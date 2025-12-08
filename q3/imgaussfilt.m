function B = imgaussfilt(A, sigma)

    if isscalar(sigma)
        sigma = [sigma sigma];
    end

    sigma = double(sigma);
    B = frequencyGaussianFilter(A, sigma, computeFilterSizeFromSigma(sigma), 'replicate');
end

%--------------------------------------------------------------------------
% Spatial Domain Filtering
%--------------------------------------------------------------------------
function A = spatialGaussianFilter(A, sigma, hsize, padding, separableFlag)

    dtype = class(A);

    if separableFlag

        [hCol, hRow] = createSeparableGaussianKernel(sigma, hsize);

        switch class(A)
            case {'int32', 'uint32'}
                A = double(A);
            case {'uint8', 'int8', 'uint16', 'int16'}
                A = single(A);
            case {'single', 'double'}
                % No-op
            otherwise
                assert(false, 'Unexpected datatype');
        end

        [~, padSize] = computeSizes(A, hsize);

        A = filterDoubleSeparableWithConv(A, hCol, hRow, hsize, padSize, padding);

        if ~isa(A, dtype)
            A = cast(A, dtype);
        end

    else
        h = createGaussianKernel(sigma, hsize);

        A = imfilter(A, h, padding, 'conv', 'same');
    end

end

function [finalSize, pad] = computeSizes(a, hSize)

    rank_a = ndims(a);
    rank_h = numel(hSize);

    % Pad dimensions with ones if filter and image rank are different
    size_h = [hSize ones(1, rank_a - rank_h)];
    size_a = [size(a) ones(1, rank_h - rank_a)];

    %Same output
    finalSize = size_a;

    %Calculate the number of pad pixels
    filter_center = floor((size_h + 1) / 2);
    pad = size_h - filter_center;

end

function result = filterDoubleSeparableWithConv(a, hcol, hrow, hSize, padSize, padding)

    sameSize = 1;

    imageSize = size(a);

    nonSymmetricPadShift = 1 - mod(hSize, 2);
    ndimsH = numel(hSize);
    prePadSize = padSize;
    prePadSize(1:ndimsH) = padSize(1:ndimsH) - nonSymmetricPadShift;

    if sameSize && any(nonSymmetricPadShift == 1)
        a = padarray(a, prePadSize, padding, 'pre');
        a = padarray(a, padSize, padding, 'post');
    else
        a = padarray(a, padSize, padding, 'both');
    end

    if ismatrix(a)
        result = conv2(hcol, hrow, a, 'valid');
    else % Stack behavior
        result = zeros(imageSize, 'like', a);
        isMoreThan3D = ndims(a) > 3;

        if isMoreThan3D
            sz = size(a);
            a = reshape(a, sz(1), sz(2), []);
        end

        for i = 1:size(a, 3)
            result(:, :, i) = conv2(hcol, hrow, a(:, :, i), 'valid');
        end

        if isMoreThan3D
            result = reshape(result, imageSize);
        end

    end

end

function [hcol, hrow] = createSeparableGaussianKernel(sigma, hsize)

    isIsotropic = sigma(1) == sigma(2) && hsize(1) == hsize(2);

    hcol = createGaussianKernel(sigma(1), hsize(1));

    if isIsotropic
        hrow = hcol;
    else
        hrow = createGaussianKernel(sigma(2), hsize(2));
    end

    hrow = reshape(hrow, 1, hsize(2));

end

%--------------------------------------------------------------------------
% Frequency Domain Filtering
%--------------------------------------------------------------------------
function A = frequencyGaussianFilter(A, sigma, hsize, padding)

    sizeA = size(A);
    dtype = class(A);
    outSize = sizeA;

    A = padImage(A, hsize, padding);

    h = createGaussianKernel(sigma, hsize);

    % cast to double to preserve precision unless single
    if ~isfloat(A)
        A = double(A);
    end

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

    % cast back to input type
    if ~strcmp(dtype, class(A))
        A = cast(A, dtype);
    end

    A = unpadImage(A, outSize);

end

%--------------------------------------------------------------------------
% Common Functions
%--------------------------------------------------------------------------

function [A, padSize] = padImage(A, hsize, padding)
    padSize = computePadSize(size(A), hsize);

    A = padarray(A, padSize, padding, 'both');
end

function padSize = computePadSize(sizeA, sizeH)
    rankA = numel(sizeA);
    rankH = numel(sizeH);

    sizeH = [sizeH ones(1, rankA - rankH)];

    padSize = floor(sizeH / 2);
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

function filterSize = computeFilterSizeFromSigma(sigma)
    filterSize = 2 * ceil(2 * sigma) + 1;
end
