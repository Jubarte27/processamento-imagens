mkdir('.out');

raposa = imread('raposa.jpg');
borboleta = imread('borboleta.jpg');

imwrite(raposa, '.out/raposa.png');
imwrite(borboleta, '.out/borboleta.png');

imwrite(rgb2gray(raposa), '.out/raposa_gray.png');
imwrite(rgb2gray(borboleta), '.out/borboleta_gray.png');
