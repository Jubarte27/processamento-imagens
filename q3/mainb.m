imgs = {'borboleta.jpg', 'raposa.jpg'};
sigmas = [2.5, 2.5, 0.5];
amounts = [0.5, 2.5, 2.5];
for i = 1:length(imgs)
    % Leitura da imagem original (colorida)
    
    name = imgs{i};
    base_name = strrep(name, '.jpg', '');
    img = im2double(imread(name));

    for j = 1:length(sigmas)
        %% Parâmetros do filtro Gaussiano
        % desvio padrão da Gaussiana (controla suavização)
        sigma = sigmas(j);
        % fator de realce
        amount = amounts(j);

        %% Criar imagem suavizada
        % filtro Gaussiano 5x5
        h = fspecial('gaussian', [5 5], sigma);
        img_blur = imfilter(img, h, 'replicate');

        % Unsharp masking
        img_sharp = img + amount*(img - img_blur);

        % Garantir que os valores fiquem entre 0 e 1
        img_sharp = max(min(img_sharp, 1), 0);


        if usejava('desktop')
            % Mostrar resultados
            figure;
            subplot(1,2,1); imshow(img); title('Original');
            subplot(1,2,2); imshow(img_sharp); title('Realce com Unsharp Masking');
        else
            mkdir('.out');
            img_id = strrep(sprintf('%.1f_%.1f', sigma, amount), '.', '');
            imwrite(img_sharp, strcat('.out/', base_name, '_', img_id, '_unsharp.png'));
        end
    end
end