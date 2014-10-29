function cmd_buildcal(args)
%BUILDCAL builds a FITS calibration.
%   BUILDCAL(ARGS) will calibrate a set of FITS images with standard
%   bias/dark/flats. It will write out a master bias dark and flat along
%   with other information about the calibration.
%
%   Copyright (C) 2009-2010 James Dalessio

% Display the copyright information.
mtalk(mcopyright);

% Check if a locale was specified and load it. Otherwise the current locale will be used.
if ~isempty(args.LOCALE_NAME), mlocale('load',args.LOCALE_NAME); end


% Obtain the output path to which we will write the data and ensure it exists on disk.
if ~isempty(args.OUTPUT_PATH), outputPath = mrelpath(args.OUTPUT_PATH{1},pwd); else outputPath = pwd; end, mmkdir(outputPath);

% Obtain the path the files were specified relative to.
if ~isempty(args.DATA_PATH), dataPath = mrelpath(args.DATA_PATH{1},pwd); else dataPath = pwd; end

% Convert the files to use their full intended path.
if ~isempty(args.BIAS_FILES), rawBiasFiles = mrelpath(args.BIAS_FILES,dataPath); else rawBiasFiles = []; end
if ~isempty(args.DARK_FILES), rawDarkFiles = mrelpath(args.DARK_FILES,dataPath); else rawDarkFiles = []; end
if ~isempty(args.FLAT_FILES), rawFlatFiles = mrelpath(args.FLAT_FILES,dataPath); else rawFlatFiles = []; end

% Build the calibration.
Calibration = CALIBRATION(rawBiasFiles,rawDarkFiles,rawFlatFiles);

% Save the calibration to disk.
%FITSCalibration.writeout(



% Get a list of object files

a = REDUCTION({'/home/dalessio/smarts2010/20101125/@objlist2'});
a.ObjectFITSList.assigncal(Calibration);
%a.reduce;

keyboard
