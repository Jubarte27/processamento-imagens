%% Interpolação em imagens coloridas

clc; clear; close all;

addpath(genpath(strcat(pwd, '/mfunctions')));

%% 2. Set resize scale
scale = 1.8;

desktop = com.mathworks.mde.desk.MLDesktop.getInstance;
myGroup = desktop.addGroup('myGroup');
desktop.setGroupDocked('myGroup', 0);
myDim   = java.awt.Dimension(4, 2);   % 4 columns, 2 rows
% 1: Maximized, 2: Tiled, 3: Floating
desktop.setDocumentArrangement('myGroup', 2, myDim)
figH    = gobjects(1, 8);

baseimgs = {'peppers.png', 'onion.png'};
iFig = 1;
for k = 1:2
    figH(iFig) = figure( ...
        'WindowStyle', 'docked', ...
        'Name', 'Original', ...
        'NumberTitle', 'off' ...
    );
    iFig = iFig + 1;
    drawnow;
    pause(0.02);  % Magic, reduces rendering errors

    original = im2double(imread(baseimgs{k}));
    imshow(original, 'InitialMagnification', 'fit');

    fs    = { @nearest_neighbour_resize    , @bilinear_resize      , @bicubic_resize };
    names = {'Nearest Neighbor (0th order)', 'Bilinear (1st order)', 'Bicubic (3rd order)'};

    for i = 1:3
        figH(iFig) = figure( ...
            'WindowStyle', 'docked', ...
            'Name', names{i}, ...
            'NumberTitle', 'off' ...
        );
        iFig = iFig + 1;
        drawnow;
        pause(0.02);  % Magic, reduces rendering errors
        imshow(fs{i}(original, scale), 'InitialMagnification', 'fit');
    end
end