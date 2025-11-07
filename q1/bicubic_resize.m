function out = bicubic_resize(I, scale)
    [rows, cols, ch] = size(I);
    new_rows = round(rows * scale);
    new_cols = round(cols * scale);

    scale = new_rows / rows;

    a = -0.5;
    function w = kernel(x)
        x = abs(x);
        if x <= 1
            w = (a+2)*x.^3 - (a+3)*x.^2 + 1;
        elseif and((x > 1), (x < 2))
            w = (a*x.^3 - 5*a*x.^2 + 8*a*x - 4*a);
        else
            w = 0;
        end
    end

    [xQ, yQ] = meshgrid( (1:new_cols)/scale + 0.5*(1 - 1/scale), ...
                     (1:new_rows)/scale + 0.5*(1 - 1/scale) );

    out = zeros(new_rows, new_cols, ch);

    clip = @(v, lo, hi) max(lo, min(v, hi));

    for c = 1:ch
        Ip = padarray(I(:,:,c), [2 2], 'replicate', 'both');
        [rmax, cmax] = size(Ip);
        
        xQp = xQ + 2;
        yQp = yQ + 2;
        x0p = floor(xQp);
        y0p = floor(yQp);

        dx = xQp - x0p;
        dy = yQp - y0p;
        
        wx = zeros([size(xQp), 4]);
        wy = zeros([size(yQp), 4]);
        for i = -1:2
            wx(:,:,i+2) = kernel(i - dx);
            wy(:,:,i+2) = kernel(i - dy);
        end

        wx = bsxfun(@rdivide, wx, sum(wx, 3));
        wy = bsxfun(@rdivide, wy, sum(wy, 3));
            
        val = zeros(new_rows, new_cols);
        for m = -1:2
            for n = -1:2
                xIdx = clip(x0p + n, 1, cmax);
                yIdx = clip(y0p + m, 1, rmax);
                
                Im = Ip(sub2ind([rmax cmax], yIdx, xIdx));
                
                val = val + Im .* wy(:,:,m+2) .* wx(:,:,n+2);
            end
        end
        
        out(:,:,c) = val;
    end
end
