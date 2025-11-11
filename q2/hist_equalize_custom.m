function J = hist_equalize_custom(I)
% HIST_EQUALIZE_CUSTOM - Equalização de histograma manual para imagens uint8.
%
% Esta função realiza a equalização de histograma de forma explícita,
% construindo o histograma e a função de distribuição acumulada (CDF)
% manualmente. O objetivo é redistribuir os níveis de cinza de modo a
% ocupar de forma mais uniforme a faixa de intensidades possíveis (0–255),
% aumentando o contraste global da imagem.
%
% Sintaxe:
%   J = hist_equalize_custom(I)
%
% Parâmetros:
%   I : imagem de entrada do tipo uint8 (valores entre 0 e 255)
%
% Retorno:
%   J : imagem de saída (uint8) após equalização do histograma
%
% Descrição do processo:
%   1. Calcula-se o histograma de frequências dos níveis de cinza.
%   2. Obtém-se a probabilidade de ocorrência de cada nível.
%   3. Calcula-se a função de distribuição acumulada (CDF).
%   4. Constrói-se um mapeamento linear: novo nível = 255 * CDF.
%   5. Aplica-se o mapa de transformação sobre todos os pixels da imagem.

    % Verificação de tipo da imagem
    if ~isa(I,'uint8')
        error('A imagem de entrada (I) deve ser do tipo uint8.');
    end

    % Cálculo manual do histograma
    counts = zeros(256, 1);
    vals = double(I(:));
    for k = 0:255
        counts(k + 1) = sum(vals == k);
    end

    % Probabilidades normalizadas (PDF)
    p = counts / numel(I);

    % Função de distribuição acumulada (CDF)
    cdf = cumsum(p);

    % Mapeamento de intensidades: 0–255
    map = uint8(round(255 * cdf));

    % Aplicação do mapeamento à imagem original
    J = map(double(I) + 1);
end

