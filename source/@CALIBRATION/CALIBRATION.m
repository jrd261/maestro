classdef CALIBRATION < handle
    properties               
        
        % For a standard calibration the master bias, dark, and flat will
        % be stored here. 
        MasterBias = 0;
        MasterDark = 0;
        MasterFlat = 1;                  
        
        % The gain (e-/ADU) and readnoise (ADU) are stored here. Note they
        % can also be stored in the locale. 
        Gain
        ReadNoise
            
    end   
end