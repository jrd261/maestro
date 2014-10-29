function  cmd_reduce(args)
%CMD_REDUCE is the MAESTRO command to reduce a FITS image set.
%   CMD_REDUCE(ARGS) will reduce a set of FITS images and save the
%   reduction to disk.
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
mtalk('\n\nBUILDING LISTS OF FITS FILES');
mfits('autobuild',args); 
mfits('display_status');
mfits('object_check');


mtalk('\n\nCHECKING FILE INTEGRITY');
mfits('integritycheck','OBJECT');
mfits('integritycheck','BIAS');
mfits('integritycheck','DARK');
mfits('integritycheck','FLAT');
if args.SKIP_SIZE_CHECK
  mtalk('\n\nIGNORING FILE SIZES');
else
  mtalk('\n\nCHECKING FILE SIZES');
  mfits('size_check','OBJECT');
  mfits('size_check','BIAS');
  mfits('size_check','DARK');
  mfits('size_check','FLAT');
end
mtalk('\n\nCHECKING FITS KEYWORDS');
mfits('keywordcheck','OBJECT');

if args.DEVELOPMENT
    mtalk('yo');
    mfield('build');
    
else
    
    %% CHECK OUTPUT FILE NAME
    % The last thing we would want to do is to perform the whole reduction only
    % to find out the output path is write protected. There are several ways
    % (from the users pov) that the output file name can be specified.
    % 1) The second argument or a flag to the command could specify the output path.
    % 2) The second argument of a flag to the command could specify the output
    % filename.
    % 3) No output name was specified and we will generate one automatically.
    
    % Obtain the path, name, and ext of the specified file. If none was
    % specified, path will contain the pwd and name and ext will be empty.Also
    % check that the output path exists and is writable. If it does not exist
    % this command will create it. If it is not writable this command will
    % throw an error.
    if isempty(args.OUTPUT_NAME)
        path = pwd;
        name = '';
        ext = '';
    else
        [path,name,ext] = fileparts(mrelpath(args.OUTPUT_NAME{1},pwd));
        if isdir([path,filesep,name,ext])
            path = [path,filesep,name];
            name = '';
        end
        mmkdir(path);
    end
    
    
    % "EXT" should contain the part of the filename that follows the first ".".
    % The extension of a maestro high speed photometry reduction file is
    % ".hsp". If this is not the given extension concatenate this onto the
    % given extension.
    if ~strcmpi(ext,'.hsp'), ext = [ext,'.hsp']; end
    
    
    %% BUILD THE CALIBRATION
    % The calibration will be built based on the current locale. The
    % calibration build will also set the gain and readnoise if biases and
    % flats are given. If no bias, darks, and flats were given the calibration
    % will still be "built" but will contain no real information.
    % Build the calibration by calling the MCAL function. See MCAL for more
    % information. Essentially this builds a calibration and stores it for us.
    mcal('build');
    
    %% REDUCE THE DATASET
    % The reduction is executed here. We use the MHSPRED function to start the
    % reduction. If the reduction completes we will also save the reduction to
    % a file, and dump a bunch of text files pertinant to the reduction if
    % asked to. Reduce the data. This is where most of the action occurs. See the
    % function MHSPRED for more information. If no errors are thrown we should
    % have a fully reduced set of data after this concludes.
    mhspred('reduce');
    
    %% RECORD REDUCTION OUTPUT
    
    % If there was no output name specified ask for the reduction to generate a
    % unique name for us.
    if isempty(name), name = mhspred('generatefilename'); end
    
    % Assign the full file name into the reduction.
    mhspred('assignfilename',[path,filesep,name,ext]);
    
    % Attempt to write out the reduction to file. We call the save command
    % which will write the object to disk. The filename we retrieved above will
    % be used. We append a / between the path and filename and add the
    % extension .hpr to the end of the filename.
    %mhspred('save'); % Disabled until hsp files are used
    
    % Here we check if we should dump the data if the user wants a bunch of
    % text files containing information about the reduction. This will create a
    % directory matching the filename that was generated above. In this
    % directory everything about the reduction will be written in a clutter of
    % ASCII files.
    %if args.DUMP_ALL, mhspred('dump'); end
    mhspred('dump');
    mtalk('\n');
    t = datestr((now-startingTime),'HH:MM:SS');
    mtalk(['\nReduction complete. Total time: ',t]);
    mtalk('\n\n');
end
