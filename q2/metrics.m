function [mu, sigma, H] = metrics(I)
    % I uint8 or vector 0..255
    if ~isa(I,'uint8')
        I = uint8(I);
    end
    vals = double(I(:));
    mu = mean(vals);
    sigma = std(vals);
    % entropy: compute pmf
    counts = zeros(256,1);
    for k=0:255
        counts(k+1) = sum(vals == k);
    end
    p = counts / sum(counts);
    p_nonzero = p(p>0);
    H = -sum(p_nonzero .* log2(p_nonzero));
end