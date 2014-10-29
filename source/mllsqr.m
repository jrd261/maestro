function [P,E,C] = mllsqr(X,Y,E)
% P -> Parameters
% C -> Covariance


if nargin < 3 || isempty(E)
    P = (X'*X)^-1*X'*Y;
    C = sum((Y-X*P).^2)*(X'*X)^-1/(size(X,1)-size(X,2));
    E = diag(C).^(1/2);
else
    W = diag(1./E.^2);
    P = (X'*W*X)^-1*X'*W*Y;
    C = (X'*W*X)^-1;
    E = diag(C).^(1/2);
end




end