function HSPReduction = mhspred(action,value)
%MHSPRED Manages the HSP Reduction Object
%   HSPReduction = MHSPRED will always return the current HSPReduction object. If
%   none has yet been created it will be created.
%
%   MHSPRED(ACTION) will perform the specified action. ACTION is a string.
%
%   MHSPRED(ACTION,VALUE) will perform the specified action given VALUE
%   which controls some aspect of the action to be performed. 
%   
%   Possible Actions:
%       MHSPRED('save',file) would save a reduction to file (a string).
%       MHSPRED('save') wold save a reduction
%       MHSPRED('load',file) would load a reduction from file (a string).
%       MHSPRED('reduce') would execute a reduction.
%       MHSPRED('buildfield') would generate a field and save it to file.
%
%   Here is a list of the possible actions:
%       'save': Save the current reduction to file. If a value is given it
%       is assumed to be the filename. If not a filename is generated.
%       'load': Load a reduction from file into the HSP Reduction Object. A
%       value must be specified and be the name of the file to load.
%
%   See also HSPREDUCTION
%
%   Copyright (C) 2009-2011 James Dalessio

% Declare a persistent variable called "P_HSPReduction". The current
% HSPREDUCTION object will be stored here. Note we add the prefix P_ to
% seperate the HSPReduction variable "HSPReduction" from the persistent variable.
persistent P_HSPReduction

% Check if the persistent variable is initialized. If it is empty than this
% is the first time this function has been called. In this case initialize
% it by calling the class constructor method for HSPREDUCTION.
if isempty(P_HSPReduction), P_HSPReduction = HSPREDUCTION; end

% Assign the value of the persistent variable to the HSPReduction variable. Some
% calls to this function will probably just to access the reduction.
% Remember that this variable is pass by reference so any further actions
% will affect the HSPREDUCTION variable in both places.
HSPReduction = P_HSPReduction;
% Check if no action was specified. In this case the function was called
% just to retrieve the reduction so we will just return will no further
% action.
if nargin == 0, return, end

% Check to see if the action is a string. If it is not a string an
% exception will be thrown.
if ~ischar(action), error('MAESTRO:mhspred:badAction','The first argument to MHSPRED should be a string.'); end

