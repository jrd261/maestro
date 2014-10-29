function buildmasterflat(Calibration)
%BUILDMASTERFLAT constructs a master flat for the Calibration object.
%   BUILDMASTERFLAT(CALIBRATION) will use the current flat fits list to
%   generate a master flat and store it in the Calibration. It will also
%   calculate the gain (and convert the reanoise to e-) from the flat images.
%
%   See also CALIBRATION
%
%   Copyright (C) 2007-2011 James Dalessio

%% PREPARE TO BUILD A MASTER FLAT
% Retrieve the list of flat FITS objects. This will write to "FlatList", an
% array of FITS objects. Check that the flat list is not empty. If this is
% the case there is no reason to continue building anything, so we just
% return and no modification will be done to the master bias.
FlatList = mfits('retrieve','FLAT'); if isempty(FlatList), return; end

% Display a little heading to indicate that a master flat is being built.
% There will be several processes initiated here that will follow up this
% heading.
mtalk('\n\nBUILDING MASTER FLAT');

% Load in the locale. We will need the locale for knowing how to combine
% the flat images together.
Locale = mconfig; 

%% BUILD THE MASTER FLAT
% Build a cube containing all of the flat images. We build the bias cube
% with raw images. If an image fails when building the flat cube note it
% will not be returned as part of the cube. The errorneous FITS image will
% be recorded as such within themselves.
flatCube = FlatList.buildcube('calibrated');

% We need to divide the flats by there average, or more robustly their
% median level in order to combine them. We will have to use a little
% reshaping to do this in one calculation. First we will calculate the
% signal level for each flat.
signalLevel = median(reshape(flatCube,[size(flatCube,1)*size(flatCube,2),size(flatCube,3)]));

% Now we need to normalize all flats by the signal level. In order to do
% this we need to use a repmat function.
flatCube = flatCube./repmat(reshape(signalLevel,[1,1,size(flatCube,3)]),[size(flatCube,1),size(flatCube,2),1]);

% Check the current method of calibration. Right now the only way to
% calibrate images is called "STANDARD". This is just the typical master
% bias, dark and flat subtraction we are all used to.
switch Locale.CALIBRATION_STYLE
    case {'standard','Standard','STANDARD'}
        % The locale method is standard. This means we need to combined the
        % master bias into a single image. To determine how to combine the
        % images check the locale entry for "FLAT_COMBINE_METHOD"
        switch Locale.FLAT_COMBINE_METHOD
            case 'mean'
                % Perform a simple averaging over the 3rd dimension of the
                % bias cube. This is the same as averaging each pixel.
                Calibration.MasterFlat = mean(flatCube,3);
            case 'median'
                % Most flats will be median combined. This way of median
                % combining is much faster than the matlab MEDIAN function.
                sortedFlatCube = sort(flatCube,3);
                Calibration.MasterFlat = sortedFlatCube(:,:,ceil(size(flatCube,3)/2));
            otherwise
                % The flat combine method is unknown. Display an error and
                % let the user know what the problem was.
                error('MAESTRO:buildmasterflat:badFlatCombineMethod','The current locale entry for "FLAT_COMBINE_METHOD" is unrecognized. Please check your locale and try again.');
        end
    otherwise
        % The calibration style was unrecognized. Display an error and let
        % the user know the locale is improperly configured.
        error('MAESTRO:buildmasterflat:badCalibrationStyle','The current locale entry for "CALIBRATION_STYLE" is unrecognized. Please check your locale and try again.');
end

%% CALCULATE THE GAIN
% We have the oppurtunity to calculate the gain if more than one flat image
% was specified and the read noise is known. First check that we can
% retrieve the readnoise without any error. If there is an error return.
try readnoise = mreadnoise; catch ME, return, end %#ok<NASGU>
if length(FlatList) < 2, return, end

% Let the user know what this time is spent doing. This can be a long
% calculation on slower machines. We will make this a process.
pid = mprocessinit('\n Calculating gain from flat fields...');

% From the standard deviation of a flat image the gain can be
% calculated. The first thing we need to do is to subtract the averaged
% master flat from the flat cube. We cannot simply subtract the master flat
% as there are some biases associated with a median combining. 
flatCube = flatCube-repmat(mean(flatCube,3),[1,1,size(flatCube,3)]);

N = size(flatCube,3);
R = (N/(N-1))^(1/2);

% Check to see if the images are being trimmmed. 
if Locale.TRIM_IMAGE
    
    % As every amplifier should
    % have its own trim section the gain for each section can be
    % different. Use MIMSPLIT to split the flat cube into sections. See
    % MIMSPLIT for more information.
    splitImageCube = mimsplit(flatCube,Locale.TRIM_PASTE_REGION);
    
    % Initialize the gain measurement as it will be done for each region.
    imageGain = zeros(length(splitImageCube),length(FlatList));
    
    % Begin to loop over all sections. Each section (or amplifier section)
    % of each image will have its own gain calculated.
    for iRegion = 1:length(splitImageCube)
        for iImage = 1:length(FlatList)
            
            % Extract the difference image between the current flat image
            % and the master. 
            diffImage = splitImageCube{iRegion}(:,:,iImage);                        
           
            % Calculate the gain of this region of this image. This is a
            % simple statistical problem.
            imageGain(iRegion,iImage) = signalLevel(iImage)/(signalLevel(iImage)^2*mrobuststd(diffImage(:))^2*R^2-readnoise(iRegion)^2);
           
		
            % Update the progress for the gain calculation to the user.
            mprocessupdate(pid,iImage/length(FlatList));
            
        end
    end            
            
else
    
    % Initialize an array to store the gain for eahc image.
    imageGain = zeros(length(FlatList),1);
    
    % Begin a loop over all images. We will calculate the gain from each
    % image and then average them together.
    for iImage = 1:length(FlatList)
        
        % Obtain the difference image between this image and the master
        % flat.
        diffImage = flatCube(:,:,iImage);
        
        % Calculate the gain of this image. Work out the statistics if
        % you'd like.
        
        imageGain(iImage) = signalLevel(iImage)/(signalLevel(iImage)^2*mrobuststd(diffImage(:))^2*R^2-readnoise^2);
        
        % Update the progress for the gain calculation to the user.            
        mprocessupdate(pid,iImage/length(FlatList));
        
    end
    imageGain = imageGain';

    
end

% Take the median from all images to calculate the actual gain. The
% Gain will now be an nx1 array with an entry for each region.
Calibration.Gain = median(imageGain,2)';

% Let the user know the process is complete and was sucessful. We also need
% to let the user know the gain. 
mprocessfinish(pid,1); mtalk('\n Gain for each amplifier in e-/ADU:'); 
for iRegion = 1:length(Calibration.Gain), mtalk([' (',num2str(Calibration.Gain(iRegion)),')']); end
