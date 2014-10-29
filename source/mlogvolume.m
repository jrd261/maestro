function logvolume = mlogvolume(logvolume)
%MLOGVOLUME Sets the verbosity (or volume) of MAESTRO log output
%   LOGVOLUME = MLOGVOLUME will return the current volume level of MAESTRO log output.
%
%   MLOGVOLUME(LOGVOLUME) will set the volume of MAESTRO log output to value given by the number LOGVOLUME. 
%
%   LOGVOLUME should be an integer between 0 and 4. It may be any other number however and should affect the functionality of the program
%
%   Examples:
%       LOGVOLUME = 3;
%       MLOGVOLUME(LOGVOLUME)
%
%       VOLUME = MLOGVOLUME 
%       
%   See also MLOG, MVOLUME, MTALK
%
%   Copyright (C) 2009-2010 James Dalessio


% Declare "MAESTRO_LOG_VOLUME_LEVEL" as persistant. We will store the value in this function.
persistent MAESTRO_LOG_VOLUME_LEVEL

% If the volume level has not been set, set it to 1 (standard volume).
if isempty(MAESTRO_LOG_VOLUME_LEVEL), MAESTRO_LOG_VOLUME_LEVEL = 1; end

% Check if an input volume was specified.
if nargin, 
    % Check if the volume specified is a number.
    if ~isnumeric(logvolume)
        % If its not a number we will release a warning.
        warning('MAESTRO:mlogvolume:badVolumeLevel',['Attempted to set MAESTRO log volume level to non numeric value. Level remains at ',num2str(MAESTRO_LOG_VOLUME_LEVEL),'.']);    
    else
        % If it is a number we will set the persistent variable to the appropriate value.
        MAESTRO_LOG_VOLUME_LEVEL = logvolume;        
    end            
end

% Assign the output variable the value of MAESTRO_VOLUME_LEVEL.
logvolume = MAESTRO_LOG_VOLUME_LEVEL;