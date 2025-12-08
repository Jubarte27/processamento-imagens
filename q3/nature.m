function seg = nature(img, K)
    seg = swa_simplified(im2double(rgb2gray(img)));
end

% swa_simplified.m
% Simplified Segmentation by Weighted Aggregation (SWA) - Option B
%
% Usage:
%   I = im2double(rgb2gray(imread('peppers.png')));
%   params = swa_simplified_params();
%   labels = swa_simplified(I, params);
%   imagesc(labels); axis image off; colormap(jet);
%
% This simplified version:
% - builds a 4-neighbour pixel graph W (sparse)
% - selects seeds greedily (approx 50% or seed_strength)
% - builds interpolation P (fine->coarse)
% - forms coarse graph Wc = P' * W * P
% - aggregates simple properties: mean intensity, variance-of-means
% - computes saliency G(e_k) exactly via PTLP/PTWP with safeguards
% - chooses top-k aggregates, performs top-down refinement (thresholding)
% - returns final pixel labeling for chosen aggregates

function labels = swa_simplified(I, params)
    if nargin < 2
        params = swa_simplified_params();
    end
    assert(ndims(I)==2, 'Input must be grayscale image HxW');
    I = im2double(I);
    [H, W] = size(I);
    n = H * W;

    % Build fine graph
    fprintf('Building pixel graph... ');
    [Wfine, coords] = build_pixel_graph_4(I, params.a);
    Lfine = spdiags(sum(Wfine,2), 0, n, n) - Wfine;
    fprintf('done. nodes=%d, edges=%d\n', n, nnz(Wfine)/2);

    % Initialize level 1
    Levels = {};
    Levels{1}.W = Wfine;
    Levels{1}.L = Lfine;
    Levels{1}.P = speye(n);   % identity for level 1
    Levels{1}.props.mean = I(:);        % mean intensity
    Levels{1}.props.varmeans = zeros(n,1); % trivial at pixel level
    Levels{1}.coords = coords;
    Levels{1}.size = n;

    % Bottom-up coarsening
    lvl = 1;
    fprintf('Coarsening...\n');
    while Levels{lvl}.size > params.stop_coarsen_nodes
        Wcur = Levels{lvl}.W;
        ncur = Levels{lvl}.size;

        % select seeds (greedy MIS-style)
        seeds = select_seeds_simple(Wcur, params.seed_strength);
        Nc = numel(seeds);
        if Nc < 2
            break;
        end

        % build interpolation P (ncur x Nc)
        P = build_interpolation_simple(Wcur, seeds);

        % coarse weights: Wc = P' * Wcur * P
        Wc = sparse(P' * (Wcur * P));
        Wc = (Wc + Wc')/2;  % ensure symmetry

        % coarse laplacian
        Lc = spdiags(sum(Wc,2), 0, size(Wc,1), size(Wc,1)) - Wc;

        % aggregate properties (mean, varmeans)
        props_child = Levels{lvl}.props;
        props_coarse = aggregate_props_simple(P, props_child);

        % optional: modulate couplings by property difference (simple)
        if params.use_property_modulation
            Wc = modulate_couplings_simple(Wc, props_coarse, params.prop_weight_scale);
            Wc = (Wc + Wc')/2;
            Lc = spdiags(sum(Wc,2), 0, size(Wc,1), size(Wc,1)) - Wc;
        end

        % store next level
        lvl = lvl + 1;
        Levels{lvl}.W = Wc;
        Levels{lvl}.L = Lc;
        Levels{lvl}.P = P;  % maps fine->coarse (size ncur x Nc)
        Levels{lvl}.props = props_coarse;
        Levels{lvl}.coords = aggregate_coords_simple(P, Levels{lvl-1}.coords);
        Levels{lvl}.size = size(Wc,1);

        fprintf(' level %d: nodes=%d\n', lvl, Levels{lvl}.size);

        if Levels{lvl}.size <= params.stop_coarsen_nodes
            break;
        end
    end

    maxLevel = lvl;
    fprintf('Coarsening finished: %d levels\n', maxLevel);

    % Salient detection: compute exact G(e_k) per level
    saliency = cell(maxLevel,1);
    candidates = cell(maxLevel,1);
    for L = 1:maxLevel
        [scores, cand] = detect_salient_exact(Levels, L, params);
        saliency{L} = scores;
        candidates{L} = cand;
        fprintf(' level %d: nodes=%d, candidates=%d\n', L, Levels{L}.size, numel(cand));
    end

    % collect all nodes and sort by score (lower better)
    all_list = [];
    for L=1:maxLevel
        sc = saliency{L};
        for k = 1:numel(sc)
            all_list = [all_list; struct('level', L, 'node', k, 'score', sc(k))];
        end
    end
    scores_vec = [all_list.score]';
    [~, ord] = sort(scores_vec, 'ascend');
    all_list = all_list(ord);

    % choose top candidates
    M = min(params.top_candidates, numel(all_list));
    chosen = all_list(1:M);
    fprintf('Selected top %d aggregates for top-down refinement\n', M);

    % Top-down refinement for each chosen candidate
    final_masks = false(n, M);
    for m = 1:M
        L0 = chosen(m).level;
        node0 = chosen(m).node;
        % U at coarse level L0
        U = zeros(Levels{L0}.size,1);
        U(node0) = 1;
        u_coarse = U;
        % roll down
        for L = L0:-1:2
            P = Levels{L}.P;         % maps fine(L-1) -> coarse(L)
            % to go coarse->fine use P * u_coarse? P is fine->coarse, so
            % coarse->fine interpolation is P * u_coarse, since column k of P lists
            % weights of fine nodes to coarse node k. So yes:
            u_fine = P * u_coarse;  % size = n_{L-1} x 1
            % threshold toward boolean
            u_fine(u_fine >= params.topdown_thresh_hi) = 1;
            u_fine(u_fine <= params.topdown_thresh_lo) = 0;
            u_coarse = u_fine;
        end
        % now u_coarse is at pixel level
        final_masks(:,m) = u_coarse > params.final_assignment_thresh;
    end

    % Assemble labels: assign in order of chosen (no overlap allowed)
    labels_vec = zeros(n,1);
    taken = false(n,1);
    for m = 1:M
        mask = final_masks(:,m) & ~taken;
        labels_vec(mask) = m;
        taken = taken | mask;
    end

    % assign remaining to nearest chosen region by intensity difference
    if params.assign_remaining && any(labels_vec==0)
        un = find(labels_vec==0);
        if ~isempty(un)
            pixvals = I(:);
            region_means = zeros(M,1);
            for m = 1:M
                region_means(m) = mean(pixvals(labels_vec==m));
            end
            for uidx = un'
                [~, b] = min(abs(region_means - pixvals(uidx)));
                labels_vec(uidx) = b;
            end
        end
    end

    labels = reshape(labels_vec, H, W);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Default params
function params = swa_simplified_params()
    params.a = 10;                    % weight parameter in wij = exp(-a * |Ii - Ij|)
    params.seed_strength = 0.5;       % approx fraction of seeds (0..1)
    params.stop_coarsen_nodes = 40;   % stop coarsening at this many nodes
    params.top_candidates = 6;        % number of top aggregates to refine
    params.topdown_thresh_hi = 0.9;   % top-down threshold high
    params.topdown_thresh_lo = 0.1;   % top-down threshold low
    params.final_assignment_thresh = 0.5;
    params.assign_remaining = true;
    params.use_property_modulation = true; % whether to modulate Wc by properties
    params.prop_weight_scale = 1.0;
    params.eps_saliency = 1e-8;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Build 4-neighbour pixel sparse graph
function [W, coords] = build_pixel_graph_4(I, a)
    [H, Wd] = size(I);
    n = H * Wd;
    idx = @(r,c) (c-1)*H + r;
    ii = []; jj = []; ss = [];
    for r = 1:H
        for c = 1:Wd
            i = idx(r,c);
            Ii = I(r,c);
            if r < H
                j = idx(r+1,c);
                Ij = I(r+1,c);
                w = exp(-a * abs(Ii - Ij));
                ii(end+1)=i; jj(end+1)=j; ss(end+1)=w;
                ii(end+1)=j; jj(end+1)=i; ss(end+1)=w;
            end
            if c < Wd
                j = idx(r,c+1);
                Ij = I(r,c+1);
                w = exp(-a * abs(Ii - Ij));
                ii(end+1)=i; jj(end+1)=j; ss(end+1)=w;
                ii(end+1)=j; jj(end+1)=i; ss(end+1)=w;
            end
        end
    end
    W = sparse(ii, jj, ss, n, n);
    W = (W + W')/2;
    % coords
    coords = zeros(n,2);
    for c = 1:Wd
        for r = 1:H
            i = idx(r,c);
            coords(i,:) = [r,c];
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Seed selection (simple greedy MIS by degree)
function seeds = select_seeds_simple(W, seed_strength)
    n = size(W,1);

    % Degrees
    deg = full(sum(W,2));

    % Target number of seeds
    target = max(2, round(seed_strength * n));

    % Sort nodes by degree (descending)
    [~, order] = sort(deg, 'descend');

    % Precompute neighbors once for all nodes
    % This avoids calling find(W(v,:)) inside the loop
    [i_all, j_all] = find(W);
    nbrs_cell = accumarray(i_all, j_all, [n, 1], @(x){x}, {});

    % State arrays
    covered    = false(n,1);
    seeds_map  = false(n,1);

    % Greedy MIS sweep
    count = 0;
    for k = 1:n
        v = order(k);
        if ~covered(v)
            % select v
            seeds_map(v) = true;
            count = count + 1;

            % mark v and neighbors as covered
            nbrs = nbrs_cell{v};
            covered(v) = true;
            covered(nbrs) = true;

            if count >= target
                break;
            end
        end
    end

    % Safety: ensure at least 2 seeds
    if sum(seeds_map) < 2
        seeds_map(1:2) = true;
    end

    seeds = find(seeds_map);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Build interpolation matrix P (fine -> coarse) simple version:
% p_ik = w(i,k) / sum_j w(i,j) for seeds k adjacent to i; seed nodes map to themselves.
function P = build_interpolation_simple(W, seeds)
    n  = size(W,1);
    Nc = numel(seeds);

    % map seed index in 1..n to 1..Nc (seed position)
    seed_index = zeros(n,1);
    seed_index(seeds) = 1:Nc;

    % 1) Identify all edges i -> j that connect to a seed
    Wnz = find(W > 0);
    [i_all, j_all] = ind2sub([n n], Wnz);

    is_seed_neighbor = seed_index(j_all) > 0;
    i_sn  = i_all(is_seed_neighbor);        % fine nodes with a seed neighbor
    j_sn  = j_all(is_seed_neighbor);        % seed neighbors
    w_sn  = W(Wnz(is_seed_neighbor));       % weights
    col_sn = seed_index(j_sn);              % seed column indices

    % 2) Accumulate weights per fine-node (for normalization)
    ssum = accumarray(i_sn, w_sn, [n 1], @sum, 0);

    % 3) Identify fine nodes that have NO seed neighbors
    no_seed_neighbor = (ssum == 0);

    % 4) For those, connect to the single highest-weight seed
    if any(no_seed_neighbor)
        nodes_no = find(no_seed_neighbor);
        W_to_seeds = W(nodes_no, seeds);            % (#nodes_no x Nc)
        [~, maxidx] = max(W_to_seeds, [], 2);    % best seed for each fine node

        ii2 = nodes_no;
        jj2 = maxidx;      % 1..Nc
        ss2 = ones(numel(nodes_no),1);  % will give P(i,j)=1
    else
        ii2 = []; jj2 = []; ss2 = [];
    end

    % 5) Normalize weights for nodes WITH seed neighbors
    keep = (ssum(i_sn) > 0);
    ii1 = i_sn(keep);
    jj1 = col_sn(keep);
    ss1 = w_sn(keep) ./ ssum(ii1);

    % 6) Seed nodes map to themselves with weight 1
    ii3 = seeds(:);
    jj3 = (1:Nc).';
    ss3 = ones(Nc,1);

    % 7) Assemble sparse interpolation matrix
    ii = [ii1; ii2; ii3];
    jj = [jj1; jj2; jj3];
    ss = [ss1; ss2; ss3];

    P = sparse(ii, jj, ss, n, Nc);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Aggregate simple properties: mean intensity and variance-of-means
