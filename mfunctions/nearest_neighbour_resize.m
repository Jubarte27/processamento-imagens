function out = nearest_neighbour_resize(img, scale)
    [rows, cols, ch] = size(img);
    new_rows = round(rows * scale);
    new_cols = round(cols * scale);
    [Y, X] = meshgrid(1:new_cols, 1:new_rows);
    X = round(X / scale); Y = round(Y / scale);
    X(X < 1) = 1; X(X > rows) = rows;
    Y(Y < 1) = 1; Y(Y > cols) = cols;


    out = zeros(new_rows, new_cols, ch);
    for k = 1:ch
        for i = 1:new_rows
            for j = 1:new_cols
                x = X(i,j); y = Y(i,j);
                out(i,j,k) = img(x, y, k);
            end
        end
    end
end