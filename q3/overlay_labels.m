function overlay_img = overlay_labels(I, labels, alpha)
    I = im2double(I);
    [H, W] = size(labels);

    % Ensure RGB input
    if size(I,3) == 1
        I_rgb = repmat(I, [1 1 3]);
    else
        I_rgb = I;
    end

    %% 1. Normalize labels into 1..M
    labs = labels(:);
    [~,~,new_labs] = unique(labs);
    new_labs = reshape(new_labs, H, W);

    M = max(new_labs);

    %% 2. Generate distinguishable colors (Mx3)
    colors = distinguishable_colors(M, [0 0 0]);

    %% 3. Vectorized color assignment
    % Convert label map to color image via indexing
    C = colors(new_labs, :);     % (H*W) x 3
    C = reshape(C, H, W, 3);     % H x W x 3

    %% 4. Alpha blend
    overlay_img = (1 - alpha) * I_rgb + alpha * C;
end

