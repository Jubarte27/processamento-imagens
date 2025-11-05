function out = bicubic_resize(img, scale)
    [rows, cols, ch] = size(img);
    new_rows = round(rows * scale);
    new_cols = round(cols * scale);
    out = zeros(new_rows, new_cols, ch);
    for k = 1:ch
        out(:,:,k) = bicubic_channel(img(:,:,k), scale);
    end
end