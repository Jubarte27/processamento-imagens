function [Label, Centers] = algkmeans(Inp, k)

    % Casting input to single if non-floating datatype
    classInp = class(Inp);

    if ~isfloat(classInp)
        Inp = single(Inp);
    end

    [m, n, c] = size(Inp);
    p = 1;
    X = reshape(Inp, m * n, []);

    [X, avgChn, stdDevChn] = normInp(X);

    if size(X, 1) < k
        error(message('images:validate:kTooLarge'))
    end

    if m == 1 && n == 1 && p == 1
        % Degenerate case with a single observation, workaround ocv bug
        Label = 1;
        NormCen = zeros(size(X), 'like', X);
    else
        [Label, NormCen] = kmeans(X, k, 'MaxIter', 1000);
    end

    Centers = denormalizeCenters(NormCen, avgChn, stdDevChn);
    Centers = cast(Centers, classInp);

    Label = reshape(Label, m, n);

    % Memory efficient Label matrix as it returns smallest numeric class
    % necessary  depending upon the number of clusters.
    if k <= intmax('uint8')
        dataType = 'uint8';
    elseif k <= intmax('uint16')
        dataType = 'uint16';
    elseif k <= intmax('uint32')
        dataType = 'uint32';
    else
        dataType = 'double';
    end

    Label = cast(Label, dataType);

end

function [out, avgChn, stdDevChn] = normInp(X)
    % normalize channels independently (each channel persists as a column in X).
    avgChn = mean(X, 1);
    stdDevChn = std(X, 0, 1);
    % standard Deviation could be zero
    stdDevChn(stdDevChn == 0) = 1;

    avgChn_X = repmat(avgChn, size(X, 1), 1);
    stdDevChn_X = repmat(stdDevChn, size(X, 1), 1);
    out = (X - avgChn_X) ./ stdDevChn_X;

end

function Centers = denormalizeCenters(NormCen, avgChn, stdDevChn)
    % De-normalized centers to be returned in original user input space.
    avgChn_Norm = repmat(avgChn, size(NormCen, 1), 1);
    stdDevChn_Norm = repmat(stdDevChn, size(NormCen, 1), 1);
    Centers = NormCen .* stdDevChn_Norm + avgChn_Norm;
end