% We have ensured that an action was specified. We will use a switch
% statement to determine which course of action to take.
switch action
    case 'save'
        % The object needs to be saved. If the object was loaded from disk
        % it is possible to call the 'save' action with no corresponding
        % value. This will attempt to use the location the object was
        % loaded from to save it to. First check to see if an action was
        % specified using the NARGIN matlab function.
        if nargin < 2
            % If we have arrived here no filename was specified. We will
            % attempt to save the file to the former location where it was
            % saved. HSPREDUCTION has a property named "FileObject" where a
            % FILE object where always be stored. However, this property
            % can be empty. If it is empty this file has never been written
            % to disk and we do not know what to do with it here so throw
            % an error.            
           if isempty(HSPReduction.FileObject.FullName), mhspred('generatefilename'); end               
            
            % If we have reached this point the file has already been saved
            % to this location before and the FILE object should be proper
            % for this location. Simply save the object.            
            save(HSPReduction.FileObject.FullName,'HSPReduction');
                                    
        else
            
            % We need to ensure that the value that was specified is a non
            % empty charecter array. If it is empty or is not a charecter array
            % throw an exception.
            if ~ischar(value) || isempty(value), error('MAESTRO:mhspred:badFileName','The given filename must be a non empty charecter array.'); end
            
            % Extract the path, name, and extension of the file with the
            % FILEPARTS function.
            [path,name,ext] = fileparts(value);
            
            % Check that the name of the file is not empty. We need to ensure
            % that a name was specified so we dont just tack on a file
            % extension and have a file called ".mpr". If no name was specified
            % throw an error.
            if isempty(name), error('MAESTRO:mhspred:noFileOnlyPath','No filename was given for writing the reduction to disk.'); end
            
            % The extension of the file should be 'hpr'. Check that this is the
            % extension given here. If it is not the proper extension than
            % append this to the file name.
            if ~strcmp(ext,'.hpr'), value = [path,name,ext,'.hpr']; end
            
            % We need to generate a file object by building a filelist.
            % Make sure that directories are not allowed.
            NewFileObject = FILE(value,'allowdirectories',false);
            
            % If there were @ or * symbols in the filename we could end up
            % with multiple file objects or a "filelist". If this is the
            % case throw an exception.
            if length(NewFileObject)>1, error('MAESTRO:mhspred:tooManyFiles','Multiple filenames were given for writing the file to disk.'); end
            
            % The new FILE object checks out. Write this to the
            % HSPReduction and save it to disk by calling this function
            % with no value. The next time through this function will use
            % the new file object to save the data.
            HSPReduction.FileObject = NewFileObject; mhspred('save');
            
        end               
    case 'load'
        % If load was called a filename needs to be specified. Otherwise
        % what in the hell are we going to load?!?. Check that a value was
        % specified and that it is a non empty charecter array.
        if nargin< 2 || ~ischar(value) || isempty(value), error('MAESTRO:hspred:loadBadFileName','The filename specified was improperly formatted.'); end
        
        % Generate a file object with the specified file name. Make sure it
        % exists.
        NewFileObject = FILE(value,'allowdirectories',false,'forceexistence',true);
        
        % If there were @ or * symbols in the filename we could end up
        % with multiple file objects or a "filelist". If this is the
        % case throw an exception.
        if length(NewFileObject)>1, error('MAESTRO:mhspred:tooManyFiles','Multiple filenames were given for writing the file to disk.'); end
        
        %HSPReduction = load(NewFileObject.FullName);
        error('MAESTRO:mhspred:loadNYI','Loading reductons is not yet implemented.')
                     
    case 'reduce'
        
        % The reduction is to be executed. Call the method of HSPReduction
        % that begins the reduction.        
        HSPReduction.reduce;
        
    case 'reducedev'
        HSPReduction.reducedev;
        
    case 'buildfield'
        % A field is to be generated for this reduction.     
       
        mtalk('\n\nBUILDING MASTER FIELD');
        
        %% BUILD A MASTER FIELD
        % No matter the method we are using to reduce the data the building of a
        % master field is neccessary. This will cycle through all images and build
        % a list of "geometries" or star positions that appear of the images.
        % This also determines if the images are rotating or if they suddenly
        % flip.
        HSPReduction.buildmasterfields4;
        
        %% CHOOSE A MASTER FIELD
        % This will select the master field that will be used to aquire the images.
        % There are several ways that a master field will be chosen. See the
        % function for more information.
    case 'labelfield'
        HSPReduction.labelfield2;
    case 'assignfilename'
        HSPReduction.FileObject = FILE(value);
    case 'assignfieldname'
        HSPReduction.MasterFieldArray(1).FieldName = value;
    case 'savefield'
        
        fileName = HSPReduction.MasterFieldArray(1).FieldName;
         starLabels = HSPReduction.MasterFieldArray(1).Labels;
        xPositions = HSPReduction.MasterFieldArray(1).Geometry(2,:)';
        yPositions = HSPReduction.MasterFieldArray(1).Geometry(3,:)';
        zPositions = HSPReduction.MasterFieldArray(1).Geometry(4,:)';
        s = median(HSPReduction.MasterFieldArray.Geometry(5,:));
        
        if length(xPositions) < 1, return, end
        mtalk(['\n Saving generated field as "',fileName,'".']);
       
        
        fid = fopen([muserpath,filesep,'fields',filesep,fileName],'w');
        fprintf(fid,['# Reference File: "',HSPReduction.MasterFieldArray(1).ReferenceFile.Name,'"\n']);
        for iStar = 1:length(starLabels)
            fprintf(fid,[starLabels{iStar},'\t']);
            fprintf(fid,[num2str(xPositions(iStar),'%10.2f'),'\t']);
            fprintf(fid,[num2str(yPositions(iStar),'%10.2f'),'\t']);
            fprintf(fid,[num2str(zPositions(iStar),'%10.2f'),'\t\n']);                        
        end
        
        
        return
        x = xPositions;
        y = yPositions;
        z = zPositions;
                        
        z = (z-min(z));
        z = z/max(z);
        z = z - median(z);
        z = z/mrobuststd(z);       
        z = z/2+1;                     
        
        xr = round((max(x)-min(x)));
        yr = round((max(y)-min(y)));
        
        zdat = zeros(yr,xr);        
        [xdat,ydat] = meshgrid(1:xr,1:yr);
                
        for i=1:length(x)
            zdat = zdat + z(i)*exp(-((x(i)-xdat).^2+(y(i)-ydat).^2)/2/(2*s)^2);            
        end
        zdat(zdat>1) = 1;
        f = figure('Visible','off');
        image(repmat(zdat,[1,1,3]));                
        
        set(gca,'YDir','normal');
      
        %set(gca,'
        x = x-min(x); x = x/max(x);
        y = y-min(y); y = y/max(y);
        
          set(f,'Visible','on');keyboard;
        for i=1:length(x)
            annotation(f,'textbox',[x(i),y(i),0,0],'String',num2str(i),'VerticalAlignment','middle','HorizontalAlignment','center');
        end
        saveas(f,[muserpath,filesep,'fields',filesep,fileName,'.jpg'])
      
       
        
        
        
        
        
        
        
        
    case 'generatefilename'         
        iFITSObject = 1;  
        
        while(1)
            try
                jd = HSPReduction.FITSList(iFITSObject).JulianDate;                
                break
            catch ME
            end                        
            iFITSObject = iFITSObject + 1;
            if iFITSObject > length(HSPReduction.FITSList)
                error('uhoh!')
            end
        end
        
        
        if any(strcmp(HSPReduction.FITSList(1).PrimaryHeader(:,1),'OBSERVAT'))
            obs = HSPReduction.FITSList(iFITSObject).PrimaryHeader{strcmp(HSPReduction.FITSList(iFITSObject).PrimaryHeader(:,1),'OBSERVAT'),2};              
        else
            obs = 'unknown';
        end
        obs(obs == ' ') = [];
        if isempty(obs), obs = 'unknown'; end
        
        fieldname = HSPReduction.MasterFieldArray(1).FieldName;
       
        ds = datestr(jd-1721058.5,'yyyymmdd_HHMMSS');   
            
        %mhspred('assignfilename',[ds,'_',fieldname]);              
        HSPReduction = [ds,'_',fieldname];
        
    case 'dump'
        
        
        mtalk('\n\nDUMPING REDUCTION TO DISK');        

        [path,name] = fileparts(HSPReduction.FileObject.FullName);
        pathName = [path,filesep,name];
        mmkdir(pathName);
        
        
        
        
        
        
        
        
        NW = min(10,size(HSPReduction.ApertureData.Counts,2));
        
        % For each aperture write out date/counts1/sky1/counts2/sky2 etc...
        % This assumes that the counts data is uniform in aperture size.
        % This is only to interface with wqed.
        FITSList = mfits('retrieve','OBJECT');        
        julianDates = [FITSList.JulianDate];                       
        julianDates = (julianDates-min(julianDates));
        outData = zeros(length(julianDates),1+2*NW);            
        outData(:,1) = julianDates;
        
        % Loop over all apertures. 
        pid = mprocessinit('\n Writing out raw photometry files...');
        for iAperture = 1:length(HSPReduction.ApertureData.Sizes)               
            outData(:,2:2:2*NW) = HSPReduction.ApertureData.Counts(:,1:NW,iAperture);
            outData(:,3:2:1+2*NW) = HSPReduction.ApertureData.Sky(:,1:NW);
            
            if(HSPReduction.ApertureData.Sizes(iAperture) < 10)
                fileName = [pathName,filesep,'counts_0',num2str(HSPReduction.ApertureData.Sizes(iAperture))]; 
            else
                fileName = [pathName,filesep,'counts_',num2str(HSPReduction.ApertureData.Sizes(iAperture))]; 
            end
            
            dlmwrite(fileName,outData,'delimiter','\t','precision','%10.10f')
	    mprocessupdate(pid,iAperture/length(HSPReduction.ApertureData.Sizes));
        end
	mprocessfinish(pid,1);

        % Do the calculation for best S/N with single aperture.
        bestApertureSN = 0;
        bestApertureIndex = 1;
        SNMatrix = zeros(length(HSPReduction.ApertureData.Sizes),3);
        SNMatrix(:,1) = HSPReduction.ApertureData.Sizes;        
	pid =	mprocessinit('\n Calculating optimum S/N single aperture of STAR1/STAR2...');
        for iAperture = 1:length(HSPReduction.ApertureData.Sizes)
            signal = HSPReduction.ApertureData.Counts(:,1,iAperture);
            noise = HSPReduction.ApertureData.Noise(:,1,iAperture);  
            totalSignal = sum(signal);
            totalNoise = sum(noise.^2)^(1/2);
            SNMatrix(iAperture,2) = totalSignal/totalNoise;
            SNMatrix(iAperture,3) = median(signal./noise);
            SN = totalSignal/totalNoise;
            if SN > bestApertureSN
                bestApertureSN = SN;
                bestApertureIndex = iAperture;
            end                        
	    mprocessupdate(pid,iAperture/length(HSPReduction.ApertureData.Sizes));
        end
        
        if  HSPReduction.ApertureData.Sizes(bestApertureIndex) < 10
            copyfile([pathName,filesep,'counts_0',num2str(HSPReduction.ApertureData.Sizes(bestApertureIndex))],[pathName,filesep,'counts_SN_optimized_0',num2str(HSPReduction.ApertureData.Sizes(bestApertureIndex))]);
        else
            copyfile([pathName,filesep,'counts_',num2str(HSPReduction.ApertureData.Sizes(bestApertureIndex))],[pathName,filesep,'counts_SN_optimized',num2str(HSPReduction.ApertureData.Sizes(bestApertureIndex))]);
        end
        mprocessfinish(pid,1);
                
       pid = mprocessinit('\n Calculating optimum S/N dynamic aperture of STAR1/STAR2...');
        % Do the calculate for best S/N with varying apertures.
        SNIndicies = zeros(size(HSPReduction.ApertureData.Counts,1),1);
        for iImage = 1:size(HSPReduction.ApertureData.Counts,1)
            [junk,i] = max(squeeze(HSPReduction.ApertureData.Counts(iImage,1,:)./HSPReduction.ApertureData.Noise(iImage,1,:))); %#ok<ASGLU>
            SNIndicies(iImage) = i;                                    
            outData(iImage,2:2:2*NW) = HSPReduction.ApertureData.Counts(iImage,1:NW,i);  
	    mprocessupdate(pid,iImage/size(HSPReduction.ApertureData.Counts,1));                     
        end
        outData(:,3:2:2*NW+1) = HSPReduction.ApertureData.Sky(:,1:NW);
        fileName = [pathName,filesep,'counts_dynamic_apertures'];
        dlmwrite(fileName,outData,'delimiter','\t','precision','%10.10f');
   	mprocessfinish(pid,1);
        
        
        	
        pid = mprocessinit('\n Copying FITS file of first image...');
        copyfile(FITSList(1).FileObject.FullName,[pathName,filesep,'firstimage.fits']);                
        mprocessfinish(pid,1);
        
        
        FITSList = mfits('retrieve','OBJECT');                
        JulianDates = [FITSList.JulianDate];             
        Apertures = HSPReduction.ApertureData.Sizes;       
        Counts = HSPReduction.ApertureData.Counts;
        Noise = HSPReduction.ApertureData.Noise;
        Sky = HSPReduction.ApertureData.Sky;
        
                
        for i=1:length(Apertures)            
           
            dlmwrite([pathName,filesep,'signal_',num2str(Apertures(i),'%03.2f')],[JulianDates',Counts(:,:,i)],'delimiter','\t','precision','%10.10f');                        
            dlmwrite([pathName,filesep,'noise_',num2str(Apertures(i),'%03.2f')],[JulianDates',Noise(:,:,i)],'delimiter','\t','precision','%10.10f');
        end        
        dlmwrite([pathName,filesep,'sky'],[JulianDates',Sky],'delimiter','\t','precision','%10.10f');
        
        
        
        
    case 'assignfield'
        %% ACTION: ASSIGNFIELD
        % Action assignfield records the string specified by the value. It
        % checks that the assigned field exists either from the PWD or in
        % <MAESTRO>/fields/. The PWD is checked first. It also checks that
        % this file is readable and that columns 2 3 and 4 contain numeric
        % values.
        
       
        % Initialize a maestro process. There will be no progress updates
        % because this should be very fast.
        pid = mprocessinit('\n Checking that the specified field exists...');
        
        % Create two file objects. One from the specified value assuming it
        % is relative to the location of the fields and the other relative
        % ot the PWD. 
        FileA = FILE(mrelpath(value,pwd));
        FileB = FILE([muserpath,filesep,'fields',filesep,value]);        
               
        % Check if the file objects are reported to be directories, non
        % existent, or were a wildcard which caught more than one file.
        isFileABad = (length(FileA) ~= 1 || ~FileA.Exists || FileA.IsDir);
        isFileBBad = (length(FileB) ~= 1 || ~FileB.Exists || FileB.IsDir);
        
        % If both files are bad kill the process with an error state and
        % report an error.
        if isFileABad && isFileBBad
            mprocessfinish(pid,false);
            error('MAESTRO:mhspred:noFieldFile',['The specified field file "',value,'" could not be found in "',[muserpath,filesep,'fields',filesep],'" or relative to the present working directory.']);                                                   
        end
        
        % By default, if FileA is ok (the file relative to the PWD) it will
        % be used. Otherwise FileB will be used.
        if isFileABad, File = FileB; else File = FileA; end                                                        

        % Indicate that the process has completed sucessfully and let the
        % user know exactly what field file will be used.
        mprocessfinish(pid,true);             
        mtalk(['\n Field "',File.FullName,'" will be used to label the stars.']);
                
        % Initialize a process to read in the file. Progress will not be
        % used because this should happen rather quickly.
        pid = mprocessinit(['\n Checking data in field file "',File.Name,'" to verify integrity...']);
        
        % Read in the data from the file.
        data = mread(File.FullName);
        
        % Assert that there are at least 4 columns.
        if size(data,2) > 4
            mprocessfinish(pid,false)
            error('MAESTRO:mhspred:badFieldFileColumnNumber',['A field file should have at least four columns but the given file ,"',File.FullName,'", only has ',num2str(size(data,2)),'.']);
        end
        
        % Assert that the data in columns 2,3, and 4 must be numeric. 
        if any(any(isnan(str2double(data(:,2:4)))))
            mprocessfinish(pid,false);
            error('MAESTRO:mhsped:badFieldData',['The second, third, and fourth columns of a field file should have numeric values but at least one entry in field file "',File.FullName,'" could not be converted to a number.']);
        end
        
        % Indicate that the file checked out ok. 
        mprocessfinish(pid,true);        
                        
        % Currently the name of the field file is recorded in a
        % configuration variable. This may change in the future.
        mconfig('STAR_LABELING_FILENAME',File.FullName);                
                                            
    otherwise
        % None of the actions were recognized. This will be considered an
        % error and an exception will be thrown.
        error('MAESTRO:mhspred:unknownAction',['The action sent to MHSPRED, "',action,'" is unknown.']);                
end
