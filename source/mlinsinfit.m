function [A,dA,T,dT] = mlinsinfit(X,Y,F)


% sinusoid
%
%  Y = A*sin(2*pi*F*(X-T))

%
if size(X,2) > size(X,1), X = X'; end
if size(Y,2) > size(Y,1), Y = Y'; end
if size(F,2) > size(F,1), F = F'; end


% Translate
% Model is now:
%  
%   Z = sum_i B*K_i
N = length(X);
M = length(F);


B = [sin(2*pi*repmat(F',[N,1]).*repmat(X,[1,M])),-cos(2*pi*repmat(F',[N,1]).*repmat(X,[1,M]))];
Z = Y;

% Solve the linear problem: Y_j = sum_i M_i X_ij






% Solve for the
K = (B'*B)^-1*B'*Z;



S = sum((Z - sum(repmat(K',[N,1]).*B,2)).^2);
dK = diag(S/(N-2*M)*(B'*B)^-1).^(1/2);


A = (K(1:M).^2 + K(M+1:2*M).^2).^(1/2);
T = atan2(K(M+1:2*M),K(1:M))/2/pi./F;


dA = 1./A.*(K(1:M).^2.*dK(1:M).^2+K(M+1:2*M).^2.*dK(M+1:2*M).^2).^(1/2);
dT = 1./A.^2.*(K(1:M).^2.*dK(M+1:2*M).^2+K(M+1:2*M).^2.*dK(1:M).^2).^(1/2) /2/pi./F;

% 
% 
% 1./A.^2*(1)
% 











end