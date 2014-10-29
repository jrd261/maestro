function [A,S] = m1dgaussfit(X,Y)



Basis = [ones(length(X),1),X.^2];
par = (Basis'*Basis)^-1*Basis'*log(Y);

A = exp(par(1));
S = (-1/par(2))^.5;
return
