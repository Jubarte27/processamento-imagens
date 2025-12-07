function seg = segment_kmeans(img, K)

    % converter para Lab
    cform = makecform('srgb2lab');
    lab = applycform(img, cform);

    % reorganizar pixels
    X = reshape(lab, [], 3);

    % k-means
    idx = kmeans(X, K, 'MaxIter', 1000);

    % voltar para imagem
    seg = reshape(idx, size(img,1), size(img,2));

end
