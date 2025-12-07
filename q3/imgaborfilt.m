function [M, P] = imgaborfilt(A, GaborBank)
    [M, P] = gaborFilterFFT(A, GaborBank, false);
end
