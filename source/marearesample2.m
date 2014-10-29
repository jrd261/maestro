function [x,y] = marearesample2(x,y,n,xmin,xmax)

if nargin < 3, n = 1000; end
if nargin < 4, xmin = -inf; end
if nargin < 5, xmax = inf; end

y(x<xmin | x > xmax) = [];
x(x<xmin | x > xmax) = [];

out = []
b = floor(length(x)/n)
for i=1:n
    out(i,:) = [mean(x(i*b-b+1:i*b+1)),max(y(i*b-b+1:i*b+1))];
end

x = out(:,1);
y = out(:,2);

end

