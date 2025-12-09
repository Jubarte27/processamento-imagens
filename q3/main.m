clear all; close all; clc;
warning('off', 'MATLAB:MKDIR:DirectoryExists'); % i know it may exists
mkdir('.out');

imgs = {'dog.jpg', 'katrina.jpg'};
K_values = [2, 3, 4]; % valores de K a testar

figure('Name', 'Originais', 'NumberTitle', 'off');

total = length(imgs);

for i = 1:total
    I = imread(imgs{i});
    subplot(1, total, i);
    imshow(I);
end

for i = 1:total
    img = imread(imgs{i});
    [~, name, ~] = fileparts(imgs{i});

    figure('Name', [name '- K-means'], 'NumberTitle', 'off');

    for k = 1:length(K_values)
        K = K_values(k);
        seg = segment_kmeans(img, K);

        subplot(2, length(K_values), k);
        imshow(seg, []);
        title(['K-means K = ' num2str(K)]);

        overlay = overlay_labels(img, seg, 0.45);
        subplot(2, length(K_values), length(K_values) + k);
        imshow(overlay);

        record([name '_K.png'], seg, K);
        record([name '_K_Color.png'], overlay, K);
    end

    figure('Name', [name '- Gabor'], 'NumberTitle', 'off');

    for k = 1:length(K_values)
        K = K_values(k);

        seg = segment_gabor(img, K);

        subplot(2, length(K_values), k);
        imshow(seg, []);
        title(['Gabor K = ' num2str(K)]);

        overlay = overlay_labels(img, seg, 0.45);
        subplot(2, length(K_values), length(K_values) + k);
        imshow(overlay);

        record([name '_G.png'], seg, K);
        record([name '_G_Color.png'], overlay, K);
    end

end
