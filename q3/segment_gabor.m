function seg = segment_gabor(img, K)
    [H, W, ~] = size(img);

    wavelengthMin = 4 / sqrt(2);
    wavelengthMax = hypot(H, W);
    n = floor(log2(wavelengthMax / wavelengthMin));
    wavelength = 2 .^ (0:(n - 2)) * wavelengthMin;

    deltaTheta = 45;
    orientation = 0:deltaTheta:(180 - deltaTheta);

    g = computeGaborCombinations(wavelength, orientation, 1, 0.5);

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

function I = im2gray(RGB)
    if (ndims(RGB) == 3)
        I = rgb2gray(RGB);
    else
        I = RGB;
    end
end

function resultsOut = computeGaborCombinations(lambda, theta, bandwidth, spatialAspectRatio)
    [lambda, theta, bandwidth, spatialAspectRatio] = ndgrid(lambda, theta, bandwidth, spatialAspectRatio);

    lambda = lambda(:);
    theta = theta(:);
    bandwidth = bandwidth(:);
    spatialAspectRatio = spatialAspectRatio(:);

    s = ones(1, size(lambda, 1));

    lambda = mat2cell(lambda, s);
    theta = mat2cell(theta, s);
    bandwidth = mat2cell(bandwidth, s);
    spatialAspectRatio = mat2cell(spatialAspectRatio, s);

    resultsOut = struct(...
        'Wavelength', lambda, ...
        'Orientation', theta, ...
        'SpatialFrequencyBandwidth', bandwidth, ...
        'SpatialAspectRatio', spatialAspectRatio ...
);

end