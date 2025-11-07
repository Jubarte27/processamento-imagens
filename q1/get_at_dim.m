function out = get_at_dim(src, dim, i)
    at = repmat({':'}, 1, ndims(src));
    at{dim} = i;
    out = subsref(src, substruct('()', at));
end