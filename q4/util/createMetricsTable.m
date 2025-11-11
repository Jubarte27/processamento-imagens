function results_table = createMetricsTable(metrics, imagename)
% Cria tabela com métricas para exportação (versão compatível)
    
    methods = {metrics.Method};
    psnr_values = [metrics.PSNR];
    ssim_values = [metrics.SSIM];
    mse_values = [metrics.MSE];
    
    % Criar estrutura de dados compatível
    results_table = struct();
    results_table.Metodo = methods;
    results_table.PSNR_dB = psnr_values;
    results_table.SSIM = ssim_values;
    results_table.MSE = mse_values;
        
    % Salvar como arquivo LaTeX
    saveTableAsLaTeX(results_table, imagename);
end