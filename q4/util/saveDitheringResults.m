function [all_metrics, comparison_table] = saveDitheringResults(originalImage, filename)
% Função completa para processar, salvar e calcular métricas
    
    % Verificar se a pasta de resultados existe
    if ~exist('resultados_dithering', 'dir')
        mkdir('resultados_dithering');
    end
    
    % Converter para escala de cinza se necessário
    if size(originalImage, 3) == 3
        originalImage = rgb2gray(originalImage);
    end
    
    % Processar todas as variações
    fs_2bit = floyd_steinberg(originalImage, 2);
    fs_3bit = floyd_steinberg(originalImage, 3);
    bayer_2bit = bayer(originalImage, 2);
    bayer_3bit = bayer(originalImage, 3);
    
    % Calcular métricas para cada método
    metrics_fs2 = calculateImageMetrics(originalImage, fs_2bit, 'Floyd-Steinberg 2bit');
    metrics_fs3 = calculateImageMetrics(originalImage, fs_3bit, 'Floyd-Steinberg 3bit');
    metrics_bay2 = calculateImageMetrics(originalImage, bayer_2bit, 'Bayer 2bit');
    metrics_bay3 = calculateImageMetrics(originalImage, bayer_3bit, 'Bayer 3bit');
    
    % Coletar todas as métricas
    all_metrics = [metrics_fs2, metrics_fs3, metrics_bay2, metrics_bay3];
    
    % Salvar imagens individuais
    [~, name, ~] = fileparts(filename);
    
    imwrite(originalImage, sprintf('resultados_dithering/%s_original.png', name));
    imwrite(fs_2bit, sprintf('resultados_dithering/%s_fs_2bit.png', name));
    imwrite(fs_3bit, sprintf('resultados_dithering/%s_fs_3bit.png', name));
    imwrite(bayer_2bit, sprintf('resultados_dithering/%s_bayer_2bit.png', name));
    imwrite(bayer_3bit, sprintf('resultados_dithering/%s_bayer_3bit.png', name));
    
    % Criar tabela de comparação
    comparison_table = createMetricsTable(all_metrics, name);
    
    % Criar figura comparativa com métricas
    createComparisonFigure(originalImage, fs_2bit, fs_3bit, bayer_2bit, bayer_3bit, all_metrics, name);
    
    fprintf('\n=== RESULTADOS PARA %s ===\n', upper(name));
    disp(comparison_table);
    
    return_all_metrics = all_metrics;
    return_comparison_table = comparison_table;
end

