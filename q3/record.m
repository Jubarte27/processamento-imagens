function record(original_file_name, img, K)
    [~, name, ~] = fileparts(original_file_name);
    base = strcat('.out/', name, '_', num2str(K));
    imwrite(uint8(img), strcat(base, '.png'));
end
