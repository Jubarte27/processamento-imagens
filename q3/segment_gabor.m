function seg = segment_gabor(img, K)
    [H, W, ~] = size(img);

    img = im2double(img);

    gray = img;

    if (ndims(img) == 3)
        gray = rgb2gray(img);
    end

    wavelengths = [3 6 12 24];
    orientations = [0 45 90 135];
    g = gaborCombinations(wavelengths, orientations, 1, 4);

    [gabormag, ~] = gaborFFT(gray, g);

    % phi = (1 + sqrt(5)) / 2;
    % Smoothing = phi;
    % numFilters = length(g);

    % for i = 1:numFilters
    %     filter_g = g(i);
    %     sigma = 0.5 * filter_g.Wavelength;
    %     gabormag(:, :, i) = gauss(gabormag(:, :, i), Smoothing * sigma);
    % end

    seg = segkmeans(gabormag, K, H, W);
end

function featureSet = makeFeatureSet(H, W, magnitudes)
    [X_map, Y_map] = meshgrid(1:W, 1:H);
    featureSet = cat(3, magnitudes, X_map, Y_map); % Big cube
    S = size(featureSet);
    featureSet = reshape(zscore(reshape(featureSet, [], S(3))), S);
end

function Label = segkmeans(magnitudes, K, H, W)
    I = makeFeatureSet(H, W, magnitudes);
    [m, n, ~] = size(I);
    X = reshape(I, m * n, []);
    Label = kmeans(zscore(X), K, 'MaxIter', 1000, 'Replicates', 1);
    Label = reshape(Label, H, W);
end

function resultsOut = gaborCombinations(lambda, theta, bandwidth, spatialAspectRatio)
    [lambda, theta, bandwidth, spatialAspectRatio] = ...
        ndgrid(lambda, theta, bandwidth, spatialAspectRatio);

    lambda = lambda(:);
    theta = theta(:);
    bandwidth = bandwidth(:);
    spatialAspectRatio = spatialAspectRatio(:);

    s = ones(1, size(lambda, 1));

    X = lambda / pi * sqrt(log(2) / 2) .* ...
        (2 .^ bandwidth + 1) ./ ...
        (2 .^ bandwidth - 1);
    sigma = [X, X ./ spatialAspectRatio];

    resultsOut = struct( ...
        'Wavelength', mat2cell(lambda, s), ...
        'Orientation', mat2cell(theta, s), ...
        'SpatialFrequencyBandwidth', mat2cell(bandwidth, s), ...
        'SpatialAspectRatio', mat2cell(spatialAspectRatio, s), ...
        'Sigma', mat2cell(sigma, s) ...
    );
end

function [M, P] = gaborFFT(A, GaborBank, batchSize)

    if nargin < 3
        batchSize = 9999; % should be smaller if less available RAM
    end

    sizeA = size(A);
    numFilters = length(GaborBank);
    padSize = (maxKernelSize(GaborBank) - 1) / 2;

    A = padarray(A, padSize, 'replicate', 'both');
    sizeAPadded = size(A);
    A_fft = fft2(A);
    out = complex(zeros([sizeA numFilters]));

    for f = 1:batchSize:numFilters
        idx = f:min(f + batchSize - 1, numFilters);
        H_batch = zeros([sizeAPadded length(idx)]);

        for k = 1:length(idx)
            H_batch(:, :, k) = ifftshift(makeFDTF(GaborBank(idx(k)), sizeAPadded));
        end

        outPadded = ifft2(bsxfun(@times, A_fft, H_batch));

        for k = 1:length(idx)
            out(:, :, idx(k)) = outPadded( ...
                padSize(1) + 1:end - padSize(1), ...
                padSize(2) + 1:end - padSize(2), ...
                k ...
            );
        end

    end

    M = abs(out);
    P = angle(out);
end

function sizeH = maxKernelSize(GaborBank)
    n = numel(GaborBank);
    sigmaX = zeros(n, 1); sigmaY = zeros(n, 1);

    for p = 1:n
        s = GaborBank(p).Sigma;
        sigmaX(p) = s(1);
        sigmaY(p) = s(2);
    end

    rX = ceil(7 * sigmaX);
    rY = ceil(7 * sigmaY);

    maxSize = max(2 * max([rX rY], [], 2) + 1);
    sizeH = [maxSize maxSize];
end

function H = makeFDTF(g, imageSize) % makeFrequencyDomainTransferFunction
    M = imageSize(1);
    N = imageSize(2);

    u = frequencyVector(N);
    v = frequencyVector(M);
    [U, V] = meshgrid(u, v);

    cosTheta = cosd(g.Orientation);
    sinTheta = sind(g.Orientation);

    Uprime = U .* cosTheta - V .* sinTheta;
    Vprime = U .* sinTheta + V .* cosTheta;

    sigmauv = 1 ./ (2 * pi * g.Sigma);

    sigmauv_sq_inv_1 = 1 / sigmauv(1) ^ 2;
    sigmauv_sq_inv_2 = 1 / sigmauv(2) ^ 2;

    Uprime = (Uprime - 1 / g.Wavelength);
    exponentTerm = Uprime .^ 2 * sigmauv_sq_inv_1 + Vprime .^ 2 * sigmauv_sq_inv_2;

    A = 2 * pi * g.Sigma(1) * g.Sigma(2);
    H = A .* exp(-0.5 * exponentTerm);
end

function u = frequencyVector(N)

    if mod(N, 2)
        u = linspace(-0.5 + 1 / (2 * N), 0.5 - 1 / (2 * N), N);
    else
        u = linspace(-0.5, 0.5 - 1 / N, N);
    end

end

function B = gauss(A, sigma)

    if isscalar(sigma)
        sigma = [sigma sigma];
    end

    filterSize = 2 * ceil(2 * sigma) + 1;
    B = frequencyGaussianFilter(A, sigma, filterSize, 'replicate');
end

function A = frequencyGaussianFilter(A, sigma, hsize, padding)
    sizeA = size(A);
    A = padImage(A, hsize, padding);
    h = createGaussianKernel(sigma, hsize);

    fftSize = size(A);
    fftH = fft2(h, fftSize(1), fftSize(2));
    A_fft = fft2(A);

    A_filtered_fft = bsxfun(@times, A_fft, fftH);
    A = ifft2(A_filtered_fft, 'symmetric');
    A = unpadImage(A, sizeA);
end

function h = createGaussianKernel(sigma, hsize)
    filterRadius = (hsize - 1) / 2;
    [X, Y] = meshgrid(-filterRadius(2):filterRadius(2), -filterRadius(1):filterRadius(1));
    arg = (X .* X) / (sigma(2) * sigma(2)) + (Y .* Y) / (sigma(1) * sigma(1));

    h = exp(-arg / 2);
    h(h < eps * max(h(:))) = 0;
    sumH = sum(h(:));

    if sumH ~= 0
        h = h ./ sumH;
    end

end

function [A, padSize] = padImage(A, hsize, padding)
    sizeH = [hsize ones(1, numel(size(A)) - numel(hsize))];
    padSize = floor(sizeH / 2);
    A = padarray(A, padSize, padding, 'both');
end

function A = unpadImage(A, outSize)
    start = 1 + size(A) - outSize;
    stop = start + outSize - 1;

    subCrop.type = '()';
    subCrop.subs = {start(1):stop(1), start(2):stop(2)};

    for dims = 3:ndims(A)
        subCrop.subs{dims} = start(dims):stop(dims);
    end

    A = subsref(A, subCrop);
end
