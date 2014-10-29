function commandlist = mcommandlist
%MCOMMANDLIST Retrieves a list of available Maestro commands from the
%manifest.
%   COMMANDLIST = MCOMMANDLIST will retrieve the command list. The COMMANDLIST is an nx3 cell array. The first column
%   is the full name of the command. The second column contains cell arrays of aliases to the command. The third column is a description of the
%   command.
%
%   Example:
%       COMMANDLIST = MCOMMANDLIST
%
%   Copyright (C) 2009-2011 James Dalessio

% Read in the command list.
commandlist = mread([mrootpath,filesep,'manifest'],'%s %q %q');

% Convert the aliases into a cell format.
commandlist(:,2) = mstring2cell(commandlist(:,2));

% Sort the commands alphabetically.
[junk,sortOrder] = sort(commandlist(:,1)); %#ok<ASGLU>
commandlist = commandlist(sortOrder,:);


