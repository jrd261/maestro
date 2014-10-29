function fid = open(obj,permission)
%OPEN Summary of this function goes here
%   Detailed explanation goes here


if nargin==1 || strcmp(permission,{'r','read'})
    
    % Make sure the file exists.
    if ~obj.FileObject.Exists, error('MAESTRO:FITS:fitscheck:noExist','The file does not exist.'); end
    
    % Make sure the file has the proper size.
    if round(obj.FileObject.FileSize/2880) ~= obj.FileObject.FileSize/2880       
        Config = mconfig;
        if Config.CHECK_BLOCK_SIZE
            error('MAESTRO:FITS:fitscheck:badSize',['The file ',obj.FileObject.FullName,' does not appear to be a FITS file or is corrupt because it is not made of 2880 byte blocks.']);
        end       
    end
    
end


if nargin>1
    fid = obj.FileObject.open(permission);
else
    fid = obj.FileObject.open;
end




