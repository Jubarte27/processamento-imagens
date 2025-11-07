function out = lerp(mat, scale, dim)
    s = size(mat);
    n_dim = ndims(mat);

    new_s = s;
    new_s(dim) = max(1, round(s(dim) * scale));

    % computar indices
    i_new = (1:new_s(dim))';
    i_in_old = (i_new - 0.5) / scale + 0.5; % centro do pixel ao invés da borda

    Q1 = floor(i_in_old);
    Q2 = Q1 + 1;
    a  = i_in_old - Q1;

    Q1 = max(min(Q1, s(dim)), 1);
    Q2 = max(min(Q2, s(dim)), 1);

    a(Q1 == Q2) = 0;

    % hack de colocar a dimensão na primeira coluna e colapsar o resto
    order = [dim, 1:dim-1, dim+1:n_dim];
    mat_p = permute(mat, order);
    s_mat_p = size(mat_p);
    mat2D = reshape(mat_p, s_mat_p(1), []);

    vals_Q1 = mat2D(Q1, :);
    vals_Q2 = mat2D(Q2, :);

    a = repmat(a, [1, size(vals_Q1, 2)]);

    % interpolacao
    out2D = (1 - a) .* vals_Q1 + a .* vals_Q2;

    % desfazer o hack
    outP = reshape(out2D, [new_s(dim), s_mat_p(2:end)]);
    out = ipermute(outP, order);
    out = cast(out, 'like', mat);
end
