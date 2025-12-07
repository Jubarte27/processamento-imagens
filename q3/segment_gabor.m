function seg = segment_gabor(img, K)
    gray = im2double(rgb2gray(img));
    [H, W] = size(gray);

    wavelengths = [3 5 9 15];
    orientations = [0 pi / 4 pi / 2 3 * pi / 4];

    % Build full Gabor bank (stacked complex kernels)
    kernels = build_gabor_bank(wavelengths, orientations);
    numFilters = size(kernels, 3);

    Fimg = fft2(gray);

    % Pad
    Kh = size(kernels, 1);
    Kw = size(kernels, 2);
    paddedK = zeros(H, W, numFilters, 'like', kernels);
    paddedK(1:Kh, 1:Kw, :) = kernels;

    Fk = fft2(paddedK);
    Fimg = repmat(Fimg, 1, 1, size(Fk, 3));

    responses = ifft2(Fimg .* Fk);
    responses = abs(responses);

    X = reshape(responses, [], numFilters);
    X = zscore(X, 0, 1);

    labels = kmeans(X, K, 'MaxIter', 1000);
    seg = reshape(labels, H, W);
end

function kernels = build_gabor_bank(wavelengths, orientations)
    % Build full Gabor filter bank (all kernels stacked in a 3-D array)
    sigma_factor = 0.56;
    gamma = 0.5;
    psi = 0;

    numW = numel(wavelengths);
    numO = numel(orientations);
    numFilters = numW * numO;

    % Determine largest kernel size to pad smaller ones consistently
    maxN = 0;

    for w = wavelengths
        sigma = sigma_factor * w;
        N = ceil(6 * sigma);
        if mod(N, 2) == 0, N = N + 1; end % odd
        maxN = max(maxN, N);
    end

    kernels = complex(zeros(maxN, maxN, numFilters));

    idx = 1;

    for w = 1:numW
        lambda = wavelengths(w);
        sigma = sigma_factor * lambda;

        % kernel size for this lambda
        N = ceil(6 * sigma);
        if mod(N, 2) == 0, N = N + 1; end

        [x, y] = meshgrid(-floor(N / 2):floor(N / 2));

        for o = 1:numO
            theta = orientations(o);

            % rotate coordinates
            xT = x * cos(theta) + y * sin(theta);
            yT = -x * sin(theta) + y * cos(theta);

            % Gaussian envelope
            G = exp(- (xT .^ 2 + gamma ^ 2 * yT .^ 2) / (2 * sigma ^ 2));

            % real = even, imag = odd
            S = exp(1i * (2 * pi * xT / lambda + psi));

            g = G .* S;

            % place into center of max-sized kernel
            ker = complex(zeros(maxN, maxN));
            start = floor((maxN - N) / 2) + 1;
            ker(start:start + N - 1, start:start + N - 1) = g;

            kernels(:, :, idx) = ker;
            idx = idx + 1;
        end

    end

end
