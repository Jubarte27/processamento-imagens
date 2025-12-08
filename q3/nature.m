function seg = nature(img, K)
    params = swa_simplified_params();
    params.top_candidates = K;
    seg = swa_simplified_vectorized(im2double(rgb2gray(img)), params);
end

function labels = swa_simplified_vectorized(I, params)

    if nargin < 2
        params = swa_simplified_params();
    end

    I = im2double(I);
    [H, W] = size(I);
    n = H * W;

    % Build fine graph (4-neighbour)
    [Wfine, coords] = build_pixel_graph_4(I, params.a);
    Lfine = spdiags(sum(Wfine, 2), 0, n, n) - Wfine;

    % Initialize level 1
    Levels = cell(1, 1);
    Levels{1}.W = Wfine;
    Levels{1}.L = Lfine;
    Levels{1}.P = speye(n);
    Levels{1}.props.mean = I(:);
    Levels{1}.props.varmeans = zeros(n, 1);
    Levels{1}.coords = coords;
    Levels{1}.size = n;

    % Bottom-up coarsening
    lvl = 1;

    while Levels{lvl}.size > params.stop_coarsen_nodes
        Wcur = Levels{lvl}.W;

        % seeds (vectorized MIS-style)
        seeds = select_seeds_simple_vectorized(Wcur, params.seed_strength);
        Nc = numel(seeds);

        if Nc < 2
            break;
        end

        % interpolation P (vectorized)
        P = build_interpolation_simple_vectorized(Wcur, seeds);

        % coarse weights (sparse)
        Wc = sparse(P' * (Wcur * P));
        % prune tiny entries to save memory
        [ii, jj, ss] = find(Wc);
        keep = ss >= eps;
        Wc = sparse(ii(keep), jj(keep), ss(keep), size(Wc, 1), size(Wc, 1));
        Wc = (Wc + Wc') / 2;

        % coarse laplacian
        Lc = spdiags(sum(Wc, 2), 0, size(Wc, 1), size(Wc, 1)) - Wc;

        % aggregate simple properties
        props_child = Levels{lvl}.props;
        props_coarse = aggregate_props_simple_vectorized(P, props_child);

        % optional property modulation
        if params.use_property_modulation
            Wc = modulate_couplings_simple_vectorized(Wc, props_coarse, params.prop_weight_scale);
            Wc = (Wc + Wc') / 2;
            Lc = spdiags(sum(Wc, 2), 0, size(Wc, 1), size(Wc, 1)) - Wc;
        end

        % store
        lvl = lvl + 1;
        Levels{lvl}.W = Wc;
        Levels{lvl}.L = Lc;
        Levels{lvl}.P = P;
        Levels{lvl}.props = props_coarse;
        Levels{lvl}.coords = aggregate_coords_simple(P, Levels{lvl - 1}.coords);
        Levels{lvl}.size = size(Wc, 1);

        if Levels{lvl}.size <= params.stop_coarsen_nodes
            break;
        end

    end

    maxLevel = lvl;

    % Saliency detection (vectorized per level)
    saliency = cell(maxLevel, 1);
    candidates = cell(maxLevel, 1);

    for L = 1:maxLevel
        [scores, cand] = detect_salient_exact_vectorized(Levels, L, params);
        saliency{L} = scores;
        candidates{L} = cand;
    end

    % Collect all nodes (vectorized arrays instead of structs)
    levels_all = cell(maxLevel, 1);
    nodes_all = cell(maxLevel, 1);
    scores_all = cell(maxLevel, 1);

    for L = 1:maxLevel
        nL = Levels{L}.size;
        levels_all{L} = L * ones(nL, 1);
        nodes_all{L} = (1:nL).';
        scores_all{L} = saliency{L}(:);
    end

    levels_all = vertcat(levels_all{:});
    nodes_all = vertcat(nodes_all{:});
    scores_all = vertcat(scores_all{:});

    [~, ord] = sort(scores_all, 'ascend');
    levels_all = levels_all(ord);
    nodes_all = nodes_all(ord);
    scores_all = scores_all(ord);

    %% ------------------------------------------------------------------------
    % 1. Select top candidates
    %% ------------------------------------------------------------------------
    M0 = numel(scores_all);
    chosen_levels = levels_all(1:M0);
    chosen_nodes = nodes_all(1:M0);

    %% ------------------------------------------------------------------------
    % 2. Top-down refinement (fully sparse and FAST)
    %% ------------------------------------------------------------------------

    % Reserve nnz list (worst-case: each pixel appears in many masks)
    rows = cell(M0, 1); % row indices (per mask)
    cols = cell(M0, 1); % matching column indices
    % values are always 1, so we don't need a cell for vals

    for m = 1:M0
        L0 = chosen_levels(m);
        node0 = chosen_nodes(m);

        % Create sparse vector ONLY via constructor (no indexing!)
        u_coarse = sparse(node0, 1, 1, Levels{L0}.size, 1);

        for L = L0:-1:2
            P = Levels{L}.P; % sparse
            u_fine = P * u_coarse; % sparse

            hi = params.topdown_thresh_hi;
            lo = params.topdown_thresh_lo;

            % Compute mask using sparse constructor
            nz = find(u_fine >= hi); % indices to keep
            nz2 = find(u_fine <= lo); % indices to drop

            % Remove drop set
            keep = setdiff(nz, nz2); % sorted, no duplicates

            % Build new sparse u_coarse WITHOUT indexing:
            u_coarse = sparse(keep, 1, 1, size(P, 1), 1);
        end

        % Final pixel-level threshold
        final_idx = find(u_coarse > params.final_assignment_thresh);

        rows{m} = final_idx;
        cols{m} = m * ones(numel(final_idx), 1);
    end

    % Build final_masks0 at once
    ii = vertcat(rows{:});
    jj = vertcat(cols{:});
    ss = ones(numel(ii), 1);

    final_masks0 = sparse(ii, jj, ss, n, M0);

    %% ------------------------------------------------------------------------
    % 3. Compute pairwise mask similarity using sparse arithmetic (no dense F'*F)
    %% ------------------------------------------------------------------------
    % Convert to sparse logical (n x M0). This is memory- and time-efficient
    Fs = sparse(double(final_masks0)); % logicals become sparse doubles (0/1). Good.

    % sizes (number of pixels) per mask
    sizes = full(sum(Fs, 1))'; % M0 x 1

    % intersection counts (sparse M0 x M0) : inter(i,j) = |mask_i ∩ mask_j|
    inter = Fs' * Fs; % sparse matrix of intersections

    % If inter is entirely diagonal or empty, nothing to merge
    if nnz(inter) == 0
        % fallback: just pick first top K masks
        K = min(params.top_candidates, M0);
        final_masks = final_masks0(:, 1:K);
    else
        % compute cosine similarity on nonzero entries only:
        [ii, jj, ijvals] = find(inter); % vectors of same length L = nnz(inter)

        % avoid self-sim entries or keep them but ignore later
        selfmask = (ii == jj);
        % denom = sqrt(size_i * size_j)
        denom = sqrt(sizes(ii) .* sizes(jj));
        sim_vals = ijvals ./ (denom + eps); % L x 1

        % build sparse similarity matrix (symmetric)
        Sim = sparse(ii, jj, sim_vals, M0, M0);
        Sim = (Sim + Sim') / 2; % ensure symmetry (still sparse)

        % remove diagonal entries (self-sim)
        Sim = Sim - spdiags(spdiags(Sim, 0), 0, M0, M0);

        % Agglomerative merging using sparse Sim.
        % We'll iteratively merge the pair with maximum similarity.
        clusters = num2cell(1:M0);
        active = true(1, M0);

        % For efficiency, convert Sim to a list of (i,j,val) and maintain a max-heap-like loop.
        % But here we use a simple sparse approach: repeatedly find max value in Sim.
        % Because Sim is sparse and M0 is moderate (we selected a limited M0), this is OK.
        while sum(active) > params.top_candidates
            % restrict to active rows/cols by zeroing others (cheap on sparse)
            Sim_sub = Sim;
            inactive_idx = find(~active);

            if ~isempty(inactive_idx)
                Sim_sub(inactive_idx, :) = 0;
                Sim_sub(:, inactive_idx) = 0;
            end

            % find global maximum entry (sparse-friendly)
            [i_list, j_list, v_list] = find(Sim_sub);

            if isempty(v_list)
                break;
            end

            [~, imax] = max(v_list);
            i = i_list(imax); j = j_list(imax);

            % merge j into i (keep i)
            clusters{i} = [clusters{i}, clusters{j}];
            clusters{j} = [];
            active(j) = false;

            % update Sim: the merged cluster i now represents union of masks in clusters{i}
            % We update similarity of i with all others by computing union-based intersection quickly:
            % New intersection counts for i with any k: inter(i,k) = sum over member masks p in clusters{i} of inter(p,k)
            members_i = clusters{i};

            if numel(members_i) > 1
                % sum rows of 'inter' corresponding to members_i
                row_sum = sum(inter(members_i, :), 1); % 1 x M0 sparse
                % update Sim(i, :) = row_sum ./ sqrt(newsize_i * sizes(:)')
                newsize_i = sum(sizes(members_i));
                denom_vec = sqrt(newsize_i .* sizes(:))' + eps; % 1 x M0
                new_sim_row = full(row_sum) ./ denom_vec; % dense 1xM0 but small if M0 small
                % assign to Sim (sparse)
                Sim(i, :) = sparse(new_sim_row);
                Sim(:, i) = Sim(i, :)';
            end

            % zero out similarities for j (it's inactive)
            Sim(j, :) = 0; Sim(:, j) = 0;
        end

        % Now form final K masks as union of members in each active cluster
        cluster_ids = find(active);
        K = numel(cluster_ids); % should equal params.top_candidates unless early stop
        final_masks = false(n, K);

        for k = 1:K
            members = clusters{cluster_ids(k)};
            if isempty(members), continue; end
            % union of binary masks across members
            final_masks(:, k) = any(final_masks0(:, members), 2);
        end

    end

    %% ------------------------------------------------------------------------
    % 4. Pixel labeling (first cluster wins) and assign remaining by intensity
    %% ------------------------------------------------------------------------
    labels_vec = zeros(n, 1);
    taken = false(n, 1);

    for k = 1:size(final_masks, 2)
        mask = final_masks(:, k) & ~taken;
        labels_vec(mask) = k;
        taken = taken | mask;
    end

    if params.assign_remaining && any(labels_vec == 0)
        un = find(labels_vec == 0);
        pixvals = I(:);
        region_means = zeros(size(final_masks, 2), 1);

        for k = 1:size(final_masks, 2)
            idx = labels_vec == k;

            if any(idx)
                region_means(k) = mean(pixvals(idx));
            else
                region_means(k) = NaN;
            end

        end

        region_means(isnan(region_means)) = mean(pixvals);
        D = abs(bsxfun(@minus, pixvals(un), region_means'));
        [~, best] = min(D, [], 2);
        labels_vec(un) = best;
    end

    labels = reshape(labels_vec, H, W);
end

%% -------------------- Helper subfunctions (vectorized) --------------------

function params = swa_simplified_params()
    params.a = 12;
    params.seed_strength = 0.5;
    params.stop_coarsen_nodes = 40;
    params.top_candidates = 6;
    params.topdown_thresh_hi = 0.9;
    params.topdown_thresh_lo = 0.1;
    params.final_assignment_thresh = 0.5;
    params.assign_remaining = false;
    params.use_property_modulation = true;
    params.prop_weight_scale = 1.0;
    params.eps_saliency = 1e-8;
end

function [W, coords] = build_pixel_graph_4(I, a)
    [H, Wd] = size(I);
    n = H * Wd;
    idx = @(r, c) (c - 1) * H + r;
    % pre-allocate roughly
    est = n * 4;
    ii = zeros(est, 1); jj = zeros(est, 1); ss = zeros(est, 1); p = 0;

    function p = update(p, i, r, c)
        j = idx(r, c); Ij = I(r, c); w = exp(-a * abs(Ii - Ij));
        p = p + 1; ii(p) = i; jj(p) = j; ss(p) = w;
        p = p + 1; ii(p) = j; jj(p) = i; ss(p) = w;
    end

    for r = 1:H

        for c = 1:Wd
            i = idx(r, c);
            Ii = I(r, c);

            if r < H; p = update(p, i, r + 1, c); end
            if c < Wd; p = update(p, i, r, c + 1); end
        end

    end

    ii = ii(1:p); jj = jj(1:p); ss = ss(1:p);
    W = sparse(ii, jj, ss, n, n);
    W = (W + W') / 2;
    coords = zeros(n, 2);

    for c = 1:Wd

        for r = 1:H
            i = idx(r, c);
            coords(i, :) = [r, c];
        end

    end

end

function seeds = select_seeds_simple_vectorized(W, seed_strength)
    n = size(W, 1);
    deg = full(sum(W, 2));
    target = max(2, round(seed_strength * n));
    [~, order] = sort(deg, 'descend');
    % neighbor lists via accumarray
    [i_all, j_all] = find(W);
    nbrs_cell = accumarray(i_all, j_all, [n, 1], @(x){x}, {});

    covered = false(n, 1);
    seeds_map = false(n, 1);
    count = 0;

    for k = 1:n
        v = order(k);

        if ~covered(v)
            seeds_map(v) = true;
            count = count + 1;
            nbrs = nbrs_cell{v};
            covered(v) = true;
            covered(nbrs) = true;
            if count >= target, break; end
        end

    end

    if sum(seeds_map) < 2
        seeds_map(1:2) = true;
    end

    seeds = find(seeds_map);
end

function P = build_interpolation_simple_vectorized(W, seeds)
    n = size(W, 1);
    Nc = numel(seeds);
    seed_index = zeros(n, 1);
    seed_index(seeds) = 1:Nc;

    [i_all, j_all, w_all] = find(W);
    is_seed_neighbor = seed_index(j_all) > 0;
    i_sn = i_all(is_seed_neighbor);
    j_sn = j_all(is_seed_neighbor);
    w_sn = w_all(is_seed_neighbor);
    col_sn = seed_index(j_sn);

    ssum = accumarray(i_sn, w_sn, [n 1], @sum, 0);

    no_seed_neighbor = (ssum == 0);
    ii2 = []; jj2 = []; ss2 = [];

    if any(no_seed_neighbor)
        nodes_no = find(no_seed_neighbor);
        W_to_seeds = W(nodes_no, seeds); % (#nodes_no x Nc)
        [~, maxidx] = max(W_to_seeds, [], 2);
        ii2 = nodes_no;
        jj2 = maxidx;
        ss2 = ones(numel(nodes_no), 1);
    end

    keep = (ssum(i_sn) > 0);
    ii1 = i_sn(keep);
    jj1 = col_sn(keep);
    ss1 = w_sn(keep) ./ ssum(ii1);

    ii3 = seeds(:);
    jj3 = (1:Nc).';
    ss3 = ones(Nc, 1);

    ii = [ii1; ii2; ii3];
    jj = [jj1; jj2; jj3];
    ss = [ss1; ss2; ss3];

    P = sparse(ii, jj, ss, n, Nc);
end

function props_c = aggregate_props_simple_vectorized(P, props_child)
    x = props_child.mean(:);
    x2 = x .^ 2;
    sumP = full(sum(P, 1))';
    sumP(sumP == 0) = eps;
    sum_wx = full(P' * x);
    sum_wx2 = full(P' * x2);
    mean_c = sum_wx ./ sumP;
    varmeans_c = (sum_wx2 ./ sumP) - mean_c .^ 2;
    varmeans_c(varmeans_c < 0) = 0;
    props_c.mean = mean_c;
    props_c.varmeans = varmeans_c;
end

function Wmod = modulate_couplings_simple_vectorized(Wc, props, scale)
    [ii, jj, ss] = find(Wc);
    fk = [props.mean(:), props.varmeans(:)];

    % Normalize features (zero mean, unit std)
    fk_m = repmat(mean(fk, 1), size(fk, 1), 1);
    fk = fk - fk_m;
    sdev = std(fk, 0, 1);
    sdev = repmat(sdev, size(fk, 1), 1);

    fk = fk ./ sdev;
    df = fk(ii, :) - fk(jj, :);
    d2 = sum(df .^ 2, 2);
    factor = exp(-scale * d2);
    new_s = ss .* factor;
    keep = new_s >= eps;
    Wmod = sparse(ii(keep), jj(keep), new_s(keep), size(Wc, 1), size(Wc, 1));
    Wmod = (Wmod + Wmod') / 2;
end

function coords_c = aggregate_coords_simple(P, coords_f)
    x = coords_f(:, 1); y = coords_f(:, 2);
    denom = max(sum(P, 1)', eps);
    x_c = (P' * x) ./ denom;
    y_c = (P' * y) ./ denom;
    coords_c = [x_c, y_c];
end

function [scores, candidates] = detect_salient_exact_vectorized(Levels, lvl, params)

    if lvl == 1
        PTLP = Levels{1}.L;
        PTWP = Levels{1}.W;
    else
        P = Levels{lvl}.P;
        Lf = Levels{lvl - 1}.L;
        Wf = Levels{lvl - 1}.W;
        PTLP = sparse(P' * (Lf * P));
        PTWP = sparse(P' * (Wf * P));
    end

    diag_num = max(real(diag(PTLP)), 0);
    diag_den = max(real(diag(PTWP)), params.eps_saliency);
    scores = diag_num ./ (2 * diag_den + params.eps_saliency);
    bad = ~isfinite(scores);

    if any(bad)
        mx = max(scores(~bad));
        scores(bad) = mx * 10 + 1;
    end

    Wc = Levels{lvl}.W;
    n = size(Wc, 1);
    [ii, jj] = find(Wc);
    comp = double(scores(ii) <= scores(jj) + eps);
    M = sparse(ii, jj, comp, n, n);
    min_comp = min(M, [], 2); % per-row min (1 if all neighbors >=)
    ok = (min_comp == 1);
    deg = full(sum(Wc ~= 0, 2));
    ok(deg == 0) = true;
    candidates = find(ok);

    if isempty(candidates)
        [~, ord] = sort(scores, 'ascend');
        candidates = ord(1:min(10, numel(ord)));
    end

end
