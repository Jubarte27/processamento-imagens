function colors = distinguishable_colors(N, avoid_colors)

    if N <= 8
        g = 12;
    elseif N <= 16
        g = 16;
    else
        g = 22;
    end

    gridv = linspace(0, 1, g);
    [R, G, B] = ndgrid(gridv, gridv, gridv);
    P = [R(:) G(:) B(:)];

    distance = pdist2(P, avoid_colors);
    P = P(all(distance > 0.12345, 2), :);
    distance = pdist2(P, avoid_colors);
    [~, idx0] = max(min(distance, [], 2));

    colors = zeros(N, 3);
    colors(1, :) = P(idx0, :);

    np = size(P, 1);
    active = true(np, 1);
    active(idx0) = false;

    dmin = pdist2(P, colors(1, :));
    dmin(idx0) = Inf;

    for k = 2:N
        [~, idx] = max(dmin .* active);

        colors(k, :) = P(idx, :);
        active(idx) = false;

        dnew = pdist2(P, P(idx, :));
        dmin = min(dmin, dnew);
    end

end
