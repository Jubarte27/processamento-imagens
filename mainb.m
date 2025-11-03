

% Leitura da imagem original (colorida)
img = imread('raposa.jpg');
img = im2double(img); % converte para double

% Parâmetros do filtro Gaussiano
sigma = 0.5;   % desvio padrão da Gaussiana (controla suavização)
amount = 2.5;  % fator de realce

% Criar imagem suavizada
h = fspecial('gaussian', [5 5], sigma); % filtro Gaussiano 5x5
img_blur = imfilter(img, h, 'replicate');

% Unsharp masking
img_sharp = img + amount*(img - img_blur);

% Garantir que os valores fiquem entre 0 e 1
img_sharp = max(min(img_sharp, 1), 0);

% Mostrar resultados
figure;
subplot(1,2,1); imshow(img); title('Original');
subplot(1,2,2); imshow(img_sharp); title('Realce com Unsharp Masking');