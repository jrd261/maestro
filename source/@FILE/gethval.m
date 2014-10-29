function [value,comment] = gethval(obj,keyword,default)


H = obj.Header;
liCompare = find(strcmp(H(:,1),keyword));
if length(liCompare) > 1
    liCompare = liCompare(1);
end
try
    value = H{liCompare,2};
    comment = H{liCompare,3};
catch ME
    value = default;
    comment = '';    
end


end

