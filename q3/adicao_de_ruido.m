
img1 = imread('borboleta.jpg');
% Adiciona ruído sal e pimenta
img_noisy1 = imnoise(img1, 'salt & pepper', 0.05); % 5% de ruído
% Adiciona ruído gaussiano
img_noisy1 = imnoise(img_noisy1, 'gaussian', 0, 0.01); % média 0, var 0.01

img2 = imread('raposa.jpg');
% Adiciona ruído sal e pimenta
img_noisy2 = imnoise(img2, 'salt & pepper', 0.05); % 5% de ruído
% Adiciona ruído gaussiano
img_noisy2 = imnoise(img_noisy2, 'gaussian', 0, 0.01); % média 0, var 0.01

if usejava('desktop')
    imshow(img_noisy1);
    imshow(img_noisy2);
else
    mkdir('.out');
    imwrite(img_noisy1, '.out/borboleta_ruido.png');
    imwrite(img_noisy2, '.out/raposa_ruido.png');
end
