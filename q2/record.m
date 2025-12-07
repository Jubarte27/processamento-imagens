function record(original_file_name, img, B, ratio, psnr_val)
    [~, name, ~] = fileparts(original_file_name);
    base = strcat('.out/', name, '_', num2str(B));
    imwrite(uint8(img), strcat(base, '.png'));
    
    results = fopen(strcat(base, '.results'), 'wt');
    fprintf(results, '&%s&%.2f&%.2f\n',name, ratio, psnr_val);
    fclose(results);
end
