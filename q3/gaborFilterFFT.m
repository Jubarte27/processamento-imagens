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
        thisKernelSize = GaborBank(p).KernelSize;
        % Kernels are always square, gabor enforces this.
        if thisKernelSize(1) > sizeH(1)
            sizeH = thisKernelSize;
        end

    end

end