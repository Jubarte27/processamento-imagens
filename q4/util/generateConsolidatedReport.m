function generateConsolidatedReport(all_metrics)
    % Gera relatório consolidado com todas as imagens
        image_names = fieldnames(all_metrics);
        
        fid = fopen('resultados_dithering/relatorio_consolidado.tex', 'w');
        
        % Cabeçalho do documento LaTeX
        fprintf(fid, '\\documentclass[12pt]{article}\n');
        fprintf(fid, '\\usepackage[utf8]{inputenc}\n');
        fprintf(fid, '\\usepackage[brazil]{babel}\n');
        fprintf(fid, '\\usepackage{graphicx}\n');
        fprintf(fid, '\\usepackage{subcaption}\n');
        fprintf(fid, '\\usepackage{booktabs}\n');
        fprintf(fid, '\\usepackage{geometry}\n');
        fprintf(fid, '\\usepackage{amsmath}\n');
        fprintf(fid, '\\usepackage{siunitx}\n');
        fprintf(fid, '\\geometry{a4paper, left=2cm, right=2cm, top=2cm, bottom=2cm}\n\n');
        
        fprintf(fid, '\\title{Relatório Consolidado - Métricas de Qualidade de Dithering}\n');
        fprintf(fid, '\\author{Análise Computacional}\n');
        fprintf(fid, '\\date{\\today}\n\n');
        
        fprintf(fid, '\\begin{document}\n\n');
        fprintf(fid, '\\maketitle\n\n');
        
        % Tabelas consolidadas para cada imagem
        for i = 1:length(image_names)
            name = image_names{i};
            metrics = all_metrics.(name);
            
            fprintf(fid, '\\section{Imagem: %s}\n', name);
            
            % Incluir tabela de métricas
            fprintf(fid, '\\input{%s_metricas.tex}\n\n', name);
            
            % Incluir figura comparativa
            fprintf(fid, '\\begin{figure}[h!]\n');
            fprintf(fid, '\\centering\n');
            fprintf(fid, '\\includegraphics[width=0.9\\textwidth]{%s_comparacao_completa.png}\n', name);
            fprintf(fid, '\\caption{Resultados completos para %s}\n', name);
            fprintf(fid, '\\label{fig:completa-%s}\n', name);
            fprintf(fid, '\\end{figure}\n\n');
        end
        
        % Análise comparativa entre imagens
        fprintf(fid, '\\section{Análise Comparativa entre Imagens}\n');
        fprintf(fid, '\\subsection{Performance por Algoritmo}\n');
        
        for i = 1:length(image_names)
            name = image_names{i};
            fprintf(fid, '\\subsubsection{%s}\n', name);
            fprintf(fid, '\\begin{itemize}\n');
            
            metrics = all_metrics.(name);
            
            % Encontrar melhor método por PSNR
            [~, idx_psnr] = max([metrics.PSNR]);
            fprintf(fid, '\\item \\textbf{Melhor PSNR}: %s (%.2f dB)\n', ...
                metrics(idx_psnr).Method, metrics(idx_psnr).PSNR);
            
            % Encontrar melhor método por SSIM
            [~, idx_ssim] = max([metrics.SSIM]);
            fprintf(fid, '\\item \\textbf{Melhor SSIM}: %s (%.4f)\n', ...
                metrics(idx_ssim).Method, metrics(idx_ssim).SSIM);
            
            fprintf(fid, '\\end{itemize}\n');
        end
        
        fprintf(fid, '\\end{document}\n');
        fclose(fid);
    end