mkdir('.out');

imwrite(imresize(imread('doca.jpg'), [NaN, 300]), '.out/doca.png');
imwrite(imresize(imread('cachorro.jpg'), [NaN, 300]), '.out/cachorro.png');

imwrite(imread('borboleta.jpg'), '.out/borboleta.png');
imwrite(imread('raposa.jpg'), '.out/raposa.png');

