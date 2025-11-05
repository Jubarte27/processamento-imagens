function out = nearest_neighbour_resize(img, scale)
    [rows, cols, ch] = size(img);
    new_rows = round(rows * scale);
    new_cols = round(cols * scale);
    [J, I] = meshgrid(1:new_cols, 1:new_rows);
    I = ceil(I / scale); J = ceil(J / scale);
    I(I < 1) = 1; I(I > rows) = rows;
    J(J < 1) = 1; J(J > cols) = cols;


    out = zeros(new_rows, new_cols, ch);
    for k = 1:ch
        for i = 1:new_rows
            for j = 1:new_cols
                ii = I(i,j); jj = J(i,j);
                out(i,j,k) = img(ii, jj, k);
            end
        end
    end
end