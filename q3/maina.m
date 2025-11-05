imgs = {'borboleta.jpg', 'raposa.jpg'};
for i = 1:2
    img_original = imread(imgs{i});

    img_noisy = imnoise(img_original, 'salt & pepper', 0.05); % 5% de ruído
    img_noisy = imnoise(img_noisy, 'gaussian', 0, 0.01); % média 0, var 0.01

    img_filtered = alpha_trimmed_mean_filter(img_noisy, 3, 3);
    if usejava('desktop')
        imshow(img_filtered);
    else
        mkdir('.out');
        name = imgs{i};
        imwrite(img_filtered, strcat('.out/', name(1:length(name) - 4), '_filtered.png'));
    end

    [SNR_filtered, PSNR_filtered, SNR_noisy, PSNR_noisy] = psnr_snr(img_original, img_filtered, img_noisy);

    fprintf('filtered\nPSNR: %.2f dB, SNR: %.2f dB\n', PSNR_filtered, SNR_filtered);
    fprintf('noisy\nPSNR: %.2f dB, SNR: %.2f dB\n', PSNR_noisy, SNR_noisy);
    
end
