function val = bicubic_interpolate(patch, dx, dy)
    % Cubic kernel
    function w = cubic(t)
        a = -0.5; % Catmull-Rom
        abs_t = abs(t);
        if abs_t <= 1
            w = (a+2)*abs_t^3 - (a+3)*abs_t^2 + 1;
        elseif abs_t < 2
            w = a*abs_t^3 - 5*a*abs_t^2 + 8*a*abs_t - 4*a;
        else
            w = 0;
        end
    end

    wx = zeros(1,4); wy = zeros(1,4);
    for i = 1:4, wx(i) = cubic(dx + 1 - i); end
    for j = 1:4, wy(j) = cubic(dy + 1 - j); end
    val = wy * patch * wx';
end