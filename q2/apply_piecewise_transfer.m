function out = apply_piecewise_transfer(I, edges, slopes, ystart)
% APPLY_PIECEWISE_TRANSFER - Aplica uma função de transferência por trechos
% lineares a uma imagem em tons de cinza (uint8).
%
% Esta função permite ajustar o contraste de uma imagem por meio de uma
% curva de transferência segmentada. Cada intervalo definido em `edges`
% possui uma inclinação específica, dada por `slopes`. Valores iniciais
% opcionais podem ser especificados em `ystart`, permitindo controle sobre
% a continuidade entre os segmentos.
%
% Sintaxe:
%   out = apply_piecewise_transfer(I, edges, slopes, ystart)
%
% Parâmetros:
%   I       : imagem de entrada do tipo uint8 (valores entre 0 e 255)
%   edges   : vetor de bordas [x0 x1 ... xN] (de 0 a 255), em ordem crescente
%   slopes  : vetor de tamanho N-1 com as inclinações (ganhos) de cada intervalo
%   ystart  : vetor com os valores iniciais (à esquerda) de cada intervalo.
%             Pode ser:
%               - vazio ( [] ) → continuidade automática entre os segmentos;
%               - um único valor → usado como valor inicial do primeiro
%                 intervalo, com continuidade automática para os seguintes;
%               - vetor completo de tamanho N-1, para controle total.
%
% Retorno:
%   out : imagem de saída (uint8) com os níveis de cinza ajustados
%
% Exemplo:
%   edges  = [0 80 160 255];
%   slopes = [1.5 0.7 1.2];
%   I2 = apply_piecewise_transfer(I, edges, slopes, []);
%
%   Esse exemplo amplia o contraste nas regiões escuras (0–80),
%   comprime nas médias (80–160) e volta a ampliar nas regiões claras (160–255).

    % Verificação de tipo da imagem
    if ~isa(I,'uint8')
        error('A imagem de entrada (I) deve ser do tipo uint8.');
    end

    x = 0:255;
    nIntervals = length(edges) - 1;

    % Verificação de consistência entre os parâmetros
    if length(slopes) ~= nIntervals
        error('O número de inclinações (slopes) deve ser igual ao número de intervalos definidos em edges.');
    end

    % Inicialização do vetor ystart
    if isempty(ystart)
        ystart = nan(1, nIntervals);
    end

    % Caso o usuário forneça apenas um valor inicial
    if numel(ystart) == 1
        tmp = nan(1, nIntervals);
        tmp(1) = ystart(1);
        ystart = tmp;
    end

    % Caso o vetor fornecido seja menor que o necessário
    if numel(ystart) < nIntervals
        tmp = nan(1, nIntervals);
        tmp(1:numel(ystart)) = ystart;
        ystart = tmp;
    end

    % Construção da LUT (tabela de correspondência de intensidades)
    lut = zeros(1, 256);

    for k = 1:nIntervals
        xL = edges(k);
        xR = edges(k+1);
        idx = (x >= xL) & (x <= xR);

        % Determinação do valor inicial y0
        if isnan(ystart(k))
            if k == 1
                y0 = 0;
            else
                % Continuidade automática: o início do segmento atual
                % é igual ao valor final do segmento anterior.
                y0 = lut(edges(k) + 1); % +1 devido ao índice 1-based do MATLAB
            end
        else
            y0 = ystart(k);
        end

        % Cálculo dos valores de saída dentro do intervalo
        m = slopes(k);
        yvals = y0 + m * (x(idx) - xL);

        % Saturação dos valores dentro do intervalo [0, 255]
        yvals = max(0, min(255, yvals));

        lut(idx) = yvals;
    end

    % Arredondamento e aplicação da LUT à imagem
    lut = round(lut);
    out = uint8(lut(double(I) + 1));  % Conversão final para uint8
end

