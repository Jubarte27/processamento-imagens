function [M, P] = gaborFilterFFT(A, GaborBank)
    outSize = size(A);
    A = double(A);

    sizeLargestKernel = findMaximumKernelSize(GaborBank);
    % Gabor always returns odd length kernels
    padSize = (sizeLargestKernel - 1) / 2;
    A = padarray(A, padSize, 'replicate');
    sizeAPadded = size(A);

    A = fft2(A);
    out = zeros([outSize, length(GaborBank)], 'like', A);

    for p = 1:length(GaborBank)
        H = makeFrequencyDomainTransferFunction(GaborBank(p), sizeAPadded, class(A));
        outPadded = ifft2(A .* ifftshift(H));
        out(:, :, p) = unpadSlice(outPadded, padSize, outSize);

    end

    M = abs(out);
    P = angle(out);

end

function outTrimmed = unpadSlice(out, padSize, outSize)
    start = padSize + 1;
    stop = start + outSize - 1;
    outTrimmed = out(start(1):stop(1), start(2):stop(2));
end

function sizeH = findMaximumKernelSize(GaborBank)
    sizeH = [0 0];
    for p = 1:length(GaborBank)
        thisKernelSize = getKernelSize(GaborBank(p));
        % Kernels are always square, gabor enforces this.
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

    % Directly construct frequency domain transfer function of
    % Gabor filter. (Jain, Farrokhnia, "Unsupervised Texture
    % Segmentation Using Gabor Filters", 1999)
    M = imageSize(1);
    N = imageSize(2);
    u = cast(createNormalizedFrequencyVector(N), classA);
    v = cast(createNormalizedFrequencyVector(M), classA);
    [U, V] = meshgrid(u, v);

    Uprime = U .* cosd(g.Orientation) - V .* sind(g.Orientation);
    Vprime = U .* sind(g.Orientation) + V .* cosd(g.Orientation);
    
    S = getSigma(g);
    sigmauv = 1 ./ (2 * pi * S);
    freq = 1 / g.Wavelength;

    A = 2 * pi * S(1) * S(2);

    Uprime = (Uprime - freq);

    H = A .* exp(-0.5 * ((Uprime .^ 2 ./ sigmauv(1) ^ 2) + (Vprime .^ 2 ./ sigmauv(2) ^ 2)));

end

function u = createNormalizedFrequencyVector(N)
    if mod(N, 2)
        u = linspace(-0.5 + 1 / (2 * N), 0.5 - 1 / (2 * N), N);
    else
        u = linspace(-0.5, 0.5 - 1 / N, N);
    end
end