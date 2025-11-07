function out = lerp(mat, scale, dim)
    s = size(mat);
    new_s = size(mat);
    new_s(dim) = round(s(dim) * scale);
    out = zeros(new_s, 'like', mat);

    function out = at(i)
        out = repmat({':'}, 1, ndims(mat));
        out{dim} = i;
    end

    clip = @(x) max(min(x, s(dim)), 1);

    function [Q1, Q2, a] = closer_points(i)
        i_in_old_scale = (i - 0.5) / scale + 0.5; %pixel center

        a = i_in_old_scale - floor(i_in_old_scale);

        Q1 = floor(i_in_old_scale);
        Q2 = ceil(i_in_old_scale);

        Q1 = clip(Q1);
        Q2 = clip(Q2);
    end

    for i = 1:new_s(dim)
        [Q1, Q2, a] = closer_points(i);
        
        idx_Q1 = at(Q1);
        points_Q1 = mat(idx_Q1{:});

        idx_Q2 = at(Q2);
        points_Q2 = mat(idx_Q2{:});

        idx_i = at(i);
        out(idx_i{:}) = (1 - a) * points_Q1 + a * points_Q2;
    end
end