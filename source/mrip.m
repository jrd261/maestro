function varargout = mrip(image,x,y,a,b)
%MRIP Summary of this function goes here
%   Detailed explanation goes here

xMax = min(ceil(x+b),size(image,2));
xMin = max(floor(x-b),1);
yMax = min(ceil(y+b),size(image,1));
yMin = max(floor(y-b),1);

[xx,yy] = meshgrid(xMin:xMax,yMin:yMax);
zz = image(yMin:yMax,xMin:xMax);

liBadIndicies = ((xx-x).^2+(yy-y).^2 > b^2 | (xx-x).^2+(yy-y).^2 < a^2);

xx(liBadIndicies) = []; xx = xx';
yy(liBadIndicies) = []; yy = yy';
zz(liBadIndicies) = []; zz = zz';


if nargout == 3 || nargout == 4, varargout = {xx,yy,zz}; elseif nargout == 1, varargout = {zz}; end
if nargout == 4
    if ceil(x+b) > size(image,2) || ceil(y+b) > size(image,1) || floor(x-b) < 1 || floor(y-b) < 1               
        varargout{4} = true; 
    else        
        varargout{4} = false;
    end        
end
    

end

