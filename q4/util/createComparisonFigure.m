function createComparisonFigure(original, fs2, fs3, bay2, bay3, metrics, filename)
    figure('Position', [100, 100, 1400, 900]);
    
    % Imagem Original
    subplot(3, 4, [1, 2]);
    imshow(original);
    title('Original (8 bits)', 'FontSize', 12, 'FontWeight', 'bold');
    
    % Floyd-Steinberg 2 bits
    subplot(3, 4, 3);
    imshow(fs2);
    title(sprintf('Floyd-Steinberg 2 bits\nPSNR: %.2f dB, SSIM: %.4f', ...
        metrics(1).PSNR, metrics(1).SSIM), 'FontSize', 10);
    
    % Floyd-Steinberg 3 bits
    subplot(3, 4, 4);
    imshow(fs3);
    title(sprintf('Floyd-Steinberg 3 bits\nPSNR: %.2f dB, SSIM: %.4f', ...
        metrics(2).PSNR, metrics(2).SSIM), 'FontSize', 10);
    
    % Bayer 2 bits
    subplot(3, 4, 7);
    imshow(bay2);
    title(sprintf('Bayer 2 bits\nPSNR: %.2f dB, SSIM: %.4f', ...
        metrics(3).PSNR, metrics(3).SSIM), 'FontSize', 10);
    
    % Bayer 3 bits
    subplot(3, 4, 8);
    imshow(bay3);
    title(sprintf('Bayer 3 bits\nPSNR: %.2f dB, SSIM: %.4f', ...
        metrics(4).PSNR, metrics(4).SSIM), 'FontSize', 10);
    
    % Gráfico de métricas
    subplot(3, 4, [9, 10, 11, 12]);
    plotMetrics(metrics);
    
    % Salvar figura
    saveas(gcf, sprintf('resultados_dithering/%s_comparacao_completa.png', filename));
    saveas(gcf, sprintf('resultados_dithering/%s_comparacao_completa.pdf', filename));
    
    close gcf;
end
