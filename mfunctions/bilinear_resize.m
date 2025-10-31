function out = bilinear_resize(img, scale)
    [rows, cols, ch] = size(img);
    new_rows = round(rows * scale);
    new_cols = round(cols * scale);
    [X, Y] = meshgrid(1:new_cols, 1:new_rows);
    X = round(X / scale); Y = round(Y / scale);
    X(X < 1) = 1; X(X > cols) = cols;
    Y(Y < 1) = 1; Y(Y > rows) = rows;


    out = zeros(new_rows, new_cols, ch);
    for k = 1:ch
        for i = 1:new_rows
            for j = 1:new_cols
                x = X(i,j); y = Y(i,j);
                x1 = floor(x); y1 = floor(y);
                x2 = min(x1 + 1, cols); y2 = min(y1 + 1, rows);
                a = x - x1; b = y - y1;
                Q11 = img(y1, x1, k);
                Q12 = img(y2, x1, k);
                Q21 = img(y1, x2, k);
                Q22 = img(y2, x2, k);
                out(i,j,k) = Q11*(1-a)*(1-b) + Q21*a*(1-b) + Q12*(1-a)*b + Q22*a*b;
            end
        end
    end
end