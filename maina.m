
img_original = imread('borboleta.jpg');

img_noisy = imnoise(img_original, 'salt & pepper', 0.05); % 5% de ruído
img_noisy = imnoise(img_noisy, 'gaussian', 0, 0.01); % média 0, var 0.01

img_filtered = alpha_trimmed_mean_filter(img_noisy, 3, 3);
imshow(img_filtered);

%============================================================

original = im2double(img_original);
noisy = im2double(img_noisy);
filtered = im2double(img_filtered);

SNR_filtered = snr(filtered, original - filtered);
PSNR_filtered = psnr(filtered, original);

SNR_noisy = snr(noisy, original - noisy);
PSNR_noisy = psnr(noisy, original);

fprintf('filtered PSNR: %.2f dB\n', PSNR_filtered);
fprintf('filtered SNR: %.2f dB\n', SNR_filtered);

fprintf('noisy PSNR: %.2f dB\n', PSNR_noisy);
fprintf('noisy SNR: %.2f dB\n', SNR_noisy);





