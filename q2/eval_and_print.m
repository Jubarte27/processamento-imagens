
function eval_and_print(name, Iorig, Itf, Ihe)
    % Iorig, Itf, Ihe are uint8 images
    [m0,s0,e0] = metrics(Iorig);
    [m1,s1,e1] = metrics(Itf);
    [m2,s2,e2] = metrics(Ihe);
    fprintf('%s: mean(orig)=%.2f std=%.2f entropy=%.3f | TF: mean=%.2f std=%.2f ent=%.3f | HE: mean=%.2f std=%.2f ent=%.3f\n',...
        name, m0, s0, e0, m1, s1, e1, m2, s2, e2);
end