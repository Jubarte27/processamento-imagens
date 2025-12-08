function seg = segment_gabor(img, K)
    [H, W, ~] = size(img);

    wavelengthMin = 4 / sqrt(2); wavelengthMax = hypot(H, W);
    n = floor(log2(wavelengthMax / wavelengthMin));
    wavelength = 2 .^ (0:(n - 2)) * wavelengthMin;
    deltaTheta = 45; orientation = 0:deltaTheta:(180 - deltaTheta);

    g = computeGaborCombinations(wavelength, orientation, 1, 0.5);

    gabormag = gaborFFT(im2gray(img), g);

    Smoothing = 3;
    for i = 1:length(g)
        sigma = 0.5 * g(i).Wavelength;
        gabormag(:, :, i) = gauss(gabormag(:, :, i), Smoothing * sigma);
    end

    X = 1:W;
    Y = 1:H;
    [X, Y] = meshgrid(X, Y);
    featureSet = cat(3, gabormag, X, Y);

    seg = segkmeans(featureSet, K);
end

function Label = segkmeans(I, k)
    [m, n, ~] = size(I);
    X = reshape(I, m * n, []);

    avgChn = mean(X, 1); avgChn = repmat(avgChn, size(X, 1), 1);
    stdDevChn = std(X, 0, 1); stdDevChn(stdDevChn == 0) = 1; stdDevChn = repmat(stdDevChn, size(X, 1), 1);
    X = (X - avgChn) ./ stdDevChn;

    Label = kmeans(X, k, 'MaxIter', 1000);
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
% Applies a bank of Gabor filters to image A using FFT-based convolution.

    outSize = size(A);
    
    % Ensure input is a floating-point type for FFT
    % Use single or double depending on required precision/speed trade-off
    A = double(A); 

    % --- 1. Padding ---
    sizeLargestKernel = findMaximumKernelSize(GaborBank);
    % Gabor always returns odd length kernels
    padSize = (sizeLargestKernel - 1) / 2;
    A = padarray(A, padSize, 'replicate', 'both'); % Use 'both' for clarity/safety
    sizeAPadded = size(A);

    % --- 2. FFT and Pre-allocation ---
    A_fft = fft2(A); % Compute FFT of the padded image
    
    % Pre-calculate number of filters and base data type
    numFilters = length(GaborBank);
    baseClass = class(real(A_fft)); % Should be 'double' or 'single'
    
    % CRITICAL: Pre-allocate 'out' as a COMPLEX array
    out = complex(zeros([outSize, numFilters], baseClass));

    % --- 3. Filter Application Loop ---
    for p = 1:numFilters
        
        % H is the frequency domain transfer function (real-valued)
        H = makeFrequencyDomainTransferFunction(GaborBank(p), sizeAPadded, baseClass);
        
        % Filtering: A_fft * H, then Inverse FFT
        % ifftshift(H) is needed because makeFrequencyDomainTransferFunction 
        % is typically centered at (0,0) (DC at array center).
        outPadded = ifft2(A_fft .* ifftshift(H)); 
        
        % The result is generally complex and needs to be stored as such
        outSlice = outPadded(padSize+1:end-padSize, padSize+1:end-padSize);
        out(:, :, p) = outSlice;

    end

    % --- 4. Final Output ---
    M = abs(out); % Magnitude response
    P = angle(out); % Phase response

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

function H = makeFrequencyDomainTransferFunction(g, imageSize, classA)
% Optimized function to construct the frequency domain transfer function
% of a Gabor filter.
    
    % --- 1. Setup and Frequency Vectors ---
    M = imageSize(1);
    N = imageSize(2);
    
    % Assumes 'createNormalizedFrequencyVector' is an existing function.
    % M and N correspond to the dimensions of the spatial domain.
    u = cast(createNormalizedFrequencyVector(N), classA); % Horizontal Freq (cols)
    v = cast(createNormalizedFrequencyVector(M), classA); % Vertical Freq (rows)
    [U, V] = meshgrid(u, v);
    
    % --- 2. Rotation and Frequency Constants ---
    
    % Pre-calculate trigonometric values for rotation (micro-optimization)
    cosTheta = cosd(g.Orientation);
    sinTheta = sind(g.Orientation);
    
    % Standard Gabor rotation in the frequency domain
    Uprime = U .* cosTheta - V .* sinTheta;
    Vprime = U .* sinTheta + V .* cosTheta; % FIX: Changed V .* sind to V .* cosd
    
    S = getSigma(g); % Spatial domain sigma [SigmaX, SigmaY]
    
    % Frequency domain sigma (spread)
    % sigmauv = [sigmau, sigmav] = 1 / (2 * pi * S)
    sigmauv = 1 ./ (2 * pi * S); 
    
    % Pre-calculate the inverse of the squared frequency-domain sigmas
    sigmauv_sq_inv_1 = 1 / sigmauv(1)^2;
    sigmauv_sq_inv_2 = 1 / sigmauv(2)^2;
    
    % Bandwidth/Center Frequency
    freq = 1 / g.Wavelength; % u0
    
    % Pre-calculate amplitude factor 'A'
    A = 2 * pi * S(1) * S(2); % Amplitude factor
    
    % --- 3. Shift Uprime and Calculate Transfer Function ---
    
    % Shift the center of the Gaussian to the Gabor frequency (u0)
    Uprime = (Uprime - freq);
    
    % Calculate the Gaussian function
    % G = exp(-0.5 * (u'^2/sigmau^2 + v'^2/sigmav^2))
    exponentTerm = Uprime .^ 2 * sigmauv_sq_inv_1 + Vprime .^ 2 * sigmauv_sq_inv_2;
    
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

    if ismatrix(A)
        A = ifft2(fft2(A) .* fft2(h, fftSize(1), fftSize(2)), 'symmetric');
    else
        fftH = fft2(h, fftSize(1), fftSize(2));

        dims3toEnd = prod(fftSize(3):fftSize(end));

        %Stack behavior
        for n = 1:dims3toEnd
            A(:, :, n) = ifft2(fft2(A(:, :, n), fftSize(1), fftSize(2)) .* fftH, 'symmetric');
        end

    end

    A = unpadImage(A, outSize);
end

function h = createGaussianKernel(sigma, hsize)
    filterRadius = (hsize - 1) / 2;
    % 2-D Gaussian kernel
    [X, Y] = meshgrid(-filterRadius(2):filterRadius(2), -filterRadius(1):filterRadius(1));
    arg = (X .* X) / (sigma(2) * sigma(2)) + (Y .* Y) / (sigma(1) * sigma(1));

    h = exp(-arg / 2);

    % Suppress near-zero components
    h(h < eps * max(h(:))) = 0;
    % Normalize
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
