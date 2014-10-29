function [A,dA,F,dF,T,dT] = mnlinsinfit(X,Y,F,d)

if nargin < 4
d = false;
end

if size(X,2) > size(X,1), X = X'; end
if size(Y,2) > size(Y,1), Y = Y'; end
if size(F,2) > size(F,1), F = F'; end


if d

  YS = max(Y);
  Y = Y/YS;

  XS = max(X);
  X = X/XS;

  F = F*XS;

end


[A,dA,T,dT] = mlinsinfit(X,Y,F); %#ok<NASGU,*ASGLU>



L = 1;
N = length(X);
M = length(F);
J = zeros(N,3*M);
XX = repmat(X,[1,M]);
for iIteration = 1:100
    
    AA = repmat(A',[N,1]);
    FF = repmat(F',[N,1]);
    TT = repmat(T',[N,1]);
        
    Z = sum(AA.*sin(2*pi.*FF.*(XX-TT)),2);
    R2_Pre = sum((Z-Y).^2);           
    
    J(:,1:3:3*M) = sin(2*pi*FF.*(XX-TT));
    J(:,2:3:3*M) = 2*pi*AA.*(XX-TT).*cos(2*pi*FF.*(XX-TT));
    J(:,3:3:3*M) = -2*pi*FF.*AA.*cos(2*pi*FF.*(XX-TT));    
    

%    dK =  (J'*J + L*eye(size(J,2)))^(-1)*J'*(Y-Z);
    dK = (J'*J+L*eye(size(J,2)))\(J'*(Y-Z));
                
    A = A + dK(1:3:3*M);
    F = F + dK(2:3:3*M);
    T = T + dK(3:3:3*M);
    
    AA = repmat(A',[N,1]);
    FF = repmat(F',[N,1]);
    TT = repmat(T',[N,1]);
        
    Z = sum(AA.*sin(2*pi.*FF.*(XX-TT)),2);
    R2_Post = sum((Z-Y).^2);           
    
    
    if(R2_Post>R2_Pre)
        L = L*10;
        A = A - dK(1:3:3*M);
        F = F - dK(1:3:3*M);
        T = T - dK(1:3:3*M);
        
        continue    
    elseif(R2_Post/R2_Pre > .99)
        L = L/10;            
        
    end

    
end


%keyboard
%c = diag((J'*J)^(-1)*R2_Post/(N-3*M));
c = diag((J'*J)\eye(size(J,2))*R2_Post/(N-3*M));


dA = c(1:3:3*M).^(1/2);
dF = c(2:3:3*M).^(1/2);
dT = c(3:3:3*M).^(1/2);



if d

   A = A*YS;
   dA = dA*YS;
   F = F/XS;
   dF = dF/XS;
   T = T*XS;
   dT = dT*XS;


end


              
              
end
