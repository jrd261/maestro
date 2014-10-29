function mode = mdebugmode(newsetting)
%MDEBUGMODE Control whether debug mode is on or off.
%   MODE = MDEBUGMODE will return whether or not we are in debug mode.
%
%   MDEBUGMODE(NEWSETTING) will change the setting of debug mode to NEWSETTING.
%
%   Example:
%       If you set MDEBUGMODE(true)
%       MODE = MDEBUGMODE will then return true.
%
%   See also xxxx
%
%   Copyright (C) 2009-2010 James Dalessio

% Declare persistent variable to store the debug mode setting.
persistent MAESTRO_DEBUG_MODE 

% Set debug mode to false if it is currently empty.
if isempty(MAESTRO_DEBUG_MODE), MAESTRO_DEBUG_MODE = false; end

% Set it to the value of newsetting if it is specified. If we are deployed this is an error.
if nargin, if isdeployed, error('MAESTRO:mdebugmode:debugInDeployedMode','Cannot turn debug mode on in deployed application'); end, MAESTRO_DEBUG_MODE = newsetting; end

% Retrieve the debug setting.
mode = MAESTRO_DEBUG_MODE;

