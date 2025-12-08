function Label = imsegkmeans(I, k)
    I = double(I);
    [m, n, ~] = size(I);
    X = reshape(I, m * n, []);

    X = normInp(X);
    Label = kmeans(X, k, 'MaxIter', 1000);
    Label = reshape(Label, m, n);
    Label = cast_smallest(Label, k);
end

function out = cast_smallest(input, k)
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

    out = cast(input, dataType);
end

function out = normInp(X)
    % normalize channels independently (each channel persists as a column in X).
    avgChn = mean(X, 1);
    stdDevChn = std(X, 0, 1);
    % standard Deviation could be zero
    stdDevChn(stdDevChn == 0) = 1;

    % matlab 2014 doesn't broadcast matrices dimensions
    avgChn_X = repmat(avgChn, size(X, 1), 1);
    stdDevChn_X = repmat(stdDevChn, size(X, 1), 1);
    out = (X - avgChn_X) ./ stdDevChn_X;

end
