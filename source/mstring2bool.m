function boolout = mstring2bool(stringin)
%MSTRING2BOOL Converts a string into a true/false
%   BOOLOUT = MSTRING2BOOL(STRINGIN) will convert the string array specified by STRINGIN into a boolean true or false.
%   
%   Example:
%       STRINGIN = 'yes'
%       BOOLOUT = MSTRING2BOOL(STRINGIN) would return true.
%
%   See also xxxx
%
%   Copyright (C) 2009-2010 James Dalessio

% Start a switch statement.
switch stringin
    case {'Yes','yes','Y','y','True','true','T','t','Ok','ok','Yup','yup'}
        boolout = true;
    case {'No','no','N','n','Nope','nope','False','false','F','f'}
        boolout = false;
    otherwise
        error('MAESTRO:mstring2bool:notTranslatable','Could not translate input into a boolean value.');
end