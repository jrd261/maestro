function stringout = mcell2string(cellin)
%MCELL2STRING Converts a cell array of strings to a single string.
%   STRINGOUT = MCELL2STRING(CELLIN) will convert the cell array specified by CELLIN into a single string by inserting whitespace between each
%   entry.
%   
%   Example:
%       CELLIN = {'Help','Me'}
%       STRINGOUT = MCELL2STRING(CELLIN) would return 'Help Me'
%
%   See also MSTRING2CELL
%
%   Copyright (C) 2009-2010 James Dalessio

% This is pretty simple. Initialize the output variable and append
% each word of the cell array into it (with a space inserted).
stringout = '';

% Loop over and combine each segment into one string using a
% whitespace as a seperator. This is a variable growing in a loop but we
% will have to deal with it here.
for iCell=1:length(cellin), stringout = [stringout,' ',cellin{iCell}]; end %#ok<AGROW> Marking that it is ok that the variable is growing in a loop.
     
% Trim off all leading and ending whitespace.
stringout = strtrim(stringout);