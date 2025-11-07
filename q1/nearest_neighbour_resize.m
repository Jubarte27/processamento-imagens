function out = nearest_neighbour_resize(img, scale)
    [rows, cols, ch] = size(img);
    new_rows = round(rows * scale);
    new_cols = round(cols * scale);
    scale = new_rows / rows;

    out = zeros(new_rows, new_cols, ch);
    for k = 1:ch
        for i = 1:new_rows
            for j = 1:new_cols
                ii = floor((i - 1) / scale) + 1;
                jj = floor((j - 1) / scale) + 1;
                out(i,j,k) = img(ii, jj, k);
            end
        end
    end
end
