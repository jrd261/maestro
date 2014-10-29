function z = msigmareject(x,s)
%MSIGMAREJECT Summary of this function goes here
%   Detailed explanation goes here

while(1)
    
    z = x;       
    
    % Remove the bad sky.
    x(abs(x-mean(x)) > s*std(x)) = [];
    
    % Break if we have not removed any pixels.
    if length(x) == length(z) || isempty(x), break, end    
    
end

    



end

