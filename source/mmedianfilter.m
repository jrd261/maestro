function [x,y] = mmedianfilter(x,y,s)

  bi = abs(y - median(y))/mrobuststd(y) > s;
  x(bi) = [];
  y(bi) = [];

end
