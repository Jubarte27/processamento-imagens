function out = lerp(mat, scale, dim)
    s = size(mat);
    new_s = size(mat);
    new_s(dim) = round(s(dim) * scale);
    out = zeros(new_s, 'like', mat);

    clip = @(x) max(min(x, s(dim)), 1);

    for i = 1:new_s(dim)
        i_in_old_scale = (i - 0.5) / scale + 0.5; %pixel center

        a = i_in_old_scale - floor(i_in_old_scale);

        Q1 = floor(i_in_old_scale);
        Q2 = ceil(i_in_old_scale);

        Q1 = clip(Q1);
        Q2 = clip(Q2);

        interpolated = (1 - a) * get_at_dim(mat, dim, Q1) + a * get_at_dim(mat, dim, Q2);

        out = set_at_dim(out, dim, i, interpolated);
    end
end