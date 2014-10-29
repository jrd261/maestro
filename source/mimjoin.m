function joinedimage = mimjoin(splitimage,pastesection)
%MIMJOIN Summary of this function goes here
%   Detailed explanation goes here
  % Begin loop over object list.
  
  
 
  % Cycle over all regions.
  for iRegion = 1:length(splitimage)
      for iImage=1:size(splitimage{iRegion},3)
          
          % Obtain target region.
          targetRegion = pastesection((iRegion-1)*4+1:(iRegion)*4);
          
         
          % Create section of new image.
          joinedimage(targetRegion(3):targetRegion(4),targetRegion(1):targetRegion(2),iImage) = splitimage{iRegion}(:,:,iImage);
          
      end
      
  end
  
  
  
  
  
  
  



