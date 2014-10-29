function splitimages = mimsplit(rawimage,cutregions)
%MIMSPLIT Summary of this function goes here
%   Detailed explanation goes here


for iImage = 1:size(rawimage,3)
    
    % Cycle over all regions.
    for iRegion = 1:length(cutregions)/4
        
        
        % Obtain source region.
        currentRegion = cutregions((iRegion-1)*4+1:(iRegion)*4);                      
        splitimages{iRegion}(:,:,iImage) = rawimage(currentRegion(3):currentRegion(4),currentRegion(1):currentRegion(2),iImage);

        
       
    end
    
end
   



