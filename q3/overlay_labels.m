function over = overlay_labels(I, labels, alpha)
    I = im2double(I);

    if size(I, 3) == 1
        I = repmat(I, [1 1 3]);
    end

    pallete = [
               92, 41, 214;
               18, 252, 37;
               235, 88, 75;
               250, 247, 95;
               48, 219, 212;
               224, 152, 75;
               224, 85, 213;
               ] / 255;

    labs = labels(:);
    [~, ~, newLabs] = unique(labs);
    newLabs = reshape(newLabs, size(labels));
    K = max(newLabs(:));

    if K <= size(pallete, 1)
        colors = pallete(1:K, :);
    else
        colors = [pallete; distinguishable_colors(K - size(pallete, 1), pallete)];
    end

    H = size(labels, 1);
    W = size(labels, 2);
    C = zeros(H, W, 3);

    for k = 1:K
        mask = (newLabs == k);

        for c = 1:3
            ch = C(:, :, c);
            ch(mask) = colors(k, c);
            C(:, :, c) = ch;
        end

    end

    over = (1 - alpha) * I + alpha * C;
end

function colors = distinguishable_colors(N, avoid_colors)

    if N <= 8
        g = 12;
    elseif N <= 16
        g = 16;
    else
        g = 22;
    end

    gridv = linspace(0, 1, g);
    [R, G, B] = ndgrid(gridv, gridv, gridv);
    P = [R(:) G(:) B(:)];

    distance = pdist2(P, avoid_colors);
    P = P(all(distance > 0.12345, 2), :);
    distance = pdist2(P, avoid_colors);
    [~, idx0] = max(min(distance, [], 2));

    colors = zeros(N, 3);
    colors(1, :) = P(idx0, :);

    np = size(P, 1);
    active = true(np, 1);
    active(idx0) = false;

    dmin = pdist2(P, colors(1, :));
    dmin(idx0) = Inf;

    for k = 2:N
        [~, idx] = max(dmin .* active);

        colors(k, :) = P(idx, :);
        active(idx) = false;

        dnew = pdist2(P, P(idx, :));
        dmin = min(dmin, dnew);
    end

end
