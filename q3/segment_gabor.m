function seg = segment_gabor(img, K)
    [H, W, ~] = size(img);

    wavelengthMin = 4 / sqrt(2);
    wavelengthMax = hypot(H, W);
    n = floor(log2(wavelengthMax / wavelengthMin));
    wavelength = 2 .^ (0:(n - 2)) * wavelengthMin;

    deltaTheta = 45;
    orientation = 0:deltaTheta:(180 - deltaTheta);

    g = gabor(wavelength, orientation);

    Agray = im2gray(img);
    gabormag = gaborFilterFFT(Agray, g);


    Smoothing = 3;
    for i = 1:length(g)
        sigma = 0.5 * g(i).Wavelength;
        gabormag(:, :, i) = imgaussfilt(gabormag(:, :, i), Smoothing * sigma);
    end

    X = 1:W;
    Y = 1:H;
    [X, Y] = meshgrid(X, Y);
    featureSet = cat(3, gabormag, X, Y);

    L = imsegkmeans(featureSet, K);

    seg = im2double(L);
end
