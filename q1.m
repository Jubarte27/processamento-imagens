%% Interpolação em imagens coloridas

addpath(genpath(strcat(pwd, '/mfunctions')));

scale = 1.8;
baseimgs = {'peppers.png', 'onion.png'};

imgs = cell(1, 8);
names= cell(1, 8);

for k = 1:2
    original = im2double(imread(baseimgs{k}));

    imgs(4*(k-1)+1:4*k) = { ...
        original, ...
        nearest_neighbour_resize(original, scale), ...
        bilinear_resize(original, scale), ...
        bicubic_resize(original, scale) };
    names(4*(k-1)+1:4*k) = {'Original', 'Nearest Neighbor', 'Bilinear', 'Bicubic'};
end

imgs_in_docked_figures(imgs, names)
