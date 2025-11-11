function eval_and_print_color(name, Vorig, Vtf, Vhe)
    [m0,s0,e0] = metrics(Vorig);
    [m1,s1,e1] = metrics(Vtf);
    [m2,s2,e2] = metrics(Vhe);
    fprintf('%s: mean(Vorig)=%.2f std=%.2f entropy=%.3f | TF: mean=%.2f std=%.2f ent=%.3f | HE: mean=%.2f std=%.2f ent=%.3f\n',...
        name, m0, s0, e0, m1, s1, e1, m2, s2, e2);
end
