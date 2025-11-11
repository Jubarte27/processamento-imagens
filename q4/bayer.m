function [out] = bayer(img,bits)
%   BAYER  é a implementação do algoritmo de dithering ordenado de Bayer para
%   imagens em tons de cinza.

    %   normalização da imagem para double e em tons de cinza
    if ~isfloat(img)
        img = im2double(img);
    end
    if size(img,3) == 3
        img = rgb2gray(img);
    end

    %   matriz de Bayer de ordem 
    BayerMatrix = [0, 32, 8, 40, 2, 34, 10, 42;
                   48, 16, 56, 24, 50, 18, 58, 26;
                   12, 44, 4, 36, 14, 46, 6, 38;
                   60, 28, 52, 20, 62, 30, 54, 22;
                   3, 35, 11, 43, 1, 33, 9, 41;
                   51, 19, 59, 27, 49, 17, 57, 25;
                   15, 47, 7, 39, 13, 45, 5, 37;
                   63, 31, 55, 23, 61, 29, 53, 21] / 64;

    [bayer_rows, bayer_cols] = size(BayerMatrix);

    %   dimensões da imagem
    [rows, cols] = size(img);

    %   define imagem de saída vazia e os 2^n tons de cinza
    out = zeros(rows, cols);
    levels = 2^bits;

    %   algoritmo de dithering de Bayer
    %   para cada pixel, faça:
    for y = 1:rows
        for x = 1:cols
            %   decide qual o limiar de dithering
            threshold = BayerMatrix(mod(y-1, bayer_rows) + 1, mod(x-1, bayer_cols) + 1);

            %   o novo pixel será o antigo + limiar
            new = round((img(y,x) + threshold / levels) * (levels - 1)) / (levels - 1);

            %   garantir faixa [0,1]:
            out(y,x) = min(max(new,0), 1);
        end
    end
end