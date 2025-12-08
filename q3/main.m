clear all; close all; clc;

imgs = {'borboleta.jpg', 'raposa.jpg'};
K_values = [2 3 4];   % valores de K a testar

%% ============================
%  JANELA 1: IMAGENS ORIGINAIS
%  ============================

% figure('Name','Originais','NumberTitle','off');

% subplot(1,2,1);
% imshow(imread(imgs{1}));
% title('Borboleta - Original');

% subplot(1,2,2);
% imshow(imread(imgs{2}));
% title('Raposa - Original');


%% ============================
%  JANELA 2: BORBOLETA K-MEANS
%  ============================

% img1 = im2double(imread(imgs{1}));
% figure('Name','Borboleta - K-means','NumberTitle','off');

% for k = 1:length(K_values)
%     K = K_values(k);
%     seg = segment_kmeans(img1, K);

%     subplot(1, length(K_values), k);
%     imshow(seg, []);
%     title(['K-means K = ' num2str(K)]);
%     record('borboleta_K.jpg', seg, K);
% end


%% ============================
%  JANELA 3: BORBOLETA GABOR
%  ============================

img1 = im2double(imread(imgs{1}));
figure('Name','Borboleta - Gabor','NumberTitle','off');
set(gcf, 'Position', get(0, 'Screensize'));

for k = 1:length(K_values)
    K = K_values(k);
    seg = segment_gabor(img1, K);

    subplot(1, length(K_values), k);
    imshow(seg, []);
    title(['Gabor K = ' num2str(K)]);
    record('borboleta_G.jpg', seg, K);
end


%% ============================
%  JANELA 4: RAPOSA K-MEANS
%  ============================

% img2 = im2double(imread(imgs{2}));
% figure('Name','Raposa - K-means','NumberTitle','off');

% for k = 1:length(K_values)
%     K = K_values(k);
%     seg = segment_kmeans(img2, K);

%     subplot(1, length(K_values), k);
%     imshow(seg, []);
%     title(['K-means K = ' num2str(K)]);
%     record('raposa_K.jpg', seg, K);
% end


%% ============================
%  JANELA 5: RAPOSA GABOR
%  ============================

img2 = im2double(imread(imgs{2}));
figure('Name','Raposa - Gabor','NumberTitle','off');
set(gcf, 'Position', get(0, 'Screensize'));

for k = 1:length(K_values)
    K = K_values(k);
    seg = segment_gabor(img2, K);

    subplot(1, length(K_values), k);
    imshow(seg, []);
    title(['Gabor K = ' num2str(K)]);
    record('raposa_G.jpg', seg, K);
end
