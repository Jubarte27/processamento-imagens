function colors = distinguishable_colors(N, avoid_colors)
    gridv = linspace(0,1,30);
    [R,G,B] = ndgrid(gridv,gridv,gridv);
    P = [R(:) G(:) B(:)];

    Davoid = pdist2(P, avoid_colors, 'euclidean');
    mask = all(Davoid > 0.10, 2);
    P = P(mask,:);
    np = size(P,1);

    D = squareform(pdist(P), 'tomatrix');

    [~, idx] = max(min(Davoid(mask,:),[],2));
    colors = P(idx,:);

    active = true(np,1);
    active(idx) = false;

    dmin = D(:,idx);

    for k = 2:N
        [~, idx2] = max(dmin .* active);   % ignore selected ones
        colors(k,:) = P(idx2,:);
        active(idx2) = false;

        dmin = min(dmin, D(:,idx2));
    end
end
