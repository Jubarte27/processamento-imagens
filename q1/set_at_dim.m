function out = set_at_dim(dst, dim, i, src)
    at = repmat({':'}, 1, ndims(dst));
    at{dim} = i;
    out = subsasgn(dst, substruct('()', at), src);
end