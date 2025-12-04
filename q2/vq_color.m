function [rec_img, ratio, psnr_med] = vq_color(img, B)

    R = img(:,:,1);
    G = img(:,:,2);
    Bc = img(:,:,3);

    [recR, rR, pR] = vq_gray(R, B);
    [recG, rG, pG] = vq_gray(G, B);
    [recB, rB, pB] = vq_gray(Bc, B);

    rec_img = cat(3, recR, recG, recB);

    ratio = (rR + rG + rB) / 3;
    psnr_med = (pR + pG + pB) / 3;

end
