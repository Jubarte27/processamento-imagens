function over = overlay_labels(I, labels, alpha)
    I = im2double(I);
    if size(I,3) == 1
        I = repmat(I, [1 1 3]);
    end

    labs = labels(:);
    [~,~,newLabs] = unique(labs);
    newLabs = reshape(newLabs, size(labels));
    K = max(newLabs(:));

    colors = rand(K,3);

    H = size(labels,1);
    W = size(labels,2);
    C = zeros(H, W, 3);

    for k = 1:K
        mask = (newLabs == k);
        for c = 1:3
            ch = C(:,:,c);
            ch(mask) = colors(k,c);
            C(:,:,c) = ch;
        end
    end

    over = (1-alpha)*I + alpha*C;
end