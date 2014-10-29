function  [A,dA] = mnllsqr(F,J,X,Y,A,DY)
% f is function handle to eval (x,a)
% j is funtion handle to eval jacobian (x,a)
% x is independent data in nxm matrix where these are teh values for
% x1,x2,x3 etc
% y is dependent data (nx1)
% a are initial guesses, for a1,a2,a3,a4 respecively.

% Initialize Jacobian, damping factor, tolerance, and calcualte weights
if nargin < 6 || isempty(DY)
    usingWeights = false;
else
    usingWeights = true;
    W = diag(1./DY(:).^2);
end
Y = Y(:);
L = 10;
T = 1E-15;
M = .99;

for i=1:1000
    
    Z = F(X,A);       
    K = J(X,A);

    if usingWeights
        dA = (K'*W*K + L*eye(size(K,2)))\(K'*W*(Y-Z(:)));
    else 
        dA = (K'*K + L*eye(size(K,2)))\(K'*(Y-Z(:)));
    end
  
   
    R2_Old = sum((Y-Z(:)).^2);
 
    Z2 = F(X,A+dA);
    R2_New = sum((Y-Z2(:)).^2);
     
    if abs(R2_New/R2_Old - 1) < T  
        
            break        
       
    end
    
    
    if R2_Old < R2_New
        L = L*2;  
        if L > 1/T
            break
        end
        continue
    end
    
    
    %if R2_New/R2_Old > M           
   %     L = L*2;        
   % else
   %     L = L/2;
   % end
    L = L/2;
    

    A = A + dA;
end

Z = F(X,A);
K = J(X,A);
R2 = sum((Y-Z(:)).^2);

% The return value of dA is the one sigma error in A
if usingWeights 
    Cov = (K'*W*K)^-1\1;
else    
    Cov = (R2/(length(Y)-length(A)))\(K'*K);
end

dA= diag(Cov).^(1/2);

end