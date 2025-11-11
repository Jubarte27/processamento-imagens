
function plotMetrics(metrics)
    methods = {metrics.Method};
    psnr_values = [metrics.PSNR];
    ssim_values = [metrics.SSIM];
    
    % Plot PSNR
    yyaxis left
    bar(psnr_values, 'FaceColor', [0.2, 0.6, 0.8]);
    ylabel('PSNR (dB)', 'FontSize', 11);
    ylim([0, max(psnr_values) * 1.1]);
    
    % Plot SSIM
    yyaxis right
    plot(ssim_values, 'o-', 'LineWidth', 2, 'MarkerSize', 8, ...
        'Color', [0.8, 0.2, 0.2], 'MarkerFaceColor', [0.8, 0.2, 0.2]);
    ylabel('SSIM', 'FontSize', 11);
    ylim([0, 1]);
    
    % Configurações do gráfico
    set(gca, 'XTickLabel', methods, 'XTickLabelRotation', 45);
    title('Comparação de Métricas de Qualidade', 'FontSize', 12, 'FontWeight', 'bold');
    grid on;
    legend('PSNR', 'SSIM', 'Location', 'northoutside', 'Orientation', 'horizontal');
end