function userpath = muserpath
%MUSERPATH Returns the user owned path of Maestro.
%   USERPATH = MUSERPATH returns the user path of Maestro. If the path
%   cannot be found an error is thrown.
%
%   EXAMPLE:
%       USERPATH = MUSERPATH
%
%   See also MROOTPATH
%
%   Copyright (C) 2009-2011 James Dalessio

% Obtain the path to the user configuration. This path is stored in the
% enviornment variable "MAESTRO_USER_PATH".
userpath = getenv('MAESTRO_USER_PATH');

% Check if the user path is empty and if so throw an error.
if isempty(userpath), error('MAESTRO:muserpath:pathNotSet','Please set the enviornment variable "MAESTRO_USER_PATH" to the location where the user''s Maestro files are located.'); end

end