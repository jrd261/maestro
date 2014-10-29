function [x2,y2] = marearesample(x1,y1,xmin,xmax,n)

y1(x1<xmin | x1 > xmax) = [];
x1(x1<xmin | x1 > xmax) = [];


dx2 = (max(x1)-min(x1))/(n-1);
x2 = (0:n-1)'/(n-1)*(max(x1) - min(x1)) + min(x1);
y2 = zeros(n,1);

for i=1:length(y2)

  y2(i) = max(y1(x1 > x2(i) - dx2 & x1 < x2(i) + dx2));

end

end

