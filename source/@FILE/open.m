function fid = open(obj,permission)
%OPEN Open a FILE object for reading/writing/appending.
%   This method opens a file and returns the FID. The FID is also stored in
%   the file object. Note only one instance of the file can be open by this
%   method. 
%
%   PERMISSION is optional and should be 'r', 'w', or 'a' for read, write,
%   and append respectively. If not specified the file will be opened in
%   read mode.
%
%   Copyright (C) 2010 James Dalessio


% Check if there are any input arguments. If there are the value for
% permission will need to be checked.
if nargin>1

    % The permission was specified. Start a switch statement to determine
    % whether the permission is ok as specified. Convert it to the format
    % taken by FOPEN.
switch permission
    case {'r','read'}
        permission = 'r';
    case {'w','write'}
        permission = 'w';
    case {'a','append'}
        permission = 'a';
    otherwise
        % The specified permission does not match. Throw an error.        
        error('MAESTRO:FILE:open:badPermission','The specified permission is unknown.');
end

else
    % The permission wasn't specified so assume the file is to be read.
    permission = 'r';
end

% Check that the file isn't already open. If it is throw an error.
%assert(obj.FID==-1,'MAESTRO:FILE:open:alreadyOpen',['Attempted to open a file , "',obj.FullName,'", that was already open']);
if obj.FID~=-1, fid = obj.FID; return; end

% Open the file. I do not believe fopen will throw an error but I could be
% mistaken. In the future this could deserve a try catch statement.
fid = fopen(obj.FullName,permission);

% If the file failed to open the fid is reported as -1. If it is -1 throw
% an error.
assert(fid ~= -1,'MAESTRO:FILE:open:openFail',['File "',obj.FullName,'" failed to open. Please check that the file exists and has appropriate read/write permissions.']); 

% Record the file indentifier in the FILE object.
obj.FID = fid;