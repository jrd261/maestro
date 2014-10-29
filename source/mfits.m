function FITSList = mfits(action,value1, value2)
%MFITS Manages Aspects of the FITS lists stored in MAESTRO.
%   FITS = MFITS will return the current list of FITS objects.
%
%   See also FITS
%
%   Copyright (C)2009-2011 James Dalessio


persistent P_FITSData
if nargin > 1
value = value1;
end
if isempty(P_FITSData)
    P_FITSData = struct('OBJECT',FITS.empty,'BIAS',FITS.empty,'DARK',FITS.empty,'FLAT',FITS.empty,'OTHER',FITS.empty);        
end


FITSList = P_FITSData.OBJECT;


switch action
    case 'retrieve'
        FITSList = P_FITSData.(upper(value1));
    case 'integritycheck'
        FITSList = P_FITSData.(upper(value1));
        if isempty(FITSList), return, end
        pid = mprocessinit(['\n Checking integrity of ',num2str(length(FITSList)),' ',value1,' FITS files.']);        
        for iFile = 1:length(FITSList)
            try
                FITSList(iFile).PrimaryHeader;
            catch ME
                mprocessfinish(pid,0);
                rethrow(ME);
            end
            mprocessupdate(pid,iFile/length(FITSList));
        end
        mprocessfinish(pid,1);
    case 'keywordcheck'
        FITSList = P_FITSData.(upper(value1));
        if isempty(FITSList), return, end
        pid = mprocessinit(['\n Checking keywords of ',num2str(length(FITSList)),' ',value1,' FITS files.']);
        for iFile = 1:length(FITSList)
            try
                FITSList(iFile).JulianDate;
            catch ME
                mprocessfinish(pid,0);
                rethrow(ME);
            end
            mprocessupdate(pid,iFile/length(FITSList));
        end
        mprocessfinish(pid,1);
    case 'build'
        FITSList = FITS(value2);
        for iFITSList = 1:length(FITSList)
            FITSList(iFITSList).ImageType = value1;
        end
        P_FITSData.(value1) = FITSList;
    case 'set'
        P_FITSData.(value1) = value2;
    case 'add'
         for iFITSList = 1:length(value2)
            value2(iFITSList).ImageType = value1;
        end
        P_FITSData.(value1) = value2;
        
    case 'autobuild'
        % ACTION: AUTOBUILD2
        % Action autobuild2 will construct a set of fits objects
        % automatically. The value can either be a structure with the
        % fields containing cell arrays, or a string or cell array of
        % strings. This is really a helper function for all maestro commands that need to load in FITS files of various types.   
        
        % Load in the maestro configuration.
        Config = mconfig;
        
        % If value is a charecter array convert it to a cell array of
        % strings.
        if ischar(value), value = {value}; end
        
        % Check if the input is a cellarray. If it is assume that these
        % values are specified as files to be automatically built. 
        if iscell(value), value = struct('AUTO_FILES',{value}); end
        
        % Now we must record the default values for all fields of the
        % structure "value".
        if ~isfield(value,'AUTO_FILES'), value.AUTO_FILES = {}; end
        if ~isfield(value,'DATA_PATH'), value.DATA_PATH = {}; end
        if ~isfield(value,'BIAS_FILES'), value.BIAS_FILES = {}; end
        if ~isfield(value,'DARK_FILES'), value.DARK_FILES = {}; end
        if ~isfield(value,'FLAT_FILES'), value.FLAT_FILES = {}; end
        if ~isfield(value,'OBJECT_FILES'), value.OBJECT_FILES = {}; end
                               
        % Obtain the path the files were specified relative to. If the data path
        % wasn't specified assume all files were referenced w/ respect to the
        % present working directory.
        if ~isempty(value.DATA_PATH), value.DATA_PATH{1} = mrelpath(value.DATA_PATH{1},pwd); else value.DATA_PATH{1} = pwd; end
                
        % The first thing to do is to determine whether we are automatically building or not.
        % We will use the variables "doAutobuild" and "doManualBuild" to record
        % whether it appears we are automatically or manually building the FITS
        % lists. 
        doAutoBuild = ~isempty(value.AUTO_FILES);
        doManualBuild =  ~isempty(value.BIAS_FILES) || ~isempty(value.DARK_FILES) || ~isempty(value.FLAT_FILES) || ~isempty(value.OBJECT_FILES);

        % If both were specified we will throw an error. We don't want to mess with
        % defaulting to ignoring something the user specified.
        if doAutoBuild && doManualBuild
            error('MAESTRO:mfits:autoAndManualSpecified','Some files were specified specifically as bias/dark/flat/object files and some were specified to be detected automatically. Please only use one method for specifying files.');
        elseif ~doAutoBuild && ~doManualBuild        
            % If neither was specified we will do automatic detection at
            % the pwd. First lets see if the object, bias, and dark files
            % were given in a list.
            ObjectFiles = FILE(Config.FITS_OBJLIST_NAMES); ObjectFiles(~[ObjectFiles.Exists]) = []; ObjectFiles([ObjectFiles.IsDir]) = [];
            BiasFiles = FILE(Config.FITS_BIASLIST_NAMES); BiasFiles(~[BiasFiles.Exists]) = []; BiasFiles([BiasFiles.IsDir]) = [];
            FlatFiles = FILE(Config.FITS_FLATLIST_NAMES); FlatFiles(~[FlatFiles.Exists]) = []; FlatFiles([FlatFiles.IsDir]) = [];
            DarkFiles = FILE(Config.FITS_DARKLIST_NAMES); DarkFiles(~[DarkFiles.Exists]) = []; DarkFiles([DarkFiles.IsDir]) = [];
            
            % If none of the list files were found we will autobuild
            % looking at all fits files. Call this function again but just
            % give the data path and some wildcard to select all fits
            % values.
            if isempty([ObjectFiles,BiasFiles,FlatFiles,DarkFiles])
                mtalk('\n No bias, dark, flat, or object lists found.');                               
                mfits('autobuild',mrelpath(cellfun(@(x) ['*.',x],Config.FITS_FILE_EXTENSIONS,'UniformOutput',false),value.DATA_PATH{1})); 
                return
            end
                                    
            % Here we need to load the filelists. Create input for
            % autobuild.
            mtalk('\n Using ASCII lists to determine which FITS files to use.');
            if ~isempty(BiasFiles), value.BIAS_FILES = {['@',BiasFiles(1).FullName]}; end
            if ~isempty(DarkFiles), value.DARK_FILES = {['@',DarkFiles(1).FullName]}; end
            if ~isempty(FlatFiles), value.FLAT_FILES = {['@',FlatFiles(1).FullName]}; end
            if ~isempty(ObjectFiles), value.OBJECT_FILES = {['@',ObjectFiles(1).FullName]}; end
            
            % Call autobuild using the file lists.
            mfits('autobuild',value);
                       
        elseif doAutoBuild
            % Auto build was specified with an argument or flag. Autobuild based on
            % these files.
            Fits = FITS(mrelpath(value.AUTO_FILES,value.DATA_PATH{1})); if isempty(Fits), return; end
           
            % Create empty FITS lists for the bias, dark, flat, and object
            % files. Also inititalize a variable to record the number of
            % bias, dark, flat, and object files found.
            biasFITSList(1:length(Fits)) = FITS; nBiasFiles = 0;            
            darkFITSList(1:length(Fits)) = FITS; nDarkFiles = 0;
            flatFITSList(1:length(Fits)) = FITS; nFlatFiles = 0;
            objFITSList(1:length(Fits)) = FITS; nObjectFiles = 0;            
            
            pid = mprocessinit('\n Autodetecting FITS file image types by keyword...');
            for iFile = 1:length(Fits)                
                for iKeyWord = 1:length(Config.FITS_TYPE_AUTODETECT_KEYWORDS)
                    
                    % Attempt to retrieve the value of the keyword
                    try
                        keyVal = Fits(iFile).getheaderval(Fits(iFile).PrimaryHeader,Config.FITS_TYPE_AUTODETECT_KEYWORDS(iKeyWord),'.*');
                    catch ME %#ok<NASGU>    
                        if iKeyWord==length(Config.FITS_TYPE_AUTODETECT_KEYWORDS)
                            nObjectFiles = nObjectFiles + 1;      
                            objFITSList(nObjectFiles) = Fits(iFile);                   
                            break
                        end
                        continue
                    end
                    if cell2mat(regexpi(keyVal,Config.FITS_TYPE_AUTODETECT_BIAS_VALUES))
                        nBiasFiles = nBiasFiles + 1;
                        biasFITSList(nBiasFiles) = Fits(iFile);  
                        break
                    end
                    
                    if cell2mat(regexpi(keyVal,Config.FITS_TYPE_AUTODETECT_DARK_VALUES))
                        nDarkFiles = nDarkFiles + 1;
                        darkFITSList(nDarkFiles) = Fits(iFile); 
                        break
                    end
                    if cell2mat(regexpi(keyVal,Config.FITS_TYPE_AUTODETECT_FLAT_VALUES))
                        nFlatFiles = nFlatFiles + 1;
                        flatFITSList(nFlatFiles) = Fits(iFile); 
                        break
                    end
                    if cell2mat(regexpi(keyVal,Config.FITS_TYPE_AUTODETECT_OTHER_VALUES)), break; end
                       
                    if iKeyWord==length(Config.FITS_TYPE_AUTODETECT_KEYWORDS)
                        nObjectFiles = nObjectFiles + 1;      
                        objFITSList(nObjectFiles) = Fits(iFile);                   
                    end
                    
                
                end
                mprocessupdate(pid,iFile/length(Fits));
            end
            mprocessfinish(pid,true);
                        
            biasFITSList(nBiasFiles+1:length(biasFITSList)) = [];
            darkFITSList(nDarkFiles+1:length(darkFITSList)) = [];
            flatFITSList(nFlatFiles+1:length(flatFITSList)) = [];
            objFITSList(nObjectFiles+1:length(objFITSList)) = [];
            
            mfits('add','BIAS',biasFITSList);
            mfits('add','DARK',darkFITSList);
            mfits('add','FLAT',flatFITSList);
            mfits('add','OBJECT',objFITSList);
                      
        else
            % The files were specified manually. Load them up individually.            
            if ~isempty(value.BIAS_FILES), mfits('build','BIAS',mrelpath(value.BIAS_FILES,value.DATA_PATH{1})); end
            if ~isempty(value.DARK_FILES), mfits('build','DARK',mrelpath(value.DARK_FILES,value.DATA_PATH{1})); end
            if ~isempty(value.FLAT_FILES), mfits('build','FLAT',mrelpath(value.FLAT_FILES,value.DATA_PATH{1})); end
            if ~isempty(value.OBJECT_FILES), mfits('build','OBJECT',mrelpath(value.OBJECT_FILES,value.DATA_PATH{1}));end    
        end
    case {'display_status'}
        BiasList = P_FITSData.BIAS;
        FlatList = P_FITSData.FLAT;
        DarkList = P_FITSData.DARK;
        ObjList = P_FITSData.OBJECT;
       
        mtalk(['\n Bias files: ',num2str(length(BiasList))]);
        mtalk(['\n Dark files: ',num2str(length(DarkList))]);
        mtalk(['\n Flat files: ',num2str(length(FlatList))]); 
        mtalk(['\n Object files: ',num2str(length(ObjList))]);
    case {'size_check'}
        FITSList = P_FITSData.(upper(value1));
        if isempty(FITSList), return, end
        pid = mprocessinit(['\n Checking size of ',num2str(length(FITSList)),' ',value1,' FITS files...']);        
        size1 = FITSList(1).FileObject.FileSize;
        for iFile = 1:length(FITSList)
            
            if FITSList(iFile).FileObject.FileSize ~= size1
                mprocessfinish(pid,false);
                error('MAESTRO:mfits:sizeCheckFail',['Not all of the ',value1,' files are the same size. Please check that these files are not corrupt and are indeed FITS files.']);
            end 
            
            mprocessupdate(pid,iFile/length(FITSList));
        end
        mprocessfinish(pid,1);
        
    case {'object_check'}
        if isempty(P_FITSData.OBJECT), error('MAESTRO:mfits:noObjectFiles','No object/target files were specified. Please specify all files as the first argument or specify object files with the -o/--object-files flag.'); end

        
                        
    case {'autobuildOLD'}
       
        % Generate a list of File objects.
        FileList  = FILE(value1);
        
         
        
        
        if length(FileList)==1 && FileList.IsDir           
            Fits = FITS({'*.fits','*.FIT','*.FITS','*.fit','*.FTS','*.fts'});
            if isempty(Fits), error('No fits files found'); end
            
            biasFITSList(1:length(Fits)) = FITS; b = 1;
            flatFITSList(1:length(Fits)) = FITS; f = 1;
            objFITSList(1:length(Fits)) = FITS; o = 1;
            darkFITSList(1:length(Fits)) = FITS; d = 1;
            
            fields = {'IMAGETYP','OBJECT','TYPE'};
                    
            pid = mprocessinit('\n Autodetecting FITS file types...');
            for i=1:length(Fits)
                for j=1:length(fields)
                    try
                        fv = Fits(i).getheaderval(Fits(i).PrimaryHeader,fields(j),'.*');
                    catch ME
                        if j==length(fields)
                          objFITSList(o) = Fits(i); o = o + 1;    
                        end
                        continue
                    end
                    if cell2mat(regexpi(fv,{'bias','zero'}))
                        biasFITSList(b) = Fits(i); b = b + 1; break;
                    end
                    
                    if cell2mat(regexpi(fv,{'dark','thermal'}))
                        darkFITSList(d) = Fits(i); d = d + 1;break;
                    end
                    if cell2mat(regexpi(fv,{'flat','domeflat','skyflat','sflat','dflat'}))
                        
                        flatFITSList(f) = Fits(i); f = f + 1;break;
                    end
                    if cell2mat(regexpi(fv,{'focus'})), break; end
                       
                    if j==length(fields)
                        objFITSList(o) = Fits(i); o = o + 1;                        
                    end
                    
                             
                end
                mprocessupdate(pid,i/length(Fits));
            end    
            mprocessfinish(pid,1);
            
            biasFITSList(b:length(biasFITSList)) = [];
            darkFITSList(d:length(darkFITSList)) = [];
            flatFITSList(f:length(flatFITSList)) = [];
            objFITSList(o:length(objFITSList)) = [];

            
            mfits('add','BIAS',biasFITSList);
            mfits('add','DARK',darkFITSList);
            mfits('add','FLAT',flatFITSList);
            mfits('add','OBJECT',objFITSList);
            
            
           return 
        end   
        
        if length(FileList) == 1 && FileList.IsDir
            if iscell(value1), value1 = value1{1}; end                            
            FileList = FILE([value1,filesep,'*']);
        end
        
        areDirs = [FileList.IsDir];
        
      %  DirList = FileList(areDirs);
        FileList(areDirs) = [];
        
        areBiasLists = cellfun(@(x) ~isempty(x),regexpi({FileList.Name},'biaslist'));
        areDarkLists = cellfun(@(x) ~isempty(x),regexpi({FileList.Name},'darklist'));
        areFlatLists = cellfun(@(x) ~isempty(x),regexpi({FileList.Name},'flatlist'));
        areObjLists = cellfun(@(x) ~isempty(x),regexpi({FileList.Name},'objlist'));
        
      %  areBiasDirs = cellfun(@(x) isempty(x),regexpi({DirList.Name},'bias'));
      %  areDarkDirs = cellfun(@(x) isempty(x),regexpi({DirList.Name},'dark'));
      %  areFlatDirs = cellfun(@(x) isempty(x),regexpi({DirList.Name},'flat'));
        
        mtalk('\nSEARCHING FOR FILES');
        % This takes care of @listing, note everything must be @listed
        if any(areBiasLists) || any(areDarkLists) || any(areFlatLists) || any(areObjLists)
            if any(areBiasLists)
                mtalk('\n Found bias file list.');
                BiasASCIIListFILE = FileList(areBiasLists);
                mfits('build','BIAS',['@',BiasASCIIListFILE(1).FullName]);
            end            
            if any(areDarkLists)
                mtalk('\n Found dark file list.');
                DarkASCIIListFILE = FileList(areDarkLists);
                mfits('build','DARK',['@',DarkASCIIListFILE(1).FullName]);
            end
            if any(areFlatLists)
                mtalk('\n Found flat file list.');
                FlatASCIIListFILE = FileList(areFlatLists);
                mfits('build','FLAT',['@',FlatASCIIListFILE(1).FullName]);
            end
            if any(areObjLists)
                mtalk('\n Found object file list.');
                ObjASCIIListFILE = FileList(areObjLists);
                mfits('build','OBJECT',['@',ObjASCIIListFILE(1).FullName]);
            end
            
            
            
        else
           
            
            error('MAESTRO:mfits:noFiles','No @lists found. Other autodection methods NYI');
           
                                                                        
        end
        
        
        
end
        