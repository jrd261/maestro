function cellout = mstring2cell(stringin)
%MSTRING2CELL converts a string into a cell array of strings.
%   CELLOUT = MSTRING2CELL(STRINGIN) will convert the string specified by STRINGIN into a cell array of strings using whitespace as a seperator.
%
%   Example:
%       STRINGIN = 'I love a parade.'
%       CELLOUT = MSTRING2CELL(STRINGIN) is equivalent to CELLOUT = {'I','love','a','parade.'}
%       
%   See also MCELL2STRING
%
%   Copyright (C) 2009-2010 James Dalessio

% Very simple regexp statement can handle this. See regexp for more details.
cellout = regexp(stringin,'\S*','match');