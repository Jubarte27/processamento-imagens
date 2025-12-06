clear all; close all; clc;

gray_imgs = {'.out/doca.png', '.out/cachorro.png'};
color_imgs = {'borboleta.jpg', 'raposa.jpg'};

B_values = [2 3];

% IMAGENS EM CINZA
for b = 1:length(B_values)
    B = B_values(b);

    figure('Name', ['Cinza B=' num2str(B)], 'NumberTitle', 'off');

    for i = 1:length(gray_imgs)

        img = imread(gray_imgs{i});

        if ndims(img) == 3
            img = rgb2gray(img);
        end

        img = double(img);

        [rec, ratio, psnr_val] = vq_gray(img, B);

        disp(['Cinza | ' gray_imgs{i} ...
                  ' | B=' num2str(B) ...
                  ' | TAXA=' num2str(ratio, '%.2f') ...
                  ' | PSNR=' num2str(psnr_val, '%.2f')]);

        subplot(2, 2, i);
        imshow(uint8(img));

        subplot(2, 2, i + 2);
        imshow(uint8(rec));

        record(gray_imgs{i}, rec, B, ratio, psnr_val)
    end

end

% IMAGENS COLORIDAS
for b = 1:length(B_values)
    B = B_values(b);

    figure('Name', ['Coloridas B=' num2str(B)], 'NumberTitle', 'off');

    for i = 1:length(color_imgs)

        img = imread(color_imgs{i});
        img = double(img);

        [rec, ratio, psnr_val] = vq_color(img, B);

        disp(['Color | ' color_imgs{i} ...
                  ' | B=' num2str(B) ...
                  ' | TAXA=' num2str(ratio, '%.2f') ...
                  ' | PSNR=' num2str(psnr_val, '%.2f')]);

        subplot(2, 2, i);
        imshow(uint8(img));

        subplot(2, 2, i + 2);
        imshow(uint8(rec));

        record(color_imgs{i}, rec, B, ratio, psnr_val)
    end

end
