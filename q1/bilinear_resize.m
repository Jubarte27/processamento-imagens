function out = bilinear_resize(img, scale)
    out = lerp(img, scale, 1);
    out = lerp(out, scale, 2);
end