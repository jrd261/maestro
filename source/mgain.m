function gain = mgain


% Return the gain in e-/ADU. Throw an error if we can't.

Locale = mconfig;

switch Locale.CCD_STATISTICS_SOURCE
    case {'cal','calibration'}
        Calibration = mcal;
        gain = Calibration.Gain;                
    case {'auto','automatic'}
        Calibration = mcal;
        gain = Calibration.Gain;
        if isempty(gain), gain = Locale.GAIN; end
        
    case {'locale'}
        gain = Locale.GAIN;        
end
            

if isempty(gain), error('MAESTRO:mgain:notSet','Unable to determine gain. Gain must be set manually or flat fields must be given.'); end