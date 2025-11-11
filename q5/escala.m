clc; clear; close all;

I = imread('lena_std.tif');
I = im2double(I);
[X, Y, C] = size(I);
fatores = [2, 3];

mkdir('.out');

for f = fatores
    newX = round(X * f);
    newY = round(Y * f);
    newI_nn = zeros(newX, newY, C);
    newI_bl = zeros(newX, newY, C);

    for i = 1:newX
        for j = 1:newY
            x = (i - 0.5) / f + 0.5;
            y = (j - 0.5) / f + 0.5;
            xi = round(x);
            yi = round(y);
            if xi >= 1 && xi <= X && yi >= 1 && yi <= Y
                newI_nn(i, j, :) = I(xi, yi, :);
            end
            x1 = floor(x); x2 = ceil(x);
            y1 = floor(y); y2 = ceil(y);
            if x1 >= 1 && x2 <= X && y1 >= 1 && y2 <= Y
                dx = x - x1; dy = y - y1;
                for c = 1:C
                    Q11 = I(x1, y1, c);
                    Q12 = I(x1, y2, c);
                    Q21 = I(x2, y1, c);
                    Q22 = I(x2, y2, c);
                    newI_bl(i,j,c) = (1-dx)*(1-dy)*Q11 + (1-dx)*dy*Q12 + dx*(1-dy)*Q21 + dx*dy*Q22;
                end
            end
        end
    end

    
    imwrite(newI_nn, sprintf('.out/lena_%dX_nn.png', f));
    imwrite(newI_bl, sprintf('.out/lena_%dX_bl.png', f));

    if usejava('desktop')
        figure;
        subplot(1,2,1), imshow(newI_nn, 'InitialMagnification', 200);
        title(['Escala ', num2str(f), 'x - Vizinho']);
        subplot(1,2,2), imshow(newI_bl, 'InitialMagnification', 200);
        title(['Escala ', num2str(f), 'x - Bilinear']);

        figure;
        imshowpair(newI_nn(200:400,200:400,:), newI_bl(200:400,200:400,:), 'montage');
        title(['Comparação local - Fator ', num2str(f)]);
    else
        minimum = f * 100;
        maximum = minimum + 200;
        imwrite(newI_nn(minimum:maximum,minimum:maximum,:), sprintf('.out/lena_%dX_nn_section.png', f));
        imwrite(newI_bl(minimum:maximum,minimum:maximum,:), sprintf('.out/lena_%dX_bl_section.png', f));
    end
end

angulos = [45, 5];

for f = fatores
    I_nn = im2double(imread(sprintf('.out/lena_%dX_nn.png', f)));
    I_bl = im2double(imread(sprintf('.out/lena_%dX_bl.png', f)));

    [X, Y, C] = size(I_nn);
    cx = Y/2;
    cy = X/2;

    for a = angulos
        ang = deg2rad(a);
        R_nn = zeros(X, Y, C);
        R_bl = zeros(X, Y, C);

        for i = 1:X
            for j = 1:Y
                x =  (j - cx)*cos(ang) + (i - cy)*sin(ang) + cx;
                y = -(j - cx)*sin(ang) + (i - cy)*cos(ang) + cy;

                xi = round(y);
                yi = round(x);
                if xi >= 1 && xi <= X && yi >= 1 && yi <= Y
                    R_nn(i,j,:) = I_nn(xi, yi, :);
                end

                x1 = floor(y); x2 = ceil(y);
                y1 = floor(x); y2 = ceil(x);
                if x1>=1 && x2<=X && y1>=1 && y2<=Y
                    dx = y - x1; dy = x - y1;
                    for c=1:C
                        Q11 = I_bl(x1,y1,c);
                        Q12 = I_bl(x1,y2,c);
                        Q21 = I_bl(x2,y1,c);
                        Q22 = I_bl(x2,y2,c);
                        R_bl(i,j,c) = (1-dx)*(1-dy)*Q11 + (1-dx)*dy*Q12 + dx*(1-dy)*Q21 + dx*dy*Q22;
                    end
                end
            end
        end

        
        if usejava('desktop')
            figure;
            subplot(1,2,1), imshow(R_nn), title(['Escala ', num2str(f), 'x, Rot ', num2str(a), '° - NN']);
            subplot(1,2,2), imshow(R_bl), title(['Escala ', num2str(f), 'x, Rot ', num2str(a), '° - Bilinear']);

            figure;
            imshowpair(R_nn(200:400,200:400,:), R_bl(200:400,200:400,:), 'montage');
            title(['Comparação local - Escala ', num2str(f), 'x, Rot ', num2str(a), '°']);
        else
            imwrite(R_nn, sprintf('.out/lena_%dX_nn_r%d.png', f, a));
            imwrite(R_bl, sprintf('.out/lena_%dX_bl_r%d.png', f, a));
            
            minimum = f * 100;
            maximum = minimum + 200;
            imwrite(R_nn(minimum:maximum,minimum:maximum,:), sprintf('.out/lena_%dX_nn_r%d_section.png', f, a));
            imwrite(R_bl(minimum:maximum,minimum:maximum,:), sprintf('.out/lena_%dX_bl_r%d_section.png', f, a));
        end
    end
end
