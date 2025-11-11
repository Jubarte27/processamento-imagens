function plot_histogram(I)
% Plota histograma 0..255 (I: uint8)
    if ~isa(I,'uint8'), I = im2uint8(I); end
    counts = zeros(256,1);
    vals = double(I(:));
    for k = 0:255
        counts(k+1) = sum(vals == k);
    end
    bar(0:255, counts, 'BarWidth', 1);
    xlim([0 255]);
    xlabel('Intensity'); ylabel('Count');
end