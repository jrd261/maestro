function message = mcommandhelp(name)
%MCOMMANDHELP generates a generic help message for a command.
%   MESSAGE = MCOMMANDHELP(NAME) Generates a string MESSAGE for the given command NAME.
%
%   Example:
%       NAME = 'command1';
%       MESSAGE = MCOMMANDHELP(NAME);
%
%   See also xxxx
%
%   Copyright (C) 2009-2010 James Dalessio

% This is rather straight forward. 
message = ['For help with this command type "maestro command ',name,'".'];