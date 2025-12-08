function B = imgaussfilt(A, sigma)
    if isscalar(sigma)
        sigma = [sigma sigma];
    end

    sigma = double(sigma);
    filterSize = 2 * ceil(2 * sigma) + 1;
    B = frequencyGaussianFilter(A, sigma, filterSize, 'replicate');
end

%--------------------------------------------------------------------------
% Spatial Domain Filtering
%--------------------------------------------------------------------------
function A = spatialGaussianFilter(A, sigma, hsize, padding)
    h = createGaussianKernel(sigma, hsize);
    A = imfilter(A, h, padding, 'conv', 'same');
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

%--------------------------------------------------------------------------
% Frequency Domain Filtering
%--------------------------------------------------------------------------
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

%--------------------------------------------------------------------------
% Common Functions
%--------------------------------------------------------------------------

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
