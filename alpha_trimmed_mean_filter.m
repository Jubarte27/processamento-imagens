

function imgFiltrada = alpha_trimmed_mean_filter(imgRuidosa, windowSize, trimAmount)
% imgRuidosa  = imagem colorida de entrada
% windowSize  = tamanho da janela 
% trimAmount  = número de pixels a remover das extremidades após ordenar

    % Inicializa imagem de saída
    imgFiltrada = zeros(size(imgRuidosa));

    % Processa cada canal RGB separadamente
    for ch = 1:3
        % Extrai canal e converte para double
        canal = double(imgRuidosa(:,:,ch));
        [rows, cols] = size(canal);
        outputCanal = zeros(rows, cols);

        % Limites da vizinhança
        maxOffset = ceil(windowSize / 2);
        minOffset = floor(windowSize / 2);

        % Varre a imagem
        for r = maxOffset:(rows - minOffset)
            for c = maxOffset:(cols - minOffset)
                % Extrai janela local
                localRegion = canal(r - minOffset:r + minOffset, c - minOffset:c + minOffset);

                % Coloca em vetor, ordena e remove extremos
                values = sort(localRegion(:));
                values = values(trimAmount + 1 : windowSize * windowSize - trimAmount);

                % Calcula média dos valores restantes
                outputCanal(r, c) = mean(values);
            end
        end

        % Mantém bordas originais
        outputCanal(1:maxOffset-1, :) = canal(1:maxOffset-1, :);
        outputCanal(rows-maxOffset+2:end, :) = canal(rows-maxOffset+2:end, :);
        outputCanal(:, 1:maxOffset-1) = canal(:, 1:maxOffset-1);
        outputCanal(:, cols-maxOffset+2:end) = canal(:, cols-maxOffset+2:end);

        % Atribui canal processado à imagem de saída
        imgFiltrada(:,:,ch) = outputCanal;
    end

    % Converte para uint8
    imgFiltrada = uint8(imgFiltrada);
end


