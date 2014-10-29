function [m,dm] = mweightedmean(x,e,n)

if nargin < 3
   n = 1;
end

m = sum(x./e.^2,n)./sum(1./e.^2,n);
dm = (1./sum(1./e.^2,n)).^(1/2);

end
