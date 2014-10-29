function buildmasterbias(Calibration)
%BUILDMASTERBIAS constructs a master bias for the Calibration object.
%   BUILDMASTERBIAS(CALIBRATION) will use the current bias fits list to
%   generate a master bias and store it in the Calibration. It will also
%   calculate the read noise (in ADU) from the bias images.
%
%   See also CALIBRATION
%
%   Copyright (C) 2007-2011 James Dalessio

%% PREPARE TO BUILD A MASTER BIAS
% Retrieve the list of bias FITS objects. This will write to "BiasList", an
% array of FITS objects. Check that the bias list is not empty. If this is
% the case there is no reason to continue building anything, so we just
% return and no modification will be done to the master bias.
BiasList = mfits('retrieve','BIAS'); if isempty(BiasList), return; end

% Display a little heading to indicate that a master bias is being built.
% There will be several processes initiated here that will follow up this
% heading.
mtalk('\n\nBUILDING MASTER BIAS');

% Load in the locale. We will need the locale for knowing how to combine
% the bias images together.
Locale = mconfig; 

%% BUILD THE MASTER BIAS
% Build a cube containing all of the bias images. We build the bias cube
% with raw images. If an image fails when building the bias cube note it
% will not be returned as part of the cube. The errorneous FITS image will
% be recorded as such within themselves.
biasCube = BiasList.buildcube('raw');

% Check the current method of calibration. Right now the only way to
% calibrate images is called "STANDARD". This is just the typical master
% bias, dark and flat subtraction we are all used to.
switch Locale.CALIBRATION_STYLE
    case {'standard','Standard','STANDARD'}
        % The locale method is standard. This means we need to combined the
        % master bias into a single image. To determine how to combine the
        % images check the locale entry for "BIAS_COMBINE_METHOD"
        switch Locale.BIAS_COMBINE_METHOD
            case 'mean'
                % Perform a simple averaging over the 3rd dimension of the
                % bias cube. This is the same as averaging each pixel.
                Calibration.MasterBias = mean(biasCube,3);
            case 'median'
                % If the bias needs to be median combined (for some strange
                % reason, sort the pixels and extract the middle image.
                sortedBiasCube = sort(biasCube,3);
                Calibration.MasterBias = sortedBiasCube(:,:,ceil(size(biasCube,3)/2));
            otherwise
                % The bias combine method is unknown. Display an error and
                % let the user know what the problem was.
                error('MAESTRO:buildmasterbias:badBiasCombineMethod','The current locale entry for "BIAS_COMBINE_METHOD" is unrecognized. Please check your locale and try again.');
        end
    otherwise
        % The calibration style was unrecognized. Display an error and let
        % the user know the locale is improperly configured.
        error('MAESTRO:buildmasterbias:badCalibrationStyle','The current locale entry for "CALIBRATION_STYLE" is unrecognized. Please check your locale and try again.');
end

%% CALCULATE THE READNOISE
% To calculate the readnoise we require that there is more than one bias.
% If there is not more than one bias we can just return and forget about
% calculating the readnoise.
if length(BiasList) < 2, return; end

% We will be calculating the readnoise from the set of bias images. This
% can take some time but we have no way of making this a process. Let the
% user know what we are doing however.
mtalk('\n Calculating readnoise from bias set... ');

% From the standard deviation of a bias image the readnoise can be
% calculated. The first thing we need to do is to subtract the master bias
% from all of the bias images. 
biasCube = biasCube-repmat(mean(biasCube,3),[1,1,size(biasCube,3)]);

N = size(biasCube,3);
R = (N/(N-1))^(1/2);

% Check to see if the images are being trimmmed. 
if Locale.TRIM_IMAGE
    % As every amplifier should
    % have its own trim section the read noise for each section can be
    % different. Use MIMSPLIT to split the bias cube into sections. See
    % MIMSPLIT for more information.
    splitImageCube = mimsplit(biasCube,Locale.TRIM_PASTE_REGION);        
    
    % Begin to loop about each region (or amplifier). For each region the
    % read noise will be calculated independently. The read noise is
    % determined using the mhistfitter function which essentially is a
    % robust standard deviation calculator that uses a histogram fit.
    for iRegion = 1:length(splitImageCube), Calibration.ReadNoise(iRegion) = mrobuststd(splitImageCube{iRegion}(:))*R; end; mok;
                      
else
    
    % If there are no regions to loop over just find the standard deviation
    % of the bias cube itself by fitting a histogram.
    Calibration.ReadNoise = mrobuststd(biasCube(:))*R; mok;
    
end

% We want to let the user know what the readnoise is. By writing it out
% here it will become part of the log. 
mtalk('\n Read noise for each amplifier in ADU: '); 
for iRegion = 1:length(Calibration.ReadNoise), mtalk(['(',num2str(Calibration.ReadNoise(iRegion)),') ']); end