function props_c = aggregate_props_simple(P, props_child)
    % P is (n_fine x n_coarse)
    x = props_child.mean(:);      % fine-level means
    x2 = x.^2;                    % squared means

    % Column sums (sum of weights)
    sumP = full(sum(P,1))';       % Nc x 1
    sumP(sumP == 0) = eps;

    % Weighted sums
    sum_wx  = full(P' * x);       % Nc x 1
    sum_wx2 = full(P' * x2);      % Nc x 1

    % Mean intensity (already vectorized)
    mean_c = sum_wx ./ sumP;

    % Variance of means:
    %   var = (Σ w*x^2 / Σ w) - (Σ w*x / Σ w)^2
    varmeans_c = (sum_wx2 ./ sumP) - (mean_c.^2);

    % Clamp tiny negative values from numerical precision
    varmeans_c(varmeans_c < 0) = 0;

    % Output
    props_c.mean = mean_c;
    props_c.varmeans = varmeans_c;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Modulate coarse couplings using property differences (simple exponential)
function Wmod = modulate_couplings_simple(Wc, props, scale)
    % Extract edges
    [ii, jj, ss] = find(Wc);

    % Feature matrix fk: [mean, varmeans]
    fk = [props.mean(:), props.varmeans(:)];

    % Normalize features (zero mean, unit std)
    fk_m = repmat(mean(fk,1), size(fk, 1), 1);
    fk = fk - fk_m;
    sdev = std(fk,0,1); 
    sdev = repmat(sdev, size(fk, 1), 1);
    fk = fk ./ sdev;

    % Vectorized pairwise feature differences
    df = fk(ii,:) - fk(jj,:);     % (#edges x 2)

    % Squared L2 norm of feature differences
    d2 = sum(df.^2, 2);           % (#edges x 1)

    % Modulation factor for each edge
    factor = exp(-scale * d2);    % (#edges x 1)

    % New weights
    new_s = ss .* factor;

    % Prune before building sparse matrix
    keep = new_s >= eps;
    ii = ii(keep);
    jj = jj(keep);
    new_s = new_s(keep);

    % Build sparse weighted matrix
    n = size(Wc,1);
    Wmod = sparse(ii, jj, new_s, n, n);

    % Symmetrize
    Wmod = (Wmod + Wmod') / 2;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Aggregate coords simple
function coords_c = aggregate_coords_simple(P, coords_f)
    x = coords_f(:,1);
    y = coords_f(:,2);
    denom = max(sum(P,1)', eps);
    x_c = (P' * x) ./ denom;
    y_c = (P' * y) ./ denom;
    coords_c = [x_c, y_c];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Detect salient nodes using exact PTLP/PTWP evaluation (numerically safe)
function [scores, candidates] = detect_salient_exact(Levels, lvl, params)

    % ---------------------------------------------------------------------
    % 1) Compute PTLP, PTWP
    % ---------------------------------------------------------------------
    if lvl == 1
        PTLP = Levels{1}.L;
        PTWP = Levels{1}.W;
    else
        P  = Levels{lvl}.P;      
        Lf = Levels{lvl-1}.L;
        Wf = Levels{lvl-1}.W;
        PTLP = sparse(P' * (Lf * P));
        PTWP = sparse(P' * (Wf * P));
    end

    diag_num = max(real(diag(PTLP)), 0);
    diag_den = max(real(diag(PTWP)), params.eps_saliency);
    scores = diag_num ./ (2*diag_den + params.eps_saliency);

    bad = ~isfinite(scores);
    if any(bad)
        mx = max(scores(~bad));
        scores(bad) = mx*10 + 1;
    end

    % ---------------------------------------------------------------------
    % 2) Local-minimum test WITHOUT accumarray
    % ---------------------------------------------------------------------
    Wc = Levels{lvl}.W;
    n  = size(Wc,1);

    % Get edges
    [ii, jj] = find(Wc);

    % For each edge (i -> j), check if score(i) <= score(j)
    comp = double(scores(ii) <= scores(jj) + eps);

    % Build sparse matrix M(i,j) = comp(edge i->j)
    M = sparse(ii, jj, comp, n, n);

    % For each node i, ok(i) = all neighbors satisfy condition
    % This is TRUE iff min over j of M(i,j) == 1
    min_comp = min(M, [], 2);       % sparse min over columns

    ok = (min_comp == 1);

    % ---------------------------------------------------------------------
    % 3) isolated nodes = automatic candidates
    % ---------------------------------------------------------------------
    deg = full(sum(Wc ~= 0, 2));
    ok(deg == 0) = true;

    candidates = find(ok);

    % ---------------------------------------------------------------------
    % 4) fallback if all nodes failed
    % ---------------------------------------------------------------------
    if isempty(candidates)
        [~, ord] = sort(scores, 'ascend');
        candidates = ord(1:min(10, numel(ord)));
    end
end
