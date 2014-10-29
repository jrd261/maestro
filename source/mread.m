function [data,header] = mread(filename,format)
%MREAD Reads in an MDF (Maestro data file)
%   DATA = MREAD(FILENAME) reads in a file given by the string
%   FILENAME. 
%
%   Example:
%       DATA = MREAD('test.moc')
%
%   See also textscan
%
%   Copyright (C) 2009-2011 James Dalessio
data = [];
header = [];

warning off all
File = FILE(filename); 
if nargin > 1
    data = textscan(File.open,format,'CommentStyle','#','CollectOutput',true); File.close;
    header = File.Header;
    data = data{1}; return;       
end


fid = File.open;
while(1)    
    line = fgetl(fid);          
    if isnumeric(line), return; end
    line = mstring2cell(line);            
    if isempty(line), continue; end
    if line{1}(1) == '#', continue; end    
    n = length(line); 
    break    
end
File.close;

data = textscan(File.open,repmat('%s ',[1,n]),'CommentStyle','#','CollectOutput',true);
data = data{1}; File.close;




header = File.Header;

end

