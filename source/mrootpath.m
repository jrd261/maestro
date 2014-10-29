function rootpath = mrootpath
%MROOTPATH Returns the root owned path of Maestro.
%   ROOTPATH = MROOTPATH returns the root path of Maestro. Throws an error
%   if the path cannot be found.
%
%   EXAMPLE:
%       ROOTPATH = MROOTPATH
%
%   See also MUSERPATH
%
%   Copyright (C) 2009-2011 James Dalessio

% Obtain the path to the user configuration. This path is stored in the
% enviornment variable "MAESTRO_USER_PATH".
rootpath = getenv('MAESTRO_ROOT_PATH');

% Check if the user path is empty and if so throw an error.
if isempty(rootpath), error('MAESTRO:mrootpath:pathNotSet','Please set the enviornment variable "MAESTRO_ROOT_PATH" to the location where Maestro is unpacked.'); end

end
