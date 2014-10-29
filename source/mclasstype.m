function classname = mclasstype(stringin)
%MCLASSTYPE Finds the standard maestro name of a class.
%   CLASSNAME = MCLASSTYPE(STRINGIN) will convert the string array specified by STRINGIN into a the name of class.
%   
%   Example:
%       STRINGIN = 'str'
%       CLASSNAME = MCLASSTYPE(STRINGIN) would return 'string'.
%
%   See also xxxx
%
%   Copyright (C) 2009-2010 James Dalessio

% Start a switch statement.
switch lower(stringin)
    case {'string','str','char'}
        classname = 'string';
    case {'numeric','number','double'}
        classname = 'numeric';
    case {'bool','boolean'}
        classname = 'boolean';
    otherwise
        error('MAESTRO:mclasstype:unknownClassType','Could not translate input into a class name.');
end

