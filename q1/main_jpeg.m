warning('off', 'MATLAB:MKDIR:DirectoryExists'); % i know it may exists
mkdir('.out');

% Carregar imagens em tons de cinza
img1 = imread('borboleta.jpg');
img2 = imread('raposa.jpg');

if size(img1, 3) == 3
    img1 = rgb2gray(img1);
end

if size(img2, 3) == 3
    img2 = rgb2gray(img2);
end

% Valores de Q para teste
Qvalues = [2 4 8 16];

% =============================================================
%  MOSTRAR APENAS UMA FIGURA COM AS DUAS IMAGENS ORIGINAIS
% =============================================================
figure('Name', 'Imagens Originais', 'NumberTitle', 'off');
subplot(1, 2, 1);
imshow(uint8(img1));
title('Imagem 1 - Original (P&B)');

subplot(1, 2, 2);
imshow(uint8(img2));
title('Imagem 2 - Original (P&B)');

% =============================================================
%  PROCESSAR E ARMAZENAR OS RESULTADOS PARA NÃO ABRIR MIL FIGURAS
% =============================================================

rec_imgs1 = cell(length(Qvalues), 1);
rec_imgs2 = cell(length(Qvalues), 1);

ratios1 = zeros(length(Qvalues), 1);
ratios2 = zeros(length(Qvalues), 1);

psnr1_vals = zeros(length(Qvalues), 1);
psnr2_vals = zeros(length(Qvalues), 1);

for k = 1:length(Qvalues)

    Q = Qvalues(k);
    fprintf('\n=== Testando com Q = %d ===\n', Q);

    % Imagem 1
    [rec1, ratio1, psnr1] = jpeg_basic(img1, Q);
    rec_imgs1{k} = rec1;
    ratios1(k) = ratio1;
    psnr1_vals(k) = psnr1;

    fprintf('Imagem 1 - Taxa: %.2f | PSNR: %.2f dB\n', ratio1, psnr1);

    % Imagem 2
    [rec2, ratio2, psnr2] = jpeg_basic(img2, Q);
    rec_imgs2{k} = rec2;
    ratios2(k) = ratio2;
    psnr2_vals(k) = psnr2;

    fprintf('Imagem 2 - Taxa: %.2f | PSNR: %.2f dB\n', ratio2, psnr2);

end

% =============================================================
%  MOSTRAR APENAS 1 FIGURA COM AS 4 COMPRESSÕES DA IMAGEM 1
% =============================================================
figure('Name', 'Compressões - Imagem 1', 'NumberTitle', 'off');

for k = 1:length(Qvalues)
    subplot(2, 2, k);
    imshow(uint8(rec_imgs1{k}));
    title(['Q = ' num2str(Qvalues(k)) ...
               ' | PSNR = ' num2str(psnr1_vals(k), '%.2f') ...
               ' | Taxa = ' num2str(ratios1(k), '%.2f')]);
    imwrite(uint8(rec_imgs1{k}), strcat('.out/borboleta_', num2str(Qvalues(k)), '.png'));
end

% =============================================================
%  MOSTRAR APENAS 1 FIGURA COM AS 4 COMPRESSÕES DA IMAGEM 2
% =============================================================
figure('Name', 'Compressões - Imagem 2', 'NumberTitle', 'off');

for k = 1:length(Qvalues)
    subplot(2, 2, k);
    imshow(uint8(rec_imgs2{k}));
    title(['Q = ' num2str(Qvalues(k)) ...
               ' | PSNR = ' num2str(psnr2_vals(k), '%.2f') ...
               ' | Taxa = ' num2str(ratios2(k), '%.2f')]);
    imwrite(uint8(rec_imgs2{k}), strcat('.out/raposa_', num2str(Qvalues(k)), '.png'));
end
