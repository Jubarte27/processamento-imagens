function saveTableAsLaTeX(table, imagename)
    % Salva a tabela em formato LaTeX para incluir no relatório
        fid = fopen(sprintf('resultados_dithering/%s_metricas.tex', imagename), 'w');
        
        fprintf(fid, '\\begin{table}[h!]\n');
        fprintf(fid, '\\centering\n');
        fprintf(fid, '\\caption{Métricas de Qualidade - %s}\n', imagename);
        fprintf(fid, '\\label{tab:metricas-%s}\n', imagename);
        fprintf(fid, '\\begin{tabular}{lcccc}\n');
        fprintf(fid, '\\toprule\n');
        fprintf(fid, '\\textbf{Método} & \\textbf{PSNR (dB)} & \\textbf{SSIM} & \\textbf{MSE} \\\\\n');
        fprintf(fid, '\\midrule\n');
        
        for i = 1:height(table)
            fprintf(fid, '%s & %.2f & %.4f & %.6f \\\\\n', ...
                table.Metodo{i}, table.PSNR_dB(i), table.SSIM(i), table.MSE(i));
        end
        
        fprintf(fid, '\\bottomrule\n');
        fprintf(fid, '\\end{tabular}\n');
        fprintf(fid, '\\end{table}\n');
        
        fclose(fid);
    end