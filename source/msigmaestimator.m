function s = msigmaestimator(xx,yy,zz)
%MSIGMAESTIMATOR Summary of this function goes here
%   Detailed explanation goes here
try
[a,i] = max(zz);
xx = xx-xx(i);
yy = yy-yy(i);
    
s = (xx.^2+yy.^2).^(1/2)./(log(a./zz)).^(1/2);
s(isnan(s)) = [];
s(isinf(s)) = [];

s = median(s);
catch ME
    'ahh!'
    keyboard
end
    


end

