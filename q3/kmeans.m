function [idx, C] = kmeans(X, k, ~, ~)
    [n, ~] = size(X);

    rp = randperm(n);
    C = X(rp(1:k), :);

    idx = zeros(n, 1);
    prev_idx = ones(n, 1) * (-1);

    maxIter = 1000;

    for it = 1:maxIter

        D = zeros(n, k);

        for j = 1:k
            diff = X - repmat(C(j, :), n, 1);
            D(:, j) = sum(diff .^ 2, 2);
        end

        [~, idx] = min(D, [], 2);

        if all(idx == prev_idx)
            break;
        end

        prev_idx = idx;

        for j = 1:k
            pts = X(idx == j, :);
            if isempty(pts)
                C(j, :) = X(randi(n), :);
            else
                C(j, :) = mean(pts, 1);
            end

        end

    end

end
