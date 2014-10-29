classdef FITS <handle
    %FITS An abstraction of a FITS file.
    %   An object that stores information about existing FITS files, or
    %   FITS files that have not yet been created. Some properties are
    %   initiated by the class constructor but most of the properties are
    %   retrieved through dependent get methods.
    %
    %   Copyright (C) 2007-2010 James Dalessio
    
    properties (SetAccess = private)
        % These properties are populated by the class constructor. They can
        % only be modified by class methods.
        FileObject % A FILE class object goes here.
               
    end
    properties
        ImageType % A string indicating the type of image. 
        ActiveStarField
    end
    
    properties (Dependent, SetAccess = private)
        % These properties are populated on demand. There value is
        % determined by the output of a get.PAR method.
        RawPrimaryHeader % The primary header in its raw charecter array format.
        PrimaryHeader % The primary header in a nx3 column cell array.
        JulianDate % The julian date of the image.
        ExposureTime % The exposure time of the image.
        DarkTime % The dark time of the image.
        RawPrimaryImage % Storage for the primary raw image.
        PrimaryImage % Storage for the primary image with overscan and trim applied.
        PrimaryImageMedian % Median of the raw image.
        PrimaryImageMean % Mean of the raw image.
        PrimaryImageSTD % Standard deviation of the raw image.
        OverscanMean % The average value of the overscan region(s).
        CalibratedPrimaryImage % A calibrated primary image.
        NoisePrimaryImage % A image containing the total noise.
        SkyRemovedPrimaryImage % A calibrated image with the sky removed.
        LocatedStars % An array containing the positions of objects on the image.
        LocatedStarsDev
        RawImage
        CalibratedImage
        
        
        FullFileName
        ShortFileName
        
        
    end
    
    properties (Hidden)
        % These properties are hidden and store information that is
        % retrieved by the dependent property methods. Many of these
        % properties will remain empty until one of the above properties is
        % referenced. These properties will then store the information for
        % quicker reference.
        S_RawPrimaryHeader % Storage for the raw primary header.
        S_PrimaryHeader % Storage for the primary header.
        S_JulianDate % Storage for the Julian Date.
        S_ExposureTime % Storage for the exposure time.
        S_DarkTime % Storage for the dark time.
        S_RawPrimaryImage % Stroage for the raw image.
        S_PrimaryImage % Storage for the primary image.
        S_PrimaryImageMedian % Storage for the median of the raw image.
        S_PrimaryImageMean % Storage for the mean of the raw image.
        S_PrimaryImageSTD % Storage for the standard deviation of the raw image.
        S_OverscanMean % The average value of the overscan region(s).
        S_CalibratedPrimaryImage % The calibrated primary image is stored here.
        S_NoisePrimaryImage % The signal to noise image is stored here.
        S_SkyRemovedPrimaryImage % Storage for an image with the sky removed.
        S_LocatedStars % Storage fot the list of stars.
        S_LocatedStarsDev
    end
    
    
    methods
        function Fits = FITS(rawfiles,varargin)
            %FITS builds a FITS "Flexible Image Transport System" object.
            %   FITS = FITS(RAWFILES) creates an array of FITS objects
            %   representing the files specified by RAWFILES.
            %
            %   FITS(RAWFILES,PROP1,VAL1,PROP2,VAL2,...) specifies some
            %   information for building the list of FITS objects. See
            %   below for more information.
            %
            %   RAWFILES must be a string or cell array of strings. See the
            %   FILE object constructor for more information.
            %
            %   Here is a list of possible property value combinations:
            %
            %   Property: imagetype Class: char Default: 'unknown'
            %   Description: This is the type of image the FITS file
            %   contains, e.g. bias, dark, flat.
            %
            %   Property: forceexistence Class: bool Default: true
            %   Description: This parameter controls whether the added
            %   files will be checked for existence. If marked as true, one
            %   failure will terminate the process.
            
            % If the constructor is called with no input arguments just
            % return one instance of a FITS object. This function will
            % generate a list of FITS objects by calling this contructor
            % recursively.
            if ~nargin, return; end
            
            % Establish the default property-value pairs. See the function
            % help for more information on what these values control.
            PropVal.imagetype = 'unknown';
            PropVal.forceexistence = true;
            
            % If more than one argument was specified property value pairs were given.
            % Overwrite the default pairs. by calling the MPROPVAL
            % function.
            if nargin > 1, PropVal = mpropval(PropVal,varargin); end
            
            % A filelist containing the files needs to be built. The FILE
            % constructor will build a list of FILE objects. If existence
            % is forced for the FITS files pass this along. The filelist is
            % also forced to not be empty.
            if PropVal.forceexistence
                File = FILE(rawfiles,'allowdirectories',false,'forcenonempty',true,'forceexistence',true);
            else
                File = FILE(rawfiles,'allowdirectories',false,'forcenonempty',true);
            end
            
            % Create FITS objects. This initializes the array and will
            % greatly speed up adding files. Note that these are not the
            % same objects that will be returned but are simply taking up
            % the space for now. The File array is guarenteed to be of at
            % least length one.
            Fits(1:length(File)) = FITS;
            
            % Begin to loop over all files in the filelist.
            for iFile=1:length(File)
                
                % Build the FITS object. Even though the array is already filled with FITS objects they must individually be constructed because they are the
                % handle class. See the handle class for more information.
                % Attach the FILE object to the FITS object.
                Fits(iFile) = FITS;
                Fits(iFile).FileObject = File(iFile);
                Fits(iFile).ImageType = PropVal.imagetype;
                
            end
            
        end
    end
    
    methods
        function signalImage = get_signal_image(obj)
            signalImage = obj.SkyRemovedPrimaryImage;
        end
        function noiseImage = get_noise_image(obj)
            noiseImage = obj.NoisePrimaryImage;
        end
        function signalImage = getSignalImage(obj)
            signalImage = obj.SkyRemovedPrimaryImage;
        end
        function noiseImage = getNoiseImage(obj)
            noiseImage = obj.NoisePrimaryImage;
        end
        function calibratedImage = getCalibratedImage(obj)
            calibratedImage = obj.CalibratedPrimaryImage;
        end        
        function rawImage = getRawImage(obj)
            rawImage = obj.PrimaryImage;
        end         
    end
    methods
        % The following methods retrieve property values using the
        % dependent property idea.
        function primaryheader = get.PrimaryHeader(obj)
            %GET.PRIMARYHEADER retreives the primary header.
            
            % Check if the primary header is already in storage. If so just
            % return that information.
            if ~isempty(obj.S_PrimaryHeader), primaryheader = obj.S_PrimaryHeader; return; end
            
            % The primary header keyvalcom array has not yet been
            % generated. First retrieve the raw header array.
            rawprimaryheader = obj.RawPrimaryHeader;
            
            % Find the entries which contain a equals sign.
            liEntries = (rawprimaryheader(:,9) == '=');
            
            % This extracts the keywords, values, and comments from the rawheader.
            primaryheader = [strtrim(mcellstr(rawprimaryheader(liEntries,1:8))),strtrim(regexprep(strtrim(regexprep(mcellstr(rawprimaryheader(liEntries,11:80)),'\</.*','')),'^''|''$',''))];
            
        end
        
        function fullfilename = get.FullFileName(obj)
            
            fullfilename = obj.FileObject.FullName;
            
        end
        function shortfilename = get.ShortFileName(obj)                        
            shortfilename = obj.FileObject.Name;           
        end
        
        function rawprimaryheader = get.RawPrimaryHeader(obj)
            %GET.RAWPRIMARYHEADER retrieves the raw primary header in an
            %ASCII block.
            %   GET.RAWPRIMARYHEADER is called when the property
            %   "RawPrimaryHeader" is referenced. The output of this
            %   function is what is returned when the property is
            %   referenced.            
            
            % Check if the raw primary header is already in storage. If so,
            % just return that information. This saves us from reading the
            % header eveytime this function is called.
            if ~isempty(obj.S_RawPrimaryHeader), rawprimaryheader = obj.S_RawPrimaryHeader; return; end
            
            % The storage place was empty. The raw header needs to be read
            % in. The configuration will allow us to control whether or not
            % forbidden ASCII charecters are allowed in the header, and
            % control a sanity check to make sure we on't end up reading in
            % the whole file.
            MaestroConfiguration = mconfig;
            
            % Open up the file and record the file ID. This is a method of
            % the FITS class.
            fid = open(obj);
            
            % Begin loop over header blocks in the file. If the maximum
            % number of blocks is reached an error will be thrown.
            for iBlock = 1:MaestroConfiguration.FITS_HEADER_MAX_BLOCKS
                
                % Seek to the proper bit in the file and read in the header block. We
                % check to see if the fseek was sucessful. If not the end of the file
                % has been reached. Close the file and throw the error.
                if fseek(fid,(iBlock-1)*2880,'bof'),
                    close(obj); error('MAESTRO:FITS:RawPrimaryHeader:EOF1',['With file "',obj.ShortFileName,'". The EOF was reached before the END keyword was found. This is either not a FITS file or is corrupt.']);
                end
                
                % Read in the next block of the header. Enclose this is a
                % try catch loop in case there is an error. If there was an
                % error close the file and throw the error.
                try
                    rawprimaryheader(1+36*(iBlock-1):36*iBlock,1:80) = fscanf(fid,'%36c',[80,1])';
                catch ME
                    close(obj); error('MAESTRO:FITS:RawPrimaryHeader:EOF2',['With file "',obj.ShortFileName,'". The EOF was reached before the END keyword was found. This is either not a FITS file or is corrupt.']);
                end
                
                % Determine whether or not a charecter check is being performed.
                %if MaestroConfiguration.DO_FITS_CHARECTER_CHECK
                    
                    % Convert the block into ascii integers. The INT8
                    % function converts the char array into a matrix.
                %    asciiBlock = int8(rawprimaryheader(1+36*(iBlock-1):36*iBlock,1:80));
                    
                    % Check if there are forbidden charecters. These ASCII
                    % charecter numbers lie outside of the FITS standard.
                    % If any lie outside of this range close the file and
                    % throw an error.
                %    if ~all(asciiBlock(:) >= 32) || ~all(asciiBlock(:) <= 126)
                        %close(obj); error('MAESTRO:FITS:RawPrimaryHeader:badASCII',['With file "',obj.ShortFileName,'". This FITS file appears corrupt as forbidden bytes were found in the primary header.']);
                %    end
                    
                %end
                
                % Check if we've reached the end keyword, and if so break the loop. The
                % first part of the conditional statement is to check if the end
                % keyword lies in the first three columns, the second is to ensure that
                % the rest of the column is whitespace.
                if any(all(isspace(rawprimaryheader(1+36*(iBlock-1)-1+find(rawprimaryheader(1+36*(iBlock-1):36*iBlock,1)=='E'&rawprimaryheader(1+36*(iBlock-1):36*iBlock,2)=='N'&rawprimaryheader(1+36*(iBlock-1):36*iBlock,3)=='D'),4:80))')); break; end
                
                % Check if we've reached the maximum number of iterations. If so throw
                % an error.
                if iBlock == MaestroConfiguration.FITS_HEADER_MAX_BLOCKS
                    close(obj); error('MAESTRO:FITS:RawPrimaryHeader:maxBlocksReached',['This FITS file appears corrupt as the END keyword was not found within the allocated ',num2str(MaestroConfiguration.FITS_HEADER_MAX_BLOCKS),' header blocks. This file may be corrupt or not a FITS file. If the header is longer than ',num2str(36*MaestroConfiguration.FITS_HEADER_MAX_BLOCKS),' increase the maximum number of header blocks allowed in the configuration option "FITS_HEADER_MAX_BLOCKS"']);
                end
            end
          
            % The header has been read in. Close the file.
            close(obj);
            
        end
        function juliandate = get.JulianDate(obj)
            %TRANSLATEPRIMARYHEADER extracts information about the current FITS file.
            %   TRANSLATEPRIMARYHEADER(OBJ) will extract the date, exposure time, and dark time from the list of specified objects.
            %
            %   See also xxxx
            %
            %   Copyright (C) 2009-2010 James Dalessio
            % Obtain the locale.
            LOCALE = mconfig;
            Config = LOCALE;
            
            
            % Obtain the shutter state.
            switch Config.FITS_HEADER_SHUTTER_STATE
                case {'open','Open','OPEN'}
                    shutterMod = .5;
                case {'close','Close','CLOSE','closed','Closed','CLOSED'}
                    shutterMod = -.5;
                case {'mid','Mid','MID','middle','midpoint'}
                    shutterMod = 0;
                otherwise
                    error('MAESTRO:FITSOBJECT:translateprimaryheader:badShutterState',['Error extracting vital information from FITS header. The value specified in the locale option SHUTTER_STATE "',LOCALE.SHUTTER_STATE,'" is not a known value.']);
            end                   
           
           if ischar(Config.FITS_HEADER_DATE_KEYWORD), Config.FITS_HEADER_DATE_KEYWORD = {Config.FITS_HEADER_DATE_KEYWORD}; end
           if ischar(Config.FITS_HEADER_DATE_REGEXP), Config.FITS_HEADER_DATE_REGEXP = {Config.FITS_HEADER_DATE_REGEXP}; end
           if ischar(Config.FITS_HEADER_DATE_FORMAT), Config.FITS_HEADER_DATE_FORMAT = {Config.FITS_HEADER_DATE_FORMAT}; end
                       
           if ischar(Config.FITS_HEADER_TIME_KEYWORD), Config.FITS_HEADER_TIME_KEYWORD = {Config.FITS_HEADER_TIME_KEYWORD}; end
           if ischar(Config.FITS_HEADER_TIME_REGEXP), Config.FITS_HEADER_TIME_REGEXP = {Config.FITS_HEADER_TIME_REGEXP}; end
           if ischar(Config.FITS_HEADER_TIME_FORMAT), Config.FITS_HEADER_TIME_FORMAT = {Config.FITS_HEADER_TIME_FORMAT}; end         
            
           if ischar(Config.FITS_HEADER_EXPTIME_KEYWORD), Config.FITS_HEADER_EXPTIME_KEYWORD = {Config.FITS_HEADER_EXPTIME_KEYWORD}; end
           if ischar(Config.FITS_HEADER_EXPTIME_REGEXP), Config.FITS_HEADER_EXPTIME_REGEXP = {Config.FITS_HEADER_EXPTIME_REGEXP}; end
           if ischar(Config.FITS_HEADER_EXPTIME_FORMAT), Config.FITS_HEADER_EXPTIME_FORMAT = {Config.FITS_HEADER_EXPTIME_FORMAT}; end
            
           if ischar(Config.FITS_HEADER_DARKTIME_KEYWORD), Config.FITS_HEADER_DARKTIME_KEYWORD = {Config.FITS_HEADER_DARKTIME_KEYWORD}; end
           if ischar(Config.FITS_HEADER_DARKTIME_REGEXP), Config.FITS_HEADER_DARKTIME_REGEXP = {Config.FITS_HEADER_DARKTIME_REGEXP}; end
           if ischar(Config.FITS_HEADER_DARKTIME_FORMAT), Config.FITS_HEADER_DARKTIME_FORMAT = {Config.FITS_HEADER_DARKTIME_FORMAT}; end
           

           
           successMarker = false;
           for dateKeyword = Config.FITS_HEADER_DATE_KEYWORD
               for dateRegExp = Config.FITS_HEADER_DATE_REGEXP
                   try
                       
                       justTheDateString = obj.getheaderval(obj.PrimaryHeader,dateKeyword{1},dateRegExp{1});   
                       successMarker = true; break;                       
                   catch ME
                   end                                          
               end
               if successMarker == true; break; end
           end
           if successMarker == false; error('MAESTRO:FITS:badDate','Error extracting date from fits header.'); end    
           
           successMarker = false;
           for timeKeyword = Config.FITS_HEADER_TIME_KEYWORD
               for timeRegExp = Config.FITS_HEADER_TIME_REGEXP
                   try
                       justTheTimeString = obj.getheaderval(obj.PrimaryHeader,timeKeyword{1},timeRegExp{1});        
                       successMarker = true; break;                       
                   catch ME
                   end                                          
               end
               if successMarker == true; break; end
           end
           if successMarker == false; error('MAESTRO:FITS:badTime','Error extracting time from fits header.'); end    
           
           successMarker = false;
           for dateFormat = Config.FITS_HEADER_DATE_FORMAT
               for timeFormat = Config.FITS_HEADER_TIME_FORMAT
                   
                   try
                       rawJD = datenum([justTheDateString,' ',justTheTimeString],[dateFormat{1},' ',timeFormat{1}]) + 1721058.5;
                       successMarker = true; break;
                   catch ME
                   end                   
               end               
               if successMarker == true; break; end
           end
           if successMarker == false; error('MAESTRO:FITS:badDateTime','Error converting date from fits header.'); end    

           
            juliandate = rawJD + obj.ExposureTime*shutterMod/86400;
           
            
            % Add the time to the date.
           % juliandate = datenum([obj.getheaderval(obj.PrimaryHeader,LOCALE.DATE_KEYWORD,LOCALE.DATE_REGEXP),' ',obj.getheaderval(obj.PrimaryHeader,LOCALE.TIME_KEYWORD,LOCALE.TIME_REGEXP)],[LOCALE.DATE_FORMAT,' ',LOCALE.TIME_FORMAT])+obj.ExposureTime*shutterMod/86400+1721058.5;
	
            
        end
        function exposuretime = get.ExposureTime(obj)
            Config = mconfig;
                         
           for exptimeKeyword = Config.FITS_HEADER_EXPTIME_KEYWORD
               for exptimeRegExp = Config.FITS_HEADER_EXPTIME_REGEXP
                   for exptimeFormat = Config.FITS_HEADER_EXPTIME_FORMAT                   
                       try                       
                           justTheExpTimeString = obj.getheaderval(obj.PrimaryHeader,exptimeKeyword{1},exptimeRegExp{1});  
                           exposuretime = datenum(['0000/01/00 ',justTheExpTimeString],['yyyy/mm/dd ',exptimeFormat{1}])*86400;
                           return
                       catch ME                   
                       end        
                   end
               end
           end           
           error('MAESTRO:FITS:badExpTime','Error extracting exptime from fits header.');
           
            %Convert exposure time using the format.
           % exposuretime = datenum(['0000/01/00 ',obj.getheaderval(obj.PrimaryHeader,LOCALE.EXPTIME_KEYWORD,LOCALE.EXPTIME_REGEXP)],['yyyy/mm/dd ',LOCALE.EXPTIME_FORMAT])*86400;
            
            
        end
        function darktime = get.DarkTime(obj)
             Config = mconfig;
                         
           for darktimeKeyword = Config.FITS_HEADER_DARKTIME_KEYWORD
               for darktimeRegExp = Config.FITS_HEADER_DARKTIME_REGEXP
                   for darktimeFormat = Config.FITS_HEADER_DARKTIME_FORMAT                   
                       try                       
                           justTheDarkTimeString = obj.getheaderval(obj.PrimaryHeader,darktimeKeyword{1},darktimeRegExp{1});   
                           darktime = datenum(['0000/01/00 ',justTheDarkTimeString],['yyyy/mm/dd ',darktimeFormat{1}])*86400;
                           return
                       catch ME                   
                       end        
                   end
               end
           end           
           error('MAESTRO:FITS:badExpTime','Error extracting exptime from fits header.');
           
            %Convert exposure time using the format.
           % exposuretime = datenum(['0000/01/00 ',obj.getheaderval(obj.PrimaryHeader,LOCALE.EXPTIME_KEYWORD,LOCALE.EXPTIME_REGEXP)],['yyyy/mm/dd ',LOCALE.EXPTIME_FORMAT])*86400;
            
            
            
            
            %LOCALE = mconfig;
            %if LOCALE.USE_DARKTIME, darktime = datenum(['0000/01/00 ',obj.getheaderval(primaryHeader,LOCALE.DARKTIME_KEYWORD,LOCALE.DARKTIME_REGEXP)],['yyyy/mm/dd ',LOCALE.DARKTIME_FORMAT])*86400; else darktime = obj.ExposureTime; end
            
        end
        function rawprimaryimage = get.RawPrimaryImage(obj)
            if isempty(obj.S_RawPrimaryImage), obj.S_RawPrimaryImage = fitsread(obj.FileObject.FullName); end
            rawprimaryimage = obj.S_RawPrimaryImage;
        end
        function primaryimage = get.PrimaryImage(obj)
            if isempty(obj.S_PrimaryImage)
                % GEt the locale.
                LOCALE = mconfig;
                  % Apply trim and overscan.
                rawImage = obj.RawPrimaryImage;
                osValues = obj.OverscanMean;
                
                if LOCALE.APPLY_OVERSCAN
                    for iSection=1:length(osValues)
                        ind = (iSection-1)*4 + 1;
                        ar = LOCALE.OS_APPLY_REGION(ind:ind+3);
                        rawImage(ar(3):ar(4),ar(1):ar(2)) = rawImage(ar(3):ar(4),ar(1):ar(2)) - osValues(iSection);                                                                                                                                               
                        
                    end                                                                                                    
                end
                
              
                
                if LOCALE.TRIM_IMAGE
                    rawImage = mimjoin(mimsplit(rawImage,LOCALE.TRIM_CUT_REGION),LOCALE.TRIM_PASTE_REGION);
                end
              
                
                
                
                
                obj.S_PrimaryImage = rawImage;
                
            end
            primaryimage = obj.S_PrimaryImage;
            
        end
        function primaryimagemedian = get.PrimaryImageMedian(obj)
            if isempty(obj.S_PrimaryImageMedian)
                obj.S_PrimaryImageMedian = median(obj.PrimaryImage(:));
            end
            primaryimagemedian = obj.S_PrimaryImageMedian;
        end
        function primaryimagemean = get.PrimaryImageMean(obj)
            if isempty(obj.S_PrimaryImageMean)
                obj.S_PrimaryImageMean = mean(obj.PrimaryImage(:));
            end
            primaryimagemean = obj.S_PrimaryImageMean;
            
        end
        function primaryimagestd = get.PrimaryImageSTD(obj)
            if isempty(obj.S_PrimaryImageSTD)
                obj.S_PrimaryImageSTD= std(obj.PrimaryImage(:));
            end
            primaryimagestd = obj.S_PrimaryImageSTD;
        end
        function overscanmean = get.OverscanMean(obj)
            LOCALE = mconfig;
            if isempty(obj.S_OverscanMean)
                if LOCALE.APPLY_OVERSCAN
                    
                    
                    trimmedImage = mimsplit(obj.RawPrimaryImage,LOCALE.OS_SOURCE_REGION);
                    
                    for iSection = 1:length(trimmedImage)
                        obj.S_OverscanMean(iSection) = mean(trimmedImage{iSection}(:));
                        
                    end
                    
                    
                else
                    obj.S_OverscanMean = 0;
                end
            end
            overscanmean = obj.S_OverscanMean;
            
        end
        function calibratedprimaryimage = get.CalibratedPrimaryImage(obj)
            if isempty(obj.S_CalibratedPrimaryImage)
                obj.S_CalibratedPrimaryImage = obj.PrimaryImage;     
                Calibration = mcal;                               
                switch obj.ImageType
                    case 'FLAT'
                        obj.S_CalibratedPrimaryImage = (obj.S_CalibratedPrimaryImage-Calibration.MasterBias-Calibration.MasterDark*obj.DarkTime);                                                            
                    case 'DARK'                                                
                       obj.S_CalibratedPrimaryImage = (obj.S_CalibratedPrimaryImage-Calibration.MasterBias);                                                           
                    case 'OBJECT'                                                   
                        obj.S_CalibratedPrimaryImage = (obj.S_CalibratedPrimaryImage-Calibration.MasterBias-Calibration.MasterDark*obj.DarkTime)./Calibration.MasterFlat;                                                            
                end
                
            end
            calibratedprimaryimage = obj.S_CalibratedPrimaryImage;
            
        end
        function noiseprimaryimage = get.NoisePrimaryImage(obj)
            if isempty(obj.S_NoisePrimaryImage)
                LOCALE = mconfig;
                C = mcal;
                readnoise = mreadnoise;
                gain = mgain;
                if LOCALE.TRIM_IMAGE
                    readNoiseImage = mimsplit(ones(size(obj.PrimaryImage)),LOCALE.TRIM_PASTE_REGION);
                    gainImage = mimsplit(ones(size(obj.PrimaryImage)),LOCALE.TRIM_PASTE_REGION);
                    for iRegion = 1:length(readNoiseImage)
                        readNoiseImage{iRegion} = readNoiseImage{iRegion}*readnoise(iRegion);
                        gainImage{iRegion} = gainImage{iRegion}*gain(iRegion);
                    end
                    readNoiseImage = mimjoin(readNoiseImage,LOCALE.TRIM_PASTE_REGION);
                    gainImage = mimjoin(gainImage,LOCALE.TRIM_PASTE_REGION);
                else
                    readNoiseImage = readnoise*ones(size(obj.PrimaryImage));
                    gainImage = gain*ones(size(obj.PrimaryImage));
                end
                
                
                % SIG = SKYREMOVED
                % NOISE^2 = RDN^2 + (DARK+CAL)*G
                calImage = obj.CalibratedPrimaryImage;
                calImage(calImage+C.MasterDark<0) = 0;
               
                obj.S_NoisePrimaryImage = (readNoiseImage.^2+(C.MasterDark+calImage)./gainImage).^.5;
                
                
            end
            noiseprimaryimage = obj.S_NoisePrimaryImage;
        end
        function skyremovedprimaryimage = get.SkyRemovedPrimaryImage(obj)
            if isempty(obj.S_SkyRemovedPrimaryImage)
                
                
                
                LOCALE = mconfig;
                
                % Turn warnings off. We will get a rank difficient warning if the sky is flat and we remove more than one section.
                warning off all
                
                % Extract the number of sky sections
                LOCALE.NUMBER_SKY_SECTIONS;
                
                % Extract the maximum number of sky pixels
                pixelsPerSkySection = LOCALE.SKY_PIXELS;
                numberSkySections = LOCALE.NUMBER_SKY_SECTIONS;
                
                % Calculate the number of sky sections on each axis.
                skySectionsPerAxis = numberSkySections^(1/2);
                
                signalImage = obj.CalibratedPrimaryImage;
                
                % Extract image size.
                yImageSize = size(signalImage,1);
                xImageSize = size(signalImage,2);
                
                % Extract the x and y grid
                [xGrid,yGrid] = meshgrid(1:xImageSize,1:yImageSize);
                
                
                % Obtain the sky interval
                xSkyInterval = floor(xImageSize/skySectionsPerAxis);
                ySkyInterval = floor(yImageSize/skySectionsPerAxis);
                skyCenters = zeros(skySectionsPerAxis,2);
                
                for iSkyRange=1:skySectionsPerAxis
                    skyCenters(iSkyRange,:) = round([mean([1+(iSkyRange-1)*xSkyInterval,1+(iSkyRange)*xSkyInterval-1]),mean([1+(iSkyRange-1)*ySkyInterval,1+(iSkyRange)*ySkyInterval-1])]);
                end
                
                skyValues = zeros(skySectionsPerAxis);
                skyXPositions = zeros(skySectionsPerAxis);
                skyYPositions = zeros(skySectionsPerAxis);
                
                % Generate random indicies.
                xRandomIndicies = floor(rand(round(pixelsPerSkySection^(1/2)),1)*(xSkyInterval-2)+1)';
                yRandomIndicies = floor(rand(round(pixelsPerSkySection^(1/2)),1)*(ySkyInterval-2)+1)';
                
                
                xHalfRange = floor(xSkyInterval/2)-1;
                yHalfRange = floor(ySkyInterval/2)-1;
                
                for iSkyRange=1:skySectionsPerAxis
                    
                    for jSkyRange=1:skySectionsPerAxis
                        
                        partialImageSection = signalImage(skyCenters(jSkyRange,2)-yHalfRange:skyCenters(jSkyRange,2)+yHalfRange,skyCenters(iSkyRange,1)-xHalfRange:skyCenters(iSkyRange,1)+xHalfRange);
                        
                        
                        includedPixels = partialImageSection(yRandomIndicies,xRandomIndicies);
                        
                        
                        
                        skyValues(iSkyRange,jSkyRange) = nanmedian(includedPixels(:));
                        
                        skyXPositions(iSkyRange,jSkyRange) = skyCenters(jSkyRange,2);
                        skyYPositions(iSkyRange,jSkyRange) = skyCenters(jSkyRange,1);
                        
                    end
                    
                end
                
                
                par = [ones(skySectionsPerAxis^2,1),skyXPositions(:)-mean(skyXPositions(:)),skyYPositions(:)-mean(skyYPositions(:))]\skyValues(:);
                
                obj.S_SkyRemovedPrimaryImage = signalImage - (par(1)+par(2)*xGrid+par(3)*yGrid);
                
                
                warning on all
                
                
                
                
                
            end
            skyremovedprimaryimage = obj.S_SkyRemovedPrimaryImage;
        end
        function stars = get.LocatedStars(obj)
           % if isempty(obj.S_LocatedStars)
                %% Extract Relavant Configuration
                % See the default reduction style configuration for what these parameters represent.
                
                LOCALE = mconfig;
                
                noiseThreshold = LOCALE.STAR_FINDING_NOISE_THRESHOLD;
                maxPercentagePossibleStars = LOCALE.STAR_FINDING_MAX_PERCENT_POSSIBLE_STARS;
                sigmaEstimated = LOCALE.STAR_FINDING_SIGMA_ESTIMATED;
                searchBoxSize = ceil(LOCALE.STAR_FINDING_SEARCH_BOX_SIZE*sigmaEstimated);
                maxLinear = LOCALE.MAX_LINEAR;
                crCutoff = LOCALE.STAR_FINDING_COSMIC_RAY_CUTOFF;
                galaxyCutoff = LOCALE.STAR_FINDING_GALAXY_CUTOFF;
                fitInitialLambda = LOCALE.STAR_CENTERING_PRELIMINARY_FIT_LAMBDA;
                fitTolerance = LOCALE.STAR_CENTERING_PRELIMINARY_FIT_TOLERANCE;
                fitIterations = LOCALE.STAR_CENTERING_PRELIMINARY_FIT_ITERATIONS;
                lambdaMultiplier = LOCALE.STAR_CENTERING_PRELIMINARY_FIT_LAMBDA_MULTIPLIER;
                minConvergence = LOCALE.STAR_CENTERING_PRELIMINARY_FIT_MIN_CONVERGENCE;
                
                
                % Extract the sky removed image.
                skyRemovedImage = obj.SkyRemovedPrimaryImage;
                
                % Extract the noise image.
                noiseImage = obj.NoisePrimaryImage;
                
                % Extract the x and y image sizes.
                xImageSize = size(skyRemovedImage,2);
                yImageSize = size(skyRemovedImage,1);
                
                % Create the x and y grids.
                [xGrid,yGrid] = meshgrid(1:xImageSize,1:yImageSize);
                
                % Obtain pixels which are above the noise threshold.
                aboveThresholdIndicies = skyRemovedImage > noiseImage*noiseThreshold;
                
                % Obtain a list of x and y values above this threshold.
                xValues = xGrid(aboveThresholdIndicies);
                yValues = yGrid(aboveThresholdIndicies);
                zValues = skyRemovedImage(aboveThresholdIndicies);
                sValues = zeros(length(xValues),1);
                
                % Obtain indicies for stars too close to the edge of the image.
                badIndicies = (xValues<=searchBoxSize+1 | xValues >= xImageSize-searchBoxSize-1 | yValues<=searchBoxSize+1 | yValues >= yImageSize-searchBoxSize-1);
                
                % Obtain indicies for stars with too large of an amplitude.
                badIndicies = badIndicies | zValues > maxLinear;
                
                % Remove all values near the edge of the image.
                xValues(badIndicies) = [];
                yValues(badIndicies) = [];
                zValues(badIndicies) = [];
                sValues(badIndicies) = [];
                
                % Sort the values by amplitude.
                [junk,sortOrder] = sort(zValues,'descend'); %#ok<ASGLU>
                
                % Check we have not exceeded the max allowed possible stars.
                if(length(xValues)/(xImageSize*yImageSize) > maxPercentagePossibleStars)
                    
                    % Calculate the desired length.
                    desiredLength = round(maxPercentagePossibleStars*(xImageSize*yImageSize));
                    
                    % Rewrite the sort order.
                    sortOrder = sortOrder(1:desiredLength);
                    
                end
                
                % Rewrite the values.
                xValues = xValues(sortOrder);
                yValues = yValues(sortOrder);
                zValues = zValues(sortOrder);
                sValues = sValues(sortOrder);
                dxValues = zeros(size(zValues));
                dyValues = zeros(size(zValues));
                dzValues = zeros(size(zValues));
                dsValues = zeros(size(zValues));
                
                % Create an index to record the stars.
                goodStarIndex = false(length(xValues),1);
                
                % Initialize number of stars found.
                numStarsFound = 0;
                
            
                % Start loop over all possible stars.
                for iStar = 1:length(xValues)
                   
                    try
                    
                    % Obtain a little image around that pixel.
                    partialImage = skyRemovedImage(yValues(iStar)-searchBoxSize:yValues(iStar)+searchBoxSize,xValues(iStar)-searchBoxSize:xValues(iStar)+searchBoxSize);
                    % Check if any pixels in the box are larger than the current pixel.
                    if length(nonzeros(partialImage(:) >= partialImage(searchBoxSize+1,searchBoxSize+1))) > 1, continue, end
                    
                    % We are fitting a gaussian of the functional form f=A*exp(-(x-x0)^2/2/s^2-(y-y0)^2/2/s^2)
                    
                    % Record an estimate for fitting parameters.
                    A = zValues(iStar);
                    X0 = xValues(iStar);
                    Y0 = yValues(iStar);
                    S = sigmaEstimated;
                    
                    % Rip a piece of the grid and image for evaluation.
                    X = xGrid(Y0-searchBoxSize:Y0+searchBoxSize,X0-searchBoxSize:X0+searchBoxSize);
                    Y = yGrid(Y0-searchBoxSize:Y0+searchBoxSize,X0-searchBoxSize:X0+searchBoxSize);
                    Z = skyRemovedImage(Y0-searchBoxSize:Y0+searchBoxSize,X0-searchBoxSize:X0+searchBoxSize);                                
                    W = real(1./noiseImage(Y0-searchBoxSize:Y0+searchBoxSize,X0-searchBoxSize:X0+searchBoxSize).^2);
                    % Obtain indicies which lie within the appropriate radius.
                    activeIndicies = (X(:)-X0).^2+(Y(:)-Y0).^2 <= searchBoxSize^2;
                    
                    % Obtain grid and image.
                    X = X(activeIndicies);
                    Y = Y(activeIndicies);
                    Z = Z(activeIndicies);
                    W = diag(W(activeIndicies));
                    
                    % Jacobian stored here.
                    J = zeros(length(Z),4);
                    
                    % Nllsqr M-L Lambda
                    L = fitInitialLambda;
                    
                    % Reset the continuation paramter.
                    goOn = true;
                    
                    % Begin loop to iterate solution.
                    for iIteration=1:fitIterations
                        if abs(imag(A))>0, keyboard, end
                        % Obtain the residual.
                        preResidual = sum((A*exp(-(X-X0).^2/2/S^2-(Y-Y0).^2/2/S^2)-Z).^2);
                        
                        % Obtain the jacobian.
                        J(:,1) = 1./exp((X - X0).^2/(2*S^2) + (Y - Y0).^2/(2*S^2));
                        J(:,2) = (A*(2*X - 2*X0))./(2*S^2*exp((X - X0).^2/(2*S^2) + (Y - Y0).^2/(2*S^2)));
                        J(:,3) = (A*(2*Y - 2*Y0))./(2*S^2*exp((X - X0).^2/(2*S^2) + (Y - Y0).^2/(2*S^2)));
                        J(:,4) = (A*((X - X0).^2/S^3 + (Y - Y0).^2/S^3))./exp((X - X0).^2/(2*S^2) + (Y - Y0).^2/(2*S^2));
                        
                        % Perform a fitting iteration.
                        %dPar = (J'*J + L*eye(size(J,2)))^(-1)*J'*(Z-A*exp(-(X-X0).^2/2/S^2-(Y-Y0).^2/2/S^2));
                                               
                        dPar = (J'*W*J + L*eye(size(J,2)))^(-1)*J'*W*(Z-A*exp(-(X-X0).^2/2/S^2-(Y-Y0).^2/2/S^2));
                        %dPar = (J'*W*J + L*eye(size(J,2)))\(J'*W*(Z-A*exp(-(X-X0).^2/2/S^2-(Y-Y0).^2/2/S^2)));

                        
                        % Update the parameters.
                        A = A + dPar(1);
                        X0 = X0 + dPar(2);
                        Y0 = Y0 + dPar(3);
                        S = S + dPar(4);
                        S = abs(S);
                        
                        % Obtain the residual.
                        postResidual = sum((A*exp(-(X-X0).^2/2/S^2-(Y-Y0).^2/2/S^2)-Z).^2);
                        
                        % Check the the star is within the search box.
                        if abs(X0-xValues(iStar)) > searchBoxSize || abs(Y0-yValues(iStar)) > searchBoxSize, goOn = false; break, end
                        
                        % Check that the standard deviation is not too small.
                        if S<crCutoff, goOn = false; break, end
                        
                        % Check that the standard deviation is not too large.
                        if S>galaxyCutoff, goOn = false; break, end
                        
                        % Check if we have gotten to the tolerance desired.
                        if(abs(postResidual/preResidual - 1) < fitTolerance)
                            break;
                        elseif(postResidual/preResidual > minConvergence)
                            L = L/lambdaMultiplier;
                        else
                            L = L*lambdaMultiplier;
                        end
                        
                        
                    end
                    
                    catch ME
                        goOn = false;
                    end
                    
                    
                    % Check if we should continue with this star.
                    if(~goOn)
                        continue
                    end
                    
                    
          
                    
                   M = (J'*W*J)^-1;
                                        
                %    M = (J'*J)^-1*postResidual/(length(X(:))-4);

                    if A<0 || M(2,2)^.5 > searchBoxSize || M(3,3)^.5 > searchBoxSize, continue, end
                    % Mark this star as good.
                    goodStarIndex(iStar) = true;
                    
                    % Copy over x,y, and z values.
                    xValues(iStar) = X0;
                    yValues(iStar) = Y0;
                    zValues(iStar) = A;
                    sValues(iStar) = S;
                    dzValues(iStar) = M(1,1).^.5;
                    dxValues(iStar) = M(2,2).^.5;
                    dyValues(iStar) = M(3,3).^.5;
                    dsValues(iStar) = M(4,4).^.5;
                    
                    % Indicate that we found another star.
                    numStarsFound = numStarsFound+1;
                    
                    if numStarsFound > LOCALE.STAR_FINDING_MAX_STARS, break, end
                end
		

		if length(nonzeros(goodStarIndex))>LOCALE.STAR_FINDING_MAX_STARS
			goodStarIndex = find(goodStarIndex);
			goodStarIndex = goodStarIndex(1:LOCALE.STAR_FINDING_MAX_STARS);
        end
        

                xValues = xValues(goodStarIndex);
                yValues = yValues(goodStarIndex);
                zValues = zValues(goodStarIndex);
                sValues = sValues(goodStarIndex);
                dxValues = dxValues(goodStarIndex);
                dyValues = dyValues(goodStarIndex);
                dzValues = dzValues(goodStarIndex);
                dsValues = dsValues(goodStarIndex);
                nValues = (1:length(xValues))';
                
               
     %    [junk,goodStarIndex2] = sort(zValues,'descend');

      %       xValues = xValues(goodStarIndex2);
       %         yValues = yValues(goodStarIndex2);
       %         zValues = zValues(goodStarIndex2);
        %        sValues = sValues(goodStarIndex2);
         %       dxValues = dxValues(goodStarIndex2);
          %      dyValues = dyValues(goodStarIndex2);
           %     dzValues = dzValues(goodStarIndex2);
            %    dsValues = dsValues(goodStarIndex2);
             %   nValues = (1:length(xValues))';
                
                
             
                obj.S_LocatedStars = [nValues,xValues,yValues,zValues,sValues,dxValues,dyValues,dzValues,dsValues]';
                
                %obj.S_LocatedStars = struct('XX',xValues,'YY',yValues,'ZZ',zValues,'SS',sValues,'DX',dxValues,'DY',dyValues,'DZ',dzValues,'DS',dsValues,'nStars',length(xValues));
                
             %   obj.clear;
           % end
            
           stars = obj.S_LocatedStars;
            
        end
function stars = get.LocatedStarsDev(obj)
           % if isempty(obj.S_LocatedStars)
                %% Extract Relavant Configuration
                % See the default reduction style configuration for what these parameters represent.
                
                LOCALE = mconfig;
                
                noiseThreshold = LOCALE.STAR_FINDING_NOISE_THRESHOLD;
                maxPercentagePossibleStars = LOCALE.STAR_FINDING_MAX_PERCENT_POSSIBLE_STARS;
                sigmaEstimated = LOCALE.STAR_FINDING_SIGMA_ESTIMATED;
                searchBoxSize = ceil(LOCALE.STAR_FINDING_SEARCH_BOX_SIZE*sigmaEstimated);
                maxLinear = LOCALE.MAX_LINEAR;
                crCutoff = LOCALE.STAR_FINDING_COSMIC_RAY_CUTOFF;
                galaxyCutoff = LOCALE.STAR_FINDING_GALAXY_CUTOFF;
                fitInitialLambda = LOCALE.STAR_CENTERING_PRELIMINARY_FIT_LAMBDA;
                fitTolerance = LOCALE.STAR_CENTERING_PRELIMINARY_FIT_TOLERANCE;
                fitIterations = LOCALE.STAR_CENTERING_PRELIMINARY_FIT_ITERATIONS;
                lambdaMultiplier = LOCALE.STAR_CENTERING_PRELIMINARY_FIT_LAMBDA_MULTIPLIER;
                minConvergence = LOCALE.STAR_CENTERING_PRELIMINARY_FIT_MIN_CONVERGENCE;
                
                
                % Extract the sky removed image.
                skyRemovedImage = obj.SkyRemovedPrimaryImage;
                
                % Extract the noise image.
                noiseImage = obj.NoisePrimaryImage;
                
                % Extract the x and y image sizes.
                xImageSize = size(skyRemovedImage,2);
                yImageSize = size(skyRemovedImage,1);
                
                % Create the x and y grids.
                [xGrid,yGrid] = meshgrid(1:xImageSize,1:yImageSize);
                
                % Obtain pixels which are above the noise threshold.
                aboveThresholdIndicies = skyRemovedImage > noiseImage*noiseThreshold;
                
                % Obtain a list of x and y values above this threshold.
                xValues = xGrid(aboveThresholdIndicies);
                yValues = yGrid(aboveThresholdIndicies);
                zValues = skyRemovedImage(aboveThresholdIndicies);
                sValues = zeros(length(xValues),1);
                
                % Obtain indicies for stars too close to the edge of the image.
                badIndicies = (xValues<=searchBoxSize+1 | xValues >= xImageSize-searchBoxSize-1 | yValues<=searchBoxSize+1 | yValues >= yImageSize-searchBoxSize-1);
                
                % Obtain indicies for stars with too large of an amplitude.
                badIndicies = badIndicies | zValues > maxLinear;
                
                % Remove all values near the edge of the image.
                xValues(badIndicies) = [];
                yValues(badIndicies) = [];
                zValues(badIndicies) = [];
                sValues(badIndicies) = [];
                
                % Sort the values by amplitude.
                [junk,sortOrder] = sort(zValues,'descend'); %#ok<ASGLU>
                
                % Check we have not exceeded the max allowed possible stars.
                if(length(xValues)/(xImageSize*yImageSize) > maxPercentagePossibleStars)
                    
                    % Calculate the desired length.
                    desiredLength = round(maxPercentagePossibleStars*(xImageSize*yImageSize));
                    
                    % Rewrite the sort order.
                    sortOrder = sortOrder(1:desiredLength);
                    
                end
                
                % Rewrite the values.
                xValues = xValues(sortOrder);
                yValues = yValues(sortOrder);
                zValues = zValues(sortOrder);
                sValues = sValues(sortOrder);
                dxValues = zeros(size(zValues));
                dyValues = zeros(size(zValues));
                dzValues = zeros(size(zValues));
                dsValues = zeros(size(zValues));
                
                % Create an index to record the stars.
                goodStarIndex = false(length(xValues),1);
                
                % Initialize number of stars found.
                numStarsFound = 0;
                
            
                % Start loop over all possible stars.
                for iStar = 1:length(xValues)
                   
                    try
                    
                    % Obtain a little image around that pixel.
                    partialImage = skyRemovedImage(yValues(iStar)-searchBoxSize:yValues(iStar)+searchBoxSize,xValues(iStar)-searchBoxSize:xValues(iStar)+searchBoxSize);
                    % Check if any pixels in the box are larger than the current pixel.
                    if length(nonzeros(partialImage(:) >= partialImage(searchBoxSize+1,searchBoxSize+1))) > 1, continue, end
                    
                    % We are fitting a gaussian of the functional form f=A*exp(-(x-x0)^2/2/s^2-(y-y0)^2/2/s^2)
                    
                    % Record an estimate for fitting parameters.
                    A = zValues(iStar);
                    X0 = xValues(iStar);
                    Y0 = yValues(iStar);
                    S = sigmaEstimated;
                    
                    % Rip a piece of the grid and image for evaluation.
                    X = xGrid(Y0-searchBoxSize:Y0+searchBoxSize,X0-searchBoxSize:X0+searchBoxSize);
                    Y = yGrid(Y0-searchBoxSize:Y0+searchBoxSize,X0-searchBoxSize:X0+searchBoxSize);
                    Z = skyRemovedImage(Y0-searchBoxSize:Y0+searchBoxSize,X0-searchBoxSize:X0+searchBoxSize);                                
                    W = real(1./noiseImage(Y0-searchBoxSize:Y0+searchBoxSize,X0-searchBoxSize:X0+searchBoxSize).^2);
                    % Obtain indicies which lie within the appropriate radius.
                    activeIndicies = (X(:)-X0).^2+(Y(:)-Y0).^2 <= searchBoxSize^2;
                    
                    % Obtain grid and image.
                    X = X(activeIndicies);
                    Y = Y(activeIndicies);
                    Z = Z(activeIndicies);
                    W = diag(W(activeIndicies));
                    
                    % Jacobian stored here.
                    J = zeros(length(Z),4);
                    
                    % Nllsqr M-L Lambda
                    L = fitInitialLambda;
                    
                    % Reset the continuation paramter.
                    goOn = true;
                    
                    % Begin loop to iterate solution.
                    for iIteration=1:fitIterations
                        if abs(imag(A))>0, keyboard, end
                        % Obtain the residual.
                        preResidual = sum((A*exp(-(X-X0).^2/2/S^2-(Y-Y0).^2/2/S^2)-Z).^2);
                        
                        
                        % Obtain the jacobian.
                        J(:,1) = 1./exp((X - X0).^2/(2*S^2) + (Y - Y0).^2/(2*S^2));
                        J(:,2) = (A*(2*X - 2*X0))./(2*S^2*exp((X - X0).^2/(2*S^2) + (Y - Y0).^2/(2*S^2)));
                        J(:,3) = (A*(2*Y - 2*Y0))./(2*S^2*exp((X - X0).^2/(2*S^2) + (Y - Y0).^2/(2*S^2)));
                        J(:,4) = (A*((X - X0).^2/S^3 + (Y - Y0).^2/S^3))./exp((X - X0).^2/(2*S^2) + (Y - Y0).^2/(2*S^2));
                        
                        % Perform a fitting iteration.
                        %dPar = (J'*J + L*eye(size(J,2)))^(-1)*J'*(Z-A*exp(-(X-X0).^2/2/S^2-(Y-Y0).^2/2/S^2));
                                               
                        dPar = (J'*W*J + L*eye(size(J,2)))^(-1)*J'*W*(Z-A*exp(-(X-X0).^2/2/S^2-(Y-Y0).^2/2/S^2));
                        %dPar = (J'*W*J + L*eye(size(J,2)))\(J'*W*(Z-A*exp(-(X-X0).^2/2/S^2-(Y-Y0).^2/2/S^2)));

                        
                        % Update the parameters.
                        A = A + dPar(1);
                        X0 = X0 + dPar(2);
                        Y0 = Y0 + dPar(3);
                        S = S + dPar(4);
                        S = abs(S);
                        
                        % Obtain the residual.
                        postResidual = sum((A*exp(-(X-X0).^2/2/S^2-(Y-Y0).^2/2/S^2)-Z).^2);
                        
                        % Check the the star is within the search box.
                        if abs(X0-xValues(iStar)) > searchBoxSize || abs(Y0-yValues(iStar)) > searchBoxSize, goOn = false; break, end
                        
                        % Check that the standard deviation is not too small.
                        if S<crCutoff, goOn = false; break, end
                        
                        % Check that the standard deviation is not too large.
                        if S>galaxyCutoff, goOn = false; break, end
                        
                        % Check if we have gotten to the tolerance desired.
                        if(abs(postResidual/preResidual - 1) < fitTolerance)
                            break;
                        elseif(postResidual/preResidual > minConvergence)
                            L = L/lambdaMultiplier;
                        else
                            L = L*lambdaMultiplier;
                        end
                        
                        
                    end
                    
                    catch ME
                        goOn = false;
                    end
                    
                    
                    % Check if we should continue with this star.
                    if(~goOn)
                        continue
                    end
                    
                    
          
                    
                   M = (J'*W*J)^-1;
                                        
                %    M = (J'*J)^-1*postResidual/(length(X(:))-4);

                    if A<0 || M(2,2)^.5 > searchBoxSize || M(3,3)^.5 > searchBoxSize, continue, end
                    % Mark this star as good.
                    goodStarIndex(iStar) = true;
                    
                    % Copy over x,y, and z values.
                    xValues(iStar) = X0;
                    yValues(iStar) = Y0;
                    zValues(iStar) = A;
                    sValues(iStar) = S;
                    dzValues(iStar) = M(1,1).^.5;
                    dxValues(iStar) = M(2,2).^.5;
                    dyValues(iStar) = M(3,3).^.5;
                    dsValues(iStar) = M(4,4).^.5;
                    
                    % Indicate that we found another star.
                    numStarsFound = numStarsFound+1;
                    
                    if numStarsFound > LOCALE.STAR_FINDING_MAX_STARS, break, end
                end
		

		if length(nonzeros(goodStarIndex))>LOCALE.STAR_FINDING_MAX_STARS
			goodStarIndex = find(goodStarIndex);
			goodStarIndex = goodStarIndex(1:LOCALE.STAR_FINDING_MAX_STARS);
        end
        

                xValues = xValues(goodStarIndex);
                yValues = yValues(goodStarIndex);
                zValues = zValues(goodStarIndex);
                sValues = sValues(goodStarIndex);
                dxValues = dxValues(goodStarIndex);
                dyValues = dyValues(goodStarIndex);
                dzValues = dzValues(goodStarIndex);
                dsValues = dsValues(goodStarIndex);
                nValues = (1:length(xValues))';
                                    
                
             
                obj.S_LocatedStarsDev = [nValues,xValues,yValues,zValues,sValues,dxValues,dyValues,dzValues,dsValues]';
                
              
            
           stars = obj.S_LocatedStarsDev;
            
        end
        function imageData = get.RawImage(obj)
            imageData = obj.PrimaryImage;
        end
        function imageData = get.CalibratedImage(obj)
            
            imageData = obj.CalibratedPrimaryImage;
        end
        function stars = findstars(obj)
            stars = obj.LocatedStars;
        end
        function stars = findstarsdev(obj)
            stars = obj.LocatedStarsDev;
            
        end
        
    end
    
    methods (Static = true)
        function value = getheaderval(keyvalcom,keyword,regex)
            %MEXTRACTHEADERVALUE Extract a FITS keyword value.
            %   Given a FITS header imported into the keyvalcom nx3 cell array of
            %   strings format, this will extract the value of the first appearance of
            %   the given keyword.
            %
            %   VALUE = MEXTRACTHEADERVALUE(KEYVALCOM,KEYWORD) specifies the
            %   KEYVALCOM cell array and the targeted KEYWORD.
            %
            %   KEYVALCOM is an nx3 cell array typically generated by reading in a FITS
            %   header. The first column is the keywords, the second is the values, and
            %   the third is the comments.
            %
            %   KEYWORD is a string that should be one of the keyword entries in the
            %   KEYVALCOM section.
            %
            %   VALUE will contain a string corresponding to the entry in the KEYVALCOM
            %   cell array will the keyword KEYWORD.
            %
            %   Example:
            %       KEYVALCOM = importfitsheader('testfile.fits');
            %       KEYWORD = 'DATE-OBS';
            %       VALUE = MEXTRACTHEADERVALUE(KEYVALCOM,KEYWORD)
            %
            %
            
            % Extract the value.
            aiMatches = find(strcmp(keyvalcom(:,1),keyword),1);
            
            % If it is empty, throw an error.
            if isempty(aiMatches), error('MAESTRO:mextractheadervalue:noMatches',['Error extracting fits header value. Could not find any matches for keyword ',keyword,'.']), end
           
            value = keyvalcom{aiMatches,2};
            
            if nargin==3, 
                value = regexp(value,regex,'match');  
                if isempty(value), error('MAESTRO:mextractheadervalue:noRegExpMatches','Error extracting fits header value. No match to regular expression.'); end
                value = value{1}; 
            end
            if isempty(value), error('MAESTRO:mextractheadervalue:noMatches','Error extracting fits header value. No match to regular expression.'); end
            
            
        end
    end
    
end
