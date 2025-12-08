function seg = segment_gabor(img, K)
    [H, W, ~] = size(img);

    wavelengthMin = 4 / sqrt(2); 
    wavelengthMax = hypot(H, W);
    n = floor(log2(wavelengthMax / wavelengthMin));
    wavelengths = 2 .^ (0:(n - 2)) * wavelengthMin;
    deltaTheta = 45; 
    orientations = 0:deltaTheta:(180 - deltaTheta);

    g = computeGaborCombinations(wavelengths, orientations, 1, 0.5);
    [gabormag, ~] = gaborFFT(im2gray(img), g);
    
    Smoothing = 3;
    numFilters = length(g);
    parfor i = 1:numFilters
        filter_g = g(i); 
        sigma = 0.5 * filter_g.Wavelength;
        % Apply Gaussian smoothing
        gabormag(:, :, i) = gauss(gabormag(:, :, i), Smoothing * sigma);
    end

    X_coords = 1:W;
    Y_coords = 1:H;
    [X_map, Y_map] = meshgrid(X_coords, Y_coords);
    
    featureSet = cat(3, gabormag, X_map, Y_map);
    seg = segkmeans(featureSet, K);
end

function Label = segkmeans(I, k)
    [m, n, ~] = size(I);
    X = reshape(I, m * n, []);
    X = zscore(X); 
    Label = kmeans(X, k, 'MaxIter', 1000, 'Replicates', 1); 
    Label = reshape(Label, m, n);
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

function [M, P] = gaborFFT(A, GaborBank)
    outSize = size(A);
    A = double(A); 

    sizeLargestKernel = findMaximumKernelSize(GaborBank);
    padSize = (sizeLargestKernel - 1) / 2;
    A = padarray(A, padSize, 'replicate', 'both'); 
    sizeAPadded = size(A);

    A_fft = fft2(A); 
    numFilters = length(GaborBank);
    
    out = complex(zeros([outSize, numFilters], 'double'));
    parfor p = 1:numFilters
        H = makeFrequencyDomainTransferFunction(GaborBank(p), sizeAPadded);
        
        outPadded = ifft2(A_fft .* ifftshift(H)); 
        
        outSlice = outPadded(padSize+1:end-padSize, padSize+1:end-padSize);
        out(:, :, p) = outSlice;

    end

    M = abs(out); % Magnitude
    P = angle(out); % Phase

end

function sizeH = findMaximumKernelSize(GaborBank)
    sizeH = [0 0];
    for p = 1:length(GaborBank)
        thisKernelSize = getKernelSize(GaborBank(p));
        if thisKernelSize(1) > sizeH(1)
            sizeH = thisKernelSize;
        end
    end
end

function sigma = getSigma(g)
    BW = g.SpatialFrequencyBandwidth;
    two_BW = 2 ^ BW;
    sigmaX = g.Wavelength / pi * sqrt(log(2) / 2) * (two_BW + 1) / (two_BW - 1);
    sigma = [sigmaX, sigmaX ./ g.SpatialAspectRatio];
end

function r = getR(g)
    r = ceil(7 * getSigma(g));
end

function kSize = getKernelSize(g)
    r = 2 * max(getR(g), [], 2) + 1;
    kSize = [r, r];
end

function H = makeFrequencyDomainTransferFunction(g, imageSize)
    M = imageSize(1);
    N = imageSize(2);
    
    u = createNormalizedFrequencyVector(N);
    v = createNormalizedFrequencyVector(M);
    [U, V] = meshgrid(u, v);
    
    cosTheta = cosd(g.Orientation);
    sinTheta = sind(g.Orientation);
    
    Uprime = U .* cosTheta - V .* sinTheta;
    Vprime = U .* sinTheta + V .* cosTheta;
    
    S = getSigma(g);
    
    sigmauv = 1 ./ (2 * pi * S);
    
    sigmauv_sq_inv_1 = 1 / sigmauv(1)^2;
    sigmauv_sq_inv_2 = 1 / sigmauv(2)^2;
    
    Uprime = (Uprime - 1 / g.Wavelength);
    exponentTerm = Uprime .^ 2 * sigmauv_sq_inv_1 + Vprime .^ 2 * sigmauv_sq_inv_2;
    
    A = 2 * pi * S(1) * S(2);
    H = A .* exp(-0.5 * exponentTerm);
end

function u = createNormalizedFrequencyVector(N)
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

    sigma = double(sigma);
    filterSize = 2 * ceil(2 * sigma) + 1;
    B = frequencyGaussianFilter(A, sigma, filterSize, 'replicate');
end

function A = frequencyGaussianFilter(A, sigma, hsize, padding)
    sizeA = size(A);
    outSize = sizeA;

    A = padImage(A, hsize, padding);
    h = createGaussianKernel(sigma, hsize);
    A = double(A);

    fftSize = size(A);
    fftH = fft2(h, fftSize(1), fftSize(2)); 
    A_fft = fft2(A);

    A_filtered_fft = bsxfun(@times, A_fft, fftH);
    A = ifft2(A_filtered_fft, 'symmetric'); 
    A = unpadImage(A, outSize);
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
