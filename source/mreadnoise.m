function readnoise = mreadnoise
%MREADNOISE Summary of this function goes here
%   Detailed explanation goes here


% Return the readnoise in ADU. Throw an error if we can't.

Locale = mconfig;

switch Locale.CCD_STATISTICS_SOURCE
    case {'cal','calibration'}
        Calibration = mcal;
        readnoise = Calibration.ReadNoise;                
    case {'auto','automatic'}
        Calibration = mcal;
        readnoise = Calibration.ReadNoise;
        if isempty(readnoise), readnoise = Locale.READNOISE; end
        
    case {'locale'}
        readnoise = Locale.READNOISE;        
end
            

if isempty(readnoise), error('MAESTRO:mreadnoise:notSet','Readnoise is not set!'); end



