function build(Calibration)

% We will notify the user (and write to the log) some information about
% which types of calibration we will be using. To determine which we will
% be using we check to see if each type of fits object is populated (or
% empty).
mtalk('\n\nBEGINNING CALIBRATION BUILD');            
mtalk('\n Building a master bias? '); if isempty(mfits('retrieve','BIAS')), mtalk('[N]'); else mtalk('[Y]'); end
mtalk('\n Building a master dark? '); if isempty(mfits('retrieve','DARK')), mtalk('[N]'); else mtalk('[Y]'); end
mtalk('\n Building a master flat? '); if isempty(mfits('retrieve','FLAT')), mtalk('[N]'); else mtalk('[Y]'); end                                

% Now we will build the bias, dark, and flat. Each of the subroutines will
% automatically check if there are bias, dark, and flat files to build.
Calibration.buildmasterbias; 
Calibration.buildmasterdark; 
Calibration.buildmasterflat; 
