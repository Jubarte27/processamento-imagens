function seg = segment_gabor(img, K)

    gray = im2double(rgb2gray(img));
    [H, W] = size(gray);

    % ---------- PARÂMETROS DOS FILTROS GABOR ----------
    wavelengths = [3 5 9 15];
    orientations = [0 pi/4 pi/2 3*pi/4];

    numW = length(wavelengths);
    numO = length(orientations);
    numFilters = numW * numO;

    responses = zeros(H, W, numFilters);
    idx = 1;

    % ---------- GERAÇÃO E APLICAÇÃO DOS FILTROS ----------
    for w = 1:numW
        lambda = wavelengths(w);

        for o = 1:numO
            theta = orientations(o);

            % Gerar kernel Gabor manualmente
            g = build_gabor_kernel(lambda, theta);

            % Convolução
            responses(:,:,idx) = abs(imfilter(gray, g, 'symmetric'));
            idx = idx + 1;
        end
    end

    % Vetorizar resposta
    X = reshape(responses, [], numFilters);

    % Normalizar
    X = X - min(X(:));
    X = X ./ max(X(:));

    % K-means
    labels = kmeans(X, K, 'MaxIter', 200);

    % Voltar para imagem
    seg = reshape(labels, H, W);

end


% -------------------------------------------------------------
% Função auxiliar: cria um kernel Gabor de tamanho 31×31
% -------------------------------------------------------------
function g = build_gabor_kernel(lambda, theta)

    sigma = 0.56 * lambda;
    gamma = 0.5;
    psi = 0;

    N = 31;  % tamanho do kernel
    [x, y] = meshgrid(-floor(N/2):floor(N/2));

    % Rotação
    x_theta = x * cos(theta) + y * sin(theta);
    y_theta = -x * sin(theta) + y * cos(theta);

    % Formula do Gabor
    g = exp(-(x_theta.^2 + gamma^2 * y_theta.^2) / (2*sigma^2)) .* ...
        cos(2*pi * x_theta / lambda + psi);

end
