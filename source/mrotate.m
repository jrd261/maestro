function [X,Y] = mrotate(X,Y,Theta)
%MROTATE Summary of this function goes here
%   Detailed explanation goes here


XTemp = X;
YTemp = Y;

X = XTemp.*cos(Theta)-YTemp.*sin(Theta);
Y = XTemp.*sin(Theta)+YTemp.*cos(Theta);


end

