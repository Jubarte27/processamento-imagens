function [metrics] = calculateImageMetrics(original, processed, method_name)
% Calcula métricas de qualidade entre imagem original e processada
    
    % Garantir que ambas as imagens estão no mesmo formato
    original = im2double(original);
    processed = im2double(processed);
    
    % Garantir que têm o mesmo tamanho (caso haja diferenças de arredondamento)
    if ~isequal(size(original), size(processed))
        processed = imresize(processed, size(original));
    end
    
    % 1. PSNR (Peak Signal-to-Noise Ratio)
    mse = mean((original(:) - processed(:)).^2);
    if mse > 0
        psnr_value = 10 * log10(1 / mse);
    else
        psnr_value = Inf;
    end
    
    % 2. SSIM (Structural Similarity Index)
    try
        ssim_value = ssim(processed, original);
    catch
        % Fallback para cálculo manual do SSIM se houver problemas
        ssim_value = calculateSSIMManual(processed, original);
    end
    
    % 3. MSE (Mean Squared Error)
    mse_value = mse;
    
    % 4. RMSE (Root Mean Squared Error)
    rmse_value = sqrt(mse_value);
    
    % Armazenar métricas
    metrics = struct(...
        'Method', method_name, ...
        'PSNR', psnr_value, ...
        'SSIM', ssim_value, ...
        'MSE', mse_value, ...
        'RMSE', rmse_value ...
    );
    
    fprintf('%s - PSNR: %.2f dB, SSIM: %.4f, MSE: %.6f\n', ...
        method_name, psnr_value, ssim_value, mse_value);
end