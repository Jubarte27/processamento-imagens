function out = bicubic_channel(channel, scale)
    [rows, cols] = size(channel);
    new_rows = round(rows * scale);
    new_cols = round(cols * scale);
    out = zeros(new_rows, new_cols);
    [X, Y] = meshgrid(1:new_cols, 1:new_rows);
    X = X / scale; Y = Y / scale;

    for i = 1:new_rows
        for j = 1:new_cols
            x = X(i,j); y = Y(i,j);
            x1 = floor(x); y1 = floor(y);
            dx = x - x1; dy = y - y1;
            patch = zeros(4,4);
            for m = -1:2
                for n = -1:2
                    xm = min(max(x1 + m, 1), cols);
                    yn = min(max(y1 + n, 1), rows);
                    patch(n+2,m+2) = channel(yn, xm);
                end
            end
            out(i,j) = bicubic_interpolate(patch, dx, dy);
        end
    end
end