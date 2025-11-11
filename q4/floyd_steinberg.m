function [out] = floyd_steinberg(img, bits)
%   FLOYD_STEINBERG É uma implementação do algoritmo de dithering de 
%   Floyd-Steinberg para imagens em tons de cinza.
    %   converte `img` para double, caso não seja
    img = im2double(img);

    %   dimensões da imagem
    [rows, cols] = size(img);
    
    %   define imagem de saída vazia e 2^n tons de cinza
    out = img;
    levels = 2^bits;

    %   dithering de Floyd-Steinberg
    %   para cada pixel da imagem, faça:
    for y = 1:rows
        for x = 1:cols
            %   obtem o valor atual do pixel
            old     = out(y,x);

            %   calcula o novo valor do pixel como ...
            new     = round(old * (levels - 1)) / (levels - 1);
            out(y,x)= new;

            %   calcula o erro (linear, diferença entre o antigo e o novo)
            err     = old - new;

            % Difusão de erro
            if x+1 <= cols,                 out(y,  x+1)    = out(y,  x+1)  + err * 7/16; end
            if y+1 <= rows && x > 1,        out(y+1,x-1)    = out(y+1,x-1)  + err * 3/16; end
            if y+1 <= rows,                 out(y+1,x)      = out(y+1,x)    + err * 5/16; end
            if y+1 <= rows && x+1 <= cols,  out(y+1,x+1)    = out(y+1,x+1)  + err * 1/16; end
        end
    end
end