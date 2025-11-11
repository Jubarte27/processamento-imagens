a = batch('adicao_de_ruido');
b = batch('maina');
c = batch('mainb');

imwrite(imread('borboleta.jpg'), '.out/borboleta.png');
imwrite(imread('raposa.jpg'), '.out/raposa.png');

wait(a); wait(b); wait(c);
