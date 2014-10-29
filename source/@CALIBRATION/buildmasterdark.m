function buildmasterdark(Calibration)
%BUILDMASTERDARK constructs a master dark for the Calibration object.
%   BUILDMASTERDARK(CALIBRATION) will use the current dark fits list to
%   generate a master dark and store it in the Calibration. It will use the
%   current master bias for calibration.
%
%   See also CALIBRATION
%
%   Copyright (C) 2007-2011 James Dalessio

%% PREPARE TO BUILD A MASTER DARK
% Retrieve the list of bias FITS objects. This will write to "BiasList", an
% array of FITS objects. Check that the bias list is not empty. If this is
% the case there is no reason to continue building anything, so we just
% return and no modification will be done to the master bias.
DarkList = mfits('retrieve','DARK'); if isempty(DarkList), return; end

% Display a little heading to indicate that a master dark is being built.
% There will be several processes initiated here that will follow up this
% heading.
mtalk('\n\nBUILDING MASTER DARK');

% Load in the locale. We will need the locale for knowing how to combine
% the dark images together.
Locale = mconfig; 

%% BUILD THE MASTER DARK
% Build a cube containing all of the dark images. We build the bias cube
% with raw images. If an image fails when building the dark cube note it
% will not be returned as part of the cube. The errorneous FITS image will
% be recorded as such within themselves.
darkCube = DarkList.buildcube('calibrated');
darkCube = darkCube./repmat(reshape([DarkList.ExposureTime],1,1,length(DarkList)),[size(darkCube,1),size(darkCube,2),1]);

% Check the current method of calibration. Right now the only way to
% calibrate images is called "STANDARD". This is just the typical master
% bias, dark and flat subtraction we are all used to.
switch Locale.CALIBRATION_STYLE
    case {'standard','Standard','STANDARD'}
        % The locale method is standard. This means we need to combined the
        % master dark into a single image. To determine how to combine the
        % images check the locale entry for "DARK_COMBINE_METHOD"
        switch Locale.DARK_COMBINE_METHOD
            case 'mean'
                % Perform a simple averaging over the 3rd dimension of the
                % dark cube. This is the same as averaging each pixel.
                Calibration.MasterDark = mean(darkCube,3);
            case 'median'
                % Most darks will be median combined to get rid of CRs and
                % such.
                sortedDarkCube = sort(darkCube,3);
                Calibration.MasterDark = sortedDarkCube(:,:,ceil(size(darkCube,3)/2));
            otherwise
                % The dark combine method is unknown. Display an error and
                % let the user know what the problem was.
                error('MAESTRO:buildmasterdark:badDarkCombineMethod','The current locale entry for "DARK_COMBINE_METHOD" is unrecognized. Please check your locale and try again.');
        end
    otherwise
        % The calibration style was unrecognized. Display an error and let
        % the user know the locale is improperly configured.
        error('MAESTRO:buildmasterdark:badCalibrationStyle','The current locale entry for "CALIBRATION_STYLE" is unrecognized. Please check your locale and try again.');
end