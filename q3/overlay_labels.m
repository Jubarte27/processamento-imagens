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
