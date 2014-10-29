function volume = mvolume(volume)
%MVOLUME Sets the verbosity (or volume) of MAESTRO output.
%   VOLUME = MVOLUME will return the current volume level of MAESTRO output.
%
%   MVOLUME(VOLUME) will set the volume of MAESTRO to value given by the number VOLUME. 
%
%   VOLUME should be an integer between 0 and 4. It may be any other number however and should affect the functionality of the program
%
%   Examples:
%       VOLUME = 3;
%       MVOLUME(VOLUME)
%
%       VOLUME = MVOLUME 
%       
%   See also MTALK, MLOGVOLUME, MLOG
%
%   Copyright (C) 2009-2010 James Dalessio


% Declare "MAESTRO_VOLUME_LEVEL" as persistant. We will store the value in this function.
global MAESTRO_VOLUME_LEVEL

% If the volume level has not been set, set it to 1 (standard volume).
if isempty(MAESTRO_VOLUME_LEVEL), MAESTRO_VOLUME_LEVEL = 1; end

% Check if an input volume was specified.
if nargin, 
    % Check if the volume specified is a number.
    if ~isnumeric(volume)
        % If its not a number we will release a warning.
        warning('MAESTRO:mvolume:badVolumeLevel',['Attempted to set MAESTRO volume level to non numeric value. Level remains at ',num2str(MAESTRO_VOLUME_LEVEL),'.']);    
    else
        % If it is a number we will set the persistent variable to the appropriate value.
        MAESTRO_VOLUME_LEVEL = volume;        
    end            
end

% Assign the output variable the value of MAESTRO_VOLUME_LEVEL.
volume = MAESTRO_VOLUME_LEVEL;