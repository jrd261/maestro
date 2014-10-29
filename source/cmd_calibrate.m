function cmd_calibrate(args)

%% COPYRIGHT NOTICE
% Display the copyright information. MCOPYRIGHT returns some formatted text that
% is sent as the input argument to the MTALK function. This essentially
% will write out the copyright information if the verbosity is set to the
% normal level (1).
mtalk(mcopyright);



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


%% BUILD THE CALIBRATION
% The calibration will be built based on the current locale. The
% calibration build will also set the gain and readnoise if biases and
% flats are given. If no bias, darks, and flats were given the calibration
% will still be "built" but will contain no real information.
% Build the calibration by calling the MCAL function. See MCAL for more
% information. Essentially this builds a calibration and stores it for us.
mcal('build');


Fits = mfits('retrieve','object');
pid = mprocessinit('\n Calibrating and writing out files...');

for i=1:length(Fits)
    
    fi = fitsinfo(Fits(i).FileObject.FullName);
    [a,b,c] = fileparts(Fits(i).FileObject.FullName);
    
    fitswrite(Fits(i).CalibratedImage',[a,filesep,b,'_CALIBRATED',c],fi.PrimaryData.Keywords);
    mprocessupdate(pid,i/length(Fits));
end
mprocessfinish(pid,true);

mtalk('\n\n');
end