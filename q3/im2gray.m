function I = im2gray(RGB)
    if (ndims(RGB) == 3)
        I = rgb2gray(RGB);
    else
        I = RGB;
    end
end
