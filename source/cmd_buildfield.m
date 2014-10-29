function  cmd_buildfield(args)
%CMD_BUILDFIELD is the MAESTRO command to build a field from a set of
%images.
%   CMD_REDUCE(ARGS) will use a set of images and write a field to disk
%
%   Copyright (C) 2009-2011 James Dalessio

%% COPYRIGHT NOTICE
% Display the copyright information. MCOPYRIGHT returns some formatted text that
% is sent as the input argument to the MTALK function. This essentially
% will write out the copyright information if the verbosity is set to the
% normal level (1).
mtalk(mcopyright);

%% RECORD REDUCTION START TIME
% Record the staring time of the reduction. This is a some matlab
% definition of absolute time in terms of days.
startingTime = now;

%% ASSIGN STAR FIELD LABELING FILE
% If a star field was specified it is recorded with the 'assignfield'
% action of the mhspred control function.
if ~isempty(args.FIELD_NAME)
    mtalk('\n VALIDATING SPECIFIED FIELD'); 
    mhspred('assignfield',args.FIELD_NAME{1}); 
end

%% BUILD LISTS OF FITS FILES
% The files that will be used for the reduction can be specified from the
% users end in four different ways.
% 1) The bias, dark, flat, and object files can be specified manually, each
% with their own flag.
% 2) Lists of object, bias, flat, and dark files.
% 3) If no arguments and no flags relavant to files were specified we will
% autobuild using /<pwd>/* as the file specification. 
mtalk('\nBUILDING LISTS OF FITS FILES');
mfits('autobuild',args); 
mfits('display_status');
mfits('object_check');

mtalk('\n\nCHECKING FILE INTEGRITY');
mfits('integritycheck','OBJECT');
mfits('integritycheck','BIAS');
mfits('integritycheck','DARK');
mfits('integritycheck','FLAT');

mtalk('\n\nCHECKING FILE SIZES');
mfits('size_check','OBJECT');
mfits('size_check','BIAS');
mfits('size_check','DARK');
mfits('size_check','FLAT');

mtalk('\n\nCHECKING FITS KEYWORDS');
mfits('keywordcheck','OBJECT');



%% BUILD THE CALIBRATION
% The calibration will be built based on the current locale. The
% calibration build will also set the gain and readnoise if biases and
% flats are given. If no bias, darks, and flats were given the calibration
% will still be "built" but will contain no real information.
% Build the calibration by calling the MCAL function. See MCAL for more
% information. Essentially this builds a calibration and stores it for us.
mcal('build');


%% BUILD THE FIELD
mhspred('buildfield');
%mhspred('labelfield');

%% RECORD REDUCTION OUTPUT

% Assign the full file name into the reduction.
if ~isempty(args.OUTPUT_NAME)
    [junk,name] = fileparts(args.OUTPUT_NAME{1}); %#ok<ASGLU>
    mhspred('assignfieldname',name);    
else
    mhspred('assignfieldname',datestr(now,'yyyy-mm-ddTHH:MM:SS'));
    
end

% Attempt to write out the reduction to file. We call the save command
% which will write the object to disk. The filename we retrieved above will
% be used. We append a / between the path and filename and add the
% extension .hpr to the end of the filename.
mhspred('savefield');

mtalk('\n\n');
