function [s,a,n,p] = maperture(image,x,y,r,method,options) %#ok<INUSD>
%MAPERTURE Calculates the flux within some annuli R of the points (X,Y).
%   S = MAPERTURE(IMAGE,X,Y,R) where IMAGE is a 2d matrix will return the total
%   number of counts within an annulus R using no weights and polygonal
%   pixel rounding. S will have size nxm where n is the number of points
%   (X,Y) specified and m is the number of apertures R specified.
%
%   [S,A] = MAPERTURE(...) will return A, the total area enclosed by each 
%   aperture.
%
%   [S,A,N] = MAPERTURE(IMAGE,...) where IMAGE is an nxmx2 matrix with 
%   IMAGE(:,:,1) representing signal and IMAGE(:,:,2) representing noise
%   will return the N, the standard error in S.
%
%   [S,A,N,P] = MAPERTURE(...) will return a logical array P with values
%   set to true if the return number of counts came from a partial image.
%   For some methods this array will always be false.
%
%   MAPERTURE(IMAGE,X,Y,R,METHOD) will use the method specified by METHOD
%   to perform the synthetic aperture. The default method is 'tophat' and
%   other possible methods are "".
%
%   MAPERTURE(IMAGE,X,Y,R,METHOD,OPTIONS) specifies options for the given
%   method. This is not yet implemented but will allow for elliptical
%   apertures.
%
%   Copyright (C) 2007-2011 James Dalessio

% Check if the method was specified. If not specify the default method.
if nargin == 4, method = 'tophat'; end

% Initialize array of counts and area based on the 
s = zeros(length(x),length(r));
n = zeros(length(x),length(r));
a = zeros(length(x),length(r));
p = false(length(x),length(r));

% Use a switch statement to determine how to perform the aperture.
switch method
    case 'tophat'
        
        if size(image,3) == 1; doNoise = false; else, doNoise = true; end
        
        % Begin loop over aperture list
        for iAperture = 1:length(r)
            
            R = r(iAperture);
            
            % Begin loop over stars.
            for iStar = 1:length(x)
                                                 
                
              
              
              xMax = min(ceil(x(iStar)+r(iAperture)+1),size(image,2));
              xMin = max(floor(x(iStar)-r(iAperture)-1),1);
              yMax = min(ceil(y(iStar)+r(iAperture)+1),size(image,1));
              yMin = max(floor(y(iStar)-r(iAperture)-1),1);
              
              [xx,yy] = meshgrid(xMin:xMax,yMin:yMax);
              zz = image(yMin:yMax,xMin:xMax,1);
              if doNoise, nn = image(yMin:yMax,xMin:xMax,2); end
              
              liBadIndicies =  (xx-x(iStar)).^2+(yy-y(iStar)).^2 > r(iAperture)^2;
              
              xx(liBadIndicies) = []; xx = xx';
              yy(liBadIndicies) = []; yy = yy';
              zz(liBadIndicies) = []; zz = zz';
              if doNoise, nn(liBadIndicies) = []; nn = nn'; end
            
                                 
                % Initialize image mask.
                imageMask = zeros(size(zz));
                                
                % Pay attention, this is complicated. But well tested.
                dx = abs(xx-x(iStar));
                dy = abs(yy-y(iStar));
                xp = dx+1/2;
                xm = dx-1/2;
                yp = dy+1/2;
                ym = dy-1/2;
                
                numi = (xp.^2 + yp.^2 <= R^2) + (xm.^2 + yp.^2 <= R^2) + (xp.^2 + ym.^2 <= R^2) + (xm.^2 + ym.^2 <= R^2);
                
                imageMask(numi==4) = 1;
                imageMask(numi==0) = 0;
                
                a1ind = (numi==1);                
                a2ind_x = (numi==2 & dx >= dy);
                a2ind_y = (numi==2 & dx < dy);
                a3ind = (numi==3);
                
                imageMask(a1ind) = 1/2*((R^2-xm(a1ind).^2).^.5-ym(a1ind)).*((R^2-ym(a1ind).^2).^.5-xm(a1ind));
                imageMask(a3ind) = 1-1/2*(yp(a3ind)-(R^2-xp(a3ind).^2).^.5).*(xp(a3ind)-(R^2-yp(a3ind).^2).^.5);
                imageMask(a2ind_x) = 1/2*((R^2-yp(a2ind_x).^2).^.5-xm(a2ind_x) + (R^2-ym(a2ind_x).^2).^.5-xm(a2ind_x));
                imageMask(a2ind_y) = 1/2*((R^2-xp(a2ind_y).^2).^.5-ym(a2ind_y) + (R^2-xm(a2ind_y).^2).^.5-ym(a2ind_y));
                                               
                s(iStar,iAperture) = sum(imageMask(:).*zz(:));
                a(iStar,iAperture) =   sum(imageMask(:));
                if doNoise, n(iStar,iAperture) = sum((imageMask(:).*nn(:)).^2)^(1/2); end
                p(iStar,iAperture) = any(liBadIndicies(:));
                
            end

        end     
        
end

end