function cellout = mcellstrcorrect(cellin)
%MCELLSTRCORRECTOR Summary of this function goes here
%   Detailed explanation goes here


cellout = cellin;
cellout = strtrim(cellout);
    
    cellout(cellfun(@(x) isempty(x),cellout)) = [];
   
    
    
