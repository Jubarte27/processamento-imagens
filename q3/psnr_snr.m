function [SNR_a, PSNR_a, SNR_b, PSNR_b] = psnr_snr(img_original, img_a, img_b)
    original = im2double(img_original);
    a = im2double(img_a);
    b = im2double(img_b);

    SNR_b = snr(b, original - b);
    PSNR_b = psnr(b, original);

    SNR_a = snr(a, original - a);
    PSNR_a = psnr(a, original);
end