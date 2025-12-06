function [rec_img, ratio, psnr_val] = vq_gray(img, B)

    img = double(img);

    % GARANTIA DE QUE É CINZA (2D)
    if ndims(img) ~= 2
        img = rgb2gray(uint8(img));
        img = double(img);
    end

    [h, w] = size(img);

    H = ceil(h/B) * B;
    W = ceil(w/B) * B;

    padded = padarray(img, [H-h, W-w], 'replicate', 'post');

    % EXTRAI BLOCOS SEMPRE 2D
    blocks = im2col(padded, [B B], 'distinct')';
    N = size(blocks, 1);

    max_samples = 10000;

    if N > max_samples
        idx = randperm(N, max_samples);
        sample_blocks = blocks(idx, :);
    else
        sample_blocks = blocks;
    end

    K = 256;

    [~, codebook] = kmeans(sample_blocks, K, 'MaxIter',1000);

    D = pdist2(blocks, codebook);
    [~, compressed_idx] = min(D, [], 2);

    rec_blocks = codebook(compressed_idx, :);
    rec_blocks = rec_blocks';

    rec_padded = col2im(rec_blocks, [B B], [H W], 'distinct');

    rec_img = rec_padded(1:h, 1:w);

    bits_original = numel(img) * 8;
    bits_codebook = numel(codebook) * 8;
    bits_indices = N * 8;

    bits_total = bits_codebook + bits_indices;

    ratio = bits_original / bits_total;

    mse = mean((img(:) - rec_img(:)).^2);
    psnr_val = 10 * log10(255^2 / mse);

end
