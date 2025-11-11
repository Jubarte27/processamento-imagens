function [out] = img2gray(img)
    %   IMG2GRAY Dada uma imagem `img`, se `img` possuir três canais, isto é, 
    %   um vetor tridimensional, retorna `img` enquanto uma imagem em 
    %   tons de cinza.
    %   verifica se `img` é tridimensional
    if size(img, 3) == 3
        %   converte para tons de cinza
        out = rgb2gray(img);
    else
        out = img;
    end
end