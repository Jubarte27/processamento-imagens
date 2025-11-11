function processAllImages()
    % Lista de imagens para processar
    imageFiles = {'borboleta.jpg'};
    
    % Estrutura para armazenar todas as métricas
    all_images_metrics = struct();
    
    for i = 1:length(imageFiles)
        if exist(imageFiles{i}, 'file')
            fprintf('\n=== PROCESSANDO: %s ===\n', imageFiles{i});
            img = imread(imageFiles{i});
            [~, name, ~] = fileparts(imageFiles{i});
            
            [metrics, table] = saveDitheringResults(img, name);
            all_images_metrics.(name) = metrics;
            
            % Salvar métricas consolidadas
            save(sprintf('resultados_dithering/%s_metrics.mat', name), 'metrics', 'table');
        else
            fprintf('Arquivo não encontrado: %s\n', imageFiles{i});
        end
    end
    
    % Gerar relatório consolidado
    generateConsolidatedReport(all_images_metrics);
    
    fprintf('\n=== PROCESSAMENTO CONCLUÍDO ===\n');
    fprintf('Todos os resultados salvos em: resultados_dithering/\n');
end