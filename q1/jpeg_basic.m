function [rec_img, ratio, psnr_val] = jpeg_basic(img, Q)

    img = double(img);
    [h, w] = size(img);

    % Ajustar dimensões para múltiplos de 8
    H = ceil(h/8) * 8;
    W = ceil(w/8) * 8;

    padded = padarray(img, [H-h W-w], 'replicate', 'post');

    % Matriz de quantização base do JPEG
    Qbase = [16 11 10 16 24 40 51 61;
             12 12 14 19 26 58 60 55;
             14 13 16 24 40 57 69 56;
             14 17 22 29 51 87 80 62;
             18 22 37 56 68 109 103 77;
             24 35 55 64 81 104 113 92;
             49 64 78 87 103 121 120 101;
             72 92 95 98 112 100 103 99];

    Qmatrix = Q * Qbase;

    coeffs = zeros(H,W);

    % --- Compressão: DCT + Quantização ---
    for i = 1:8:H
        for j = 1:8:W
            bloco = padded(i:i+7, j:j+7);
            D = dct2(bloco);
            C = round(D ./ Qmatrix);
            coeffs(i:i+7, j:j+7) = C;
        end
    end

    % Estimar taxa de compressão
    total = numel(coeffs);
    nzeros = nnz(coeffs);
    ratio = total / nzeros;

    % --- Descompressão ---
    rec = zeros(H,W);
    for i = 1:8:H
        for j = 1:8:W
            C = coeffs(i:i+7, j:j+7);
            D = C .* Qmatrix;
            rec(i:i+7, j:j+7) = idct2(D);
        end
    end

    rec_img = rec(1:h, 1:w);

    % --- PSNR ---
    mse = mean((img(:) - rec_img(:)).^2);
    psnr_val = 10 * log10(255^2 / mse);

end