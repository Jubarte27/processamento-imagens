mkdir('.out');

imwrite(imresize(imread('doca.jpg'), [512, NaN]), '.out/doca.png');
imwrite(imresize(imread('cachorro.jpg'), [512, NaN]), '.out/cachorro.png');

imwrite(imread('borboleta.jpg'), '.out/borboleta.png');
imwrite(imread('raposa.jpg'), '.out/raposa.png');

