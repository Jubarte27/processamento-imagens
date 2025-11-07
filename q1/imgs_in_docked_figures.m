function imgs_in_docked_figures(imgs, img_names, names, varargin)

    if ~usejava('desktop')
        mkdir('.out');
        for i = 1:length(imgs)
            base_image_name = strrep(strrep(strrep(img_names{i}, '.jpg', ''), '.png', ''), '.tif', '');
            name = strrep(lower(names{i}), ' ', '_');

            imwrite(imgs{i}, strcat('.out/', base_image_name, '_', name, '.png'));
        end
        return
    end


    for i = 1:length(imgs)
        figure( ...
            'WindowStyle', 'docked', ...
            'NumberTitle', 'off', ...
            'Units', 'normalized', ...
            'Position', [0, 0, 1, 1], ...
            'Name', names{i} ...
        );
        imshow(imgs{i}, 'InitialMagnification', 'fit');
    end
end