function record(original_file_name, img, K)

    if ismatrix(img)
        minD = min(img(:));
        maxD = max(img(:));
        img = (img - minD) ./ (maxD - minD);
    end

    [~, name, ~] = fileparts(original_file_name);
    base = strcat('.out/', name, '_', num2str(K));
    imwrite(img, strcat(base, '.png'));

end
