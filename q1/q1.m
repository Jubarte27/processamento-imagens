%% Interpolação em imagens coloridas
scale = 2;
baseimgs = {'cat.png', 'hamster.png'};

algorithms = { ...
    'Original'                        , @(a, b) a                ; ...
    'Nearest Neighbour'                , @nearest_neighbour_resize; ...
    'Bilinear'                        , @bilinear_resize         ; ...
    'Bicubic'                         , @bicubic_resize          ; ...
};

image_count = length(baseimgs);
runs_per_image = length(algorithms);
total_runs = runs_per_image * length(baseimgs);

names = repmat(algorithms(:,1), image_count, 1);
baseimgnames = repmat(baseimgs, length(algorithms));
f = repmat(algorithms(:,2), image_count, 1);

inimgs = reshape(repmat(baseimgs, runs_per_image, 1), 1, []); %% transpose
outimgs = cell(1, total_runs);

parfor i = 1:length(inimgs)
    img = im2double(imread(inimgs{i}));

    outimgs{i} = f{i}(img, scale);
end
imgs_in_docked_figures(outimgs, baseimgnames, names);
