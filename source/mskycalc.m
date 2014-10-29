function sky = mskycalc(image,x,y,a,b,s,method)
%MSKYCALC Calculates the sky (background level per pixel) for a section of
%an image.
%   MSKYCALC(IMAGE,X,Y,A,B) will return the calculated sky values at
%   positions (X,Y) on the 2d matrix IMAGE.  A and B are the minimum and
%   maximum annulus respectively. A 2-sigma rejection algorithm will be
%   used to eliminate extremum values by default.
%
%   MSKYCALC(IMAGE,X,Y,A,B,S) where S is a number, specifies the rejection
%   level for removing pixels. The default is 2.
%
%   MSKYCALC(IMAGE,X,Y,A,B,[],METHOD) where 'Method' is a string indicating
%   the method by which to perform the sky calculation.
%
%   METHOD can currently contain the string 'SIGMAREJECT', 'MEAN', 'MEDIAN', or 'IRAF'
%   (3*median-2*mean). 
%
%   Copyright (C) 2007-2011 James Dalessio

% Assert that there are at least 5 input arguments. This is the minimum
% number of input arguments required for this function.
assert(nargin>=5,'MAESTRO:mskycalc:badNumberInputArguments','MSKYCALC requires at least 5 input arguments.');

% Assert that x and y are one dimensional and have equal length. The large
% dimension of x and y is irrelavant (it can be nx1 or 1xn).
assert(isnumeric(x) && isnumeric(y) && length(x) == length(y) && numel(x) == length(x) && numel(y) == length(y),'MAESTRO:mskycalc:badXY','X and Y must be one dimensional arrays of the same length.'); 

% Assert that A and B must be scalars.
assert(isnumeric(a) && isnumeric(b) && numel(a) == 1 && numel(b) == 1 && b>a && a>=0 && b>0,'MAESTRO:mskycalc:badAB','A and B must be positive scalars with B > A.');

% Check the number of input arguments. If there are less than 7 we specify
% the method as "sigmareject" and if there are less than 6 we specify the
% sigmareject level as 2 sigma.
if nargin < 7, method = 'sigmareject'; end
if nargin < 6, s=2; end

% Assert that the method must be a string. 
assert(ischar(method),'MAESTRO:mskycalc:badMethodClass','METHOD must be a string.');

% Assert that if the method is sigma rejection that s is a scalar and >0.
if strcmp(method,'sigmareject'), assert(isnumeric(s) && numel(s) == 1 && s>0,'MAESTRO:mskycalc:badS','S must be a positive scalar.'); end
  
% Initialize the output. The output will be an array of numbers equal to
% the size of the the number of points specified by (x,y).
sky = zeros(length(x),1);

% Begin loop over all given points.
for iStar = 1:length(x)    
    
    % Extract arrays of x,y, and image values given the annuli a and b from
    % position x,y. If no pixels fall within the range empty arrays are
    % returned.
    [xx,yy,zz] = mrip(image,x(iStar),y(iStar),a,b); %#ok<ASGLU>                
        
    % Switch statement to determine the method we will use to calculate the
    % sky value.
    switch method
        case 'sigmareject'
            % We take the mean of the sigma rejected pixels.
            sky(iStar) = mean(msigmareject(zz,s));            
        case 'mean'
            sky(iStar) = mean(zz);
        case 'median'
            sky(iStar) = median(zz);
        case 'iraf'
            % I have no idea why this is done in certain places in IRAF.
            sky(iStar) = 3*median(zz)-2*mean(zz);
        case 'mode'
            sky(iStar) = mode(zz);
        otherwise
            % The method was not recognized. Point the user towards some
            % help.
            errror('MAESTRO:mskycalc:badMethod',['Unknown sky calculation method "',method,'". Please see the function''s documentation.']);            
    end
    
end

end