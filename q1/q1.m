%% Interpolação em imagens coloridas
total = tic;

scale = 3;
baseimgs = {'cameraman.tif'};

algorithms = { ...
    % 'Original'                        , @(a, b) a                ; ...
    % 'Nearest Neighbor'                , @nearest_neighbour_resize; ...
    % 'Nearest Neighbor - MATLAB'       , @(a, b) imresize(a, b, 'nearest'); ...
    % 'Nearest Neighbor - MATLAB - Diff', @(a, b) imabsdiff(imresize(a, b, 'nearest'), nearest_neighbour_resize(a, b)); ...
    'Bilinear'                        , @bilinear_resize         ; ...
    'Bilinear - MATLAB'               , @(a, b) imresize(a, b, 'bilinear'); ...
    'Bilinear - MATLAB - Diff'        , @(a, b) imabsdiff(imresize(a, b, 'bilinear'), bilinear_resize(a, b)); ...
    % 'Bicubic'                         , @bicubic_resize          ; ...
    % 'Bicubic - MATLAB'                , @(a, b) imresize(a, b, 'bicubic'); ...
    % 'Bicubic - MATLAB - Diff'         , @(a, b) imabsdiff(imresize(a, b, 'bicubic'), bicubic_resize(a, b)); ...
};

image_count = length(baseimgs);
runs_per_image = length(algorithms);
total_runs = runs_per_image * length(baseimgs);

names = repmat(algorithms(:,1), image_count, 1);
f = repmat(algorithms(:,2), image_count, 1);

inimgs = reshape(repmat(baseimgs, runs_per_image, 1), 1, []); %% transpose
outimgs = cell(1, total_runs);


tic
parfor i = 1:length(inimgs)
    img = im2double(imread(inimgs{i}));

    outimgs{i} = f{i}(img, scale);
end
fprintf('Agoritmos de Interpolação: ');
toc
imgs_in_docked_figures(outimgs, names);

fprintf('Total: ');
toc(total)