function out = at_dim(n_dims, dim, i)
    out = repmat({':'}, 1, n_dims);
    out{dim} = i;
end
