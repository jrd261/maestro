classdef FILE < handle
    %FILE A class for storing information about a file.
    %   This class is an abstraction of a file. It contains information
    %   about the file, or possible file and allows controled actions such
    %   as reading or writing to be performed on the file. The class
    %   constructor creates the object(s) and sets the name/location of the
    %   file. 
    %
    %   Copyright (C) 2010-2011 James Dalessio
    
    properties (SetAccess = private)        
        % These properties are the basic information about the file. They
        % cannot change externally.
        
        FullName % The name of the file including the absolute path.  (string)
        Name % The name of the file only without path. (string)
        Ext % The file extension, including the .. (string)
        Path % The absolute path to the file. (string)
    end
        
    properties
        % These properties control writing and reading of the file. The
        % FID is set to -1 when the file is closed. 
        
        FID = -1;% The current FID for reading/writing from/to the file. (int)
        FIDMode % The current mode for reading writing. Can be 'r', 'w', or 'a' for read write append. (string).
    end
    properties(Hidden)
        S_Header = [];        
    end    
    properties (Dependent = true, SetAccess = private)
        % There properties list information about the files that can change
        % outside of the program. When any of these properties are accessed
        % they are updated just prior to retrieving the value. 
        
        FileSize % The size of the file in bytes (double).
        Exists % Whether or not the file exists (bool).
        IsDir % Whether or not the file is a directory (bool).
        LastMod % The last time (date number) of modification. (double)
        Header % The header of the file.
    end
    
    methods
        function File = FILE(rawfiles,varargin)
            %FILE builds a FILE object or an array of FILE objects.
            %   FILE = FILE(RAWFILES) will construct an array of file
            %   objects representing the files referenced in RAWFILES.
            %
            %   FILE = FILE(RAWFILES,PROPERTY1,VALUE1,PROPERTY2,VALUE2,...)
            %   will specify property value pairs for the filelist
            %   building. See below for more information.
            %
            %   RAWFILES must be a string or a cell array of strings. Each
            %   cell (or the string) should contain either the name of a
            %   file, directory, a wildcard reference to files, or the name
            %   of an ASCII list filled with names of files. If an ASCII
            %   list is specified the @ symbol should appear at either the
            %   begining of the filename "/data/@list" or the path
            %   "@/data/list", otherwise the list itself will be considered
            %   the target file.
            %
            %   Here is a list of property value combinations.
            %
            %   Property: 'forceexistence' Class:  bool Default: false
            %   Description: Asserts that the files being added exist. If
            %   any of them don't exist an error will be thrown.                        
            %
            %   Property: 'allowdirectories' Class: bool Default: true
            %   Description: If set to false directories will not be
            %   included in the final filelist.
            %
            %   Property: 'forcenonempty' Class: bool Default: false
            %   Description: If set to true an error will be thrown before
            %   an empty filelist is returned.
            
            % If no arguments were specified return a single FILE object.
            % This is neccessary because this constructor recursively calls
            % this function with no input arguments to build a list of FILE
            % objects.
            if ~nargin, return; end
            
            % Add the properties to a structure that will be used to store
            % the PV data. See the function MPROPVAL for more information
            % and the function help for information on what these property
            % values control.
            PropVal.forceexistence = false;
            PropVal.allowdirectories = true;       
            PropVal.forcenonempty = false;
            
            %  Varargin should be empty or
            % property value pairs. Pass this to MPROPVAL to process the
            % input. If an error occured rethrow it as if it were called by
            % this function.
            if nargin>1,try PropVal = mpropval(PropVal,varargin); catch ME, rethrow(ME); end, end
            
            % Assert rawfiles is a string or cell array of strings. If not
            % throw an error. Make sure to let the user know which class
            % the input was and what it should have been.
            assert(ischar(rawfiles)||iscellstr(rawfiles),'MAESTRO:FILE:badInput',['FILE constructor was called input argument of class "',class(rawfiles),'" when the class must be char or cell.']);                        
            
            % The input variable RAWFILES is either a string or cellstr.
            % MSTRING2CELL will convert it to a cell array of strings.
            % Check if it is a charecter array and if so, convert it to a
            % cell array of strings.
            if ischar(rawfiles), rawfiles = mstring2cell(rawfiles); end
            
            % The variable RAWFILES is guarenteed to be a cell array, but
            % it does not necessarily have a non empty (whitespace) string
            % in each cell array. This MAESTRO function will remove all
            % "empty" strings from the cell array.
            rawfiles = mcellstrcorrect(rawfiles);
            
            % After removing all empty strings from the cell arrary it is
            % possible that the cell array is completely empty. Assert that
            % it is populated.
            assert(~isempty(rawfiles),'MAESTRO:FILE:noFiles','Tried to build a filelist with no files.');
            
            % It is guarenteed that the input variable rawfiles is a cell
            % array of strings with at least one nonempty, nonwhitespace
            % string. It is assumed that the files were specified with
            % either an absolute path or a path relative to the current
            % path. Use the MRELPATH function to obtain the full path for
            % each file specified in the cell array. The current path is
            % assumed to be the present working directory.
            rawfiles = mrelpath(rawfiles,pwd);            
            
            % Some of the specified files will be wildcard captures and
            % ASCII lists. Obtain logical indicies for each of them. Also,
            % obtain logical indicies for files which do not satisfy either
            % criteria. These are files specified by name.
            areASCIILists = cellfun(@(x) any(x == '@'),rawfiles);
            areWildCard = cellfun(@(x) any(x == '*'),rawfiles);
            areNormalFiles = ~(areASCIILists | areWildCard);         
            
            % Initialize an empty file object. As files are added to the
            % array they will be concatenated with this original object.
            File = FILE.empty;
            
            % It is possible that a file was specified that uses wildcard
            % captures and is a filelist. Check if this is the case. If so,
            % report an error and show the entry in RAWFILES.
            if any(areASCIILists & areWildCard), error('MAESTRO:FILE:asciiAndWC',['Confusion about the name of file ',rawfiles{find(areASCIILists & areWildCard,1)},'. This is specified as an ASCII list and a wildcard query.']); end
            
            % Extract the files that appear to be ASCII lists.
            asciiFiles = rawfiles(areASCIILists);
            
            % Begin a loop over the supposed ascii lists.
            for iFile = 1:length(asciiFiles)
                
                % The file name contains the @ charecter to specify that it
                % is an ASCII list. Remove the charecter.
                asciiFiles{iFile}(asciiFiles{iFile} == '@') = [];
                
                % The filename could now be empty. Assert that the file is
                % not empty.
                assert(~isempty(asciiFiles{iFile}),'MAESTRO:FILE:emptyListFileName','A filename was passed to the filelist builder whos name consisted of only @ symbols.');
                
                % Attempt to read in the ASCII list using the MREAD
                % function.
                fileData = mread(asciiFiles{iFile});
                
                % The ASCII file could have been empty. Assert that at
                % least one line existed in the ASCII files.
                assert(~isempty(fileData),'MAESTRO:FILE:emptyASCIIList',['The ASCII file list ',asciiFiles{iFile},' was empty.']);
                
                % The files in the ASCII list were specified either
                % absolutely or relative to the path the ASCII list lives
                % on. Make sure that those files are given from their
                % absolute paths by using the current path of the ASCII
                % list with the FILEPARTS function.
                fileData = mrelpath(fileData(:,1),fileparts(asciiFiles{iFile}));
                
                % This new list of files contained in FILEDATA need to be
                % processed. Recursively call this method and concatenate
                % the output to what is already known. This is a variable
                % growing in a loop but there is no way to preallocate this
                % memory. The way the constructor is called depends on
                % whether of not varargin was specified.                
                if nargin>1, File = [File,FILE(fileData,varargin{:})]; else File = [File,FILE(fileData)]; end %#ok<AGROW>
                
            end
            
            % Extact the files that are wildcard queries.
            wildCardFiles = rawfiles(areWildCard);
            
            
            % Loop over all wildcard files
            for iFile=1:length(wildCardFiles);              
                % Obtain a list of wildcard files. This will return an
                % nx1 structure where n is the number of matching
                % files.
                dirList = dir(wildCardFiles{iFile});
                               
                % If directories aren't allowed from wildcard queries
                % get rid of them here.
                if ~PropVal.allowdirectories, dirList([dirList.isdir]) = []; end
                                              
                % If the directory is empty don't bother running the next
                % line. Continue to the next file.
                if isempty(dirList), continue, end
                
                % If this list isn't empty the files contained in the
                % list are relative to their current path. Use the
                % FILEPARTS function to extract the path. Concatenate
                % the new FILE array to the current one. This is a
                % variable growing in a loop but there is no way to
                % preallocate the memory.
                if nargin>1,  File = [File,FILE(mrelpath({dirList.name},fileparts(wildCardFiles{iFile})),varargin{:})]; else File = [File,FILE(mrelpath({dirList.name},fileparts(wildCardFiles{iFile})))]; end %#ok<AGROW>
                
            end
            
            % All that is left is regular files. Extract the list of
            % regular files. Note these files have already been assigned
            % there absolute path.
            normalFileList = rawfiles(areNormalFiles);
           
            % Assert that if the filelist is forced to be non empty and is
            % empty that an error will be thrown.
            if PropVal.forcenonempty && isempty(normalFileList) && isempty(File), error('MAESTRO:FILE:isEmpty','No matching files were found.'); end
            
            % If there are no normal files to add to the list this function
            % is complete. Check if there are no normal files and return if
            % true.
            if isempty(normalFileList), return, end
            
            % Initialize an array of FILE objects. These are handle objects
            % so this doesn't do us any more good than simple initializing
            % the right amount of memory.
            newFiles(1:length(normalFileList)) = FILE;
            
            % Begin to loop over list of files.
            for iFile = 1:length(normalFileList)
                
                % Construct the object and create a reference. The
                % reference must be created for listener adding later.
                newFiles(iFile) = FILE; obj = newFiles(iFile);
                
                % Record some generic information about the files. This
                % information is not dependent on the existance of the
                % file, only its full name and path.
                [path,name,ext] = fileparts(normalFileList{iFile});
                obj.FullName = normalFileList{iFile};
                obj.Name = [name,ext];
                obj.Path = path;
                obj.Ext = ext;
                
                % Manually check the existance of the files if this was
                % specified in the PropVals. If existance is required and
                % the file does not exist throw an error.
                assert(~PropVal.forceexistence || exist(normalFileList{iFile},'file'),'MAESTRO:FILE:existFail',['The file ',normalFileList{iFile},' does not exist.']);
                
                % If the property value "allowdirectories" is set to false
                % check that the file is not a directory. If it is a
                % directory throw an error.
                if ~PropVal.allowdirectories && isdir(normalFileList{iFile}), error('MAESTRO:FILE:isDir',['The file ',normalFileList{iFile},' appears to be a directory but directories are not allowed in this file list.']); end                
                
            end
            
            % Concatenate the new files added to the list with the files
            % that were added by ASCII list and wildcard query.
            File = [File,newFiles];
                                    
        end
    end  
        
    methods
        
        % The following are dependent get methods used in place of fixed
        % property values. They will update when the value for the
        % properties is requested.
        
        function exists = get.Exists(obj)
            % GET.EXISTS returns whether or not the file exists.  
            %   This is almost as simple as it gets. 
            
            % Check if the file exists.
            exists = exist(obj.FullName,'file');            
        end
        
        function filesize = get.FileSize(obj)  
            % GET.FILESIZE returns the size of the file.
            %   If the file does not exist this will throw an error. 
            
            % Check if the file exists.
            if obj.Exists
                % The file exists. Retrieve the size of the file using the
                % MATLAB dir command.
                dirInfo = dir(obj.FullName); filesize = dirInfo.bytes;
            else
                % The file does not exist. Throw an error.
                error('MAESTRO:FILE:getFileSize:noExist',['The file ',obj.FileName,' does not exist but its size was requested.']);               
            end           
        end
        function lastmod = get.LastMod(obj)
            % GET.LASTMOD returns the last modification date of the file.
            %   IF the file does not exist this will throw an error.
            
            % Check if the file exists.
            if obj.Exists
                % The file exists. Retrive the last mod date of the file
                % using the MATLAB dir command.
                dirInfo = dir(obj.FullName); lastmod = dirInfo.datenum;
            else
                % The file does not exist. This is an error.
                error('MAESTRO:FILE:getLastMod:noExist',['The file ',obj.FullName,' does not exist but its last modification date was requested.']);
            end           
        end
        function isdir = get.IsDir(obj)
             % GET.ISDIR returns the whether or not the file is a
             % directory.
             %   If the file does not exist this will throw an error.
            
            % Check if the file exists.
            if obj.Exists
                % The file exists. Retrive the whether the file is a directory
                % using the MATLAB dir command.
                dirInfo = dir(obj.FullName); isdir = dirInfo.isdir;
            else
                % The file does not exist. This is an error.
                error('MAESTRO:FILE:getIsDir:noExist',['The file ',obj.Name,' does not exist but it was requested whether or not it was a directory.']);
            end           
        end
        function H = get.Header(obj)
            
            if ~isempty(obj.S_Header)
                H = obj.S_Header;
                return
            end
            
            fid = obj.open;
            
            % Initialize the header.
            H = cell(0,3);
            
            % Loop over all lines of header.
            iLine = 1;
            while(1)
                
                string = fgets(fid);
               if ~ischar(string), break; end
                lineData = strtrim(string);
                
                
                if isempty(lineData) || lineData(1) ~= '#', break; end, lineData(1) = []; lineData = strtrim(lineData);
                
                for iChar=2:length(lineData)
                    if lineData(iChar) == '='
                        H{iLine,1} = strtrim(lineData(1:iChar-1));
                        lineData(1:iChar) = [];
                        break;
                    end
                end
                
                for iChar=2:length(lineData)
                    if lineData(iChar) == '#'
                        H{iLine,2} = strtrim(lineData(1:iChar-1));
                        if iChar+1 < length(lineData), H{iLine,3} = strtrim(lineData(iChar+1:length(lineData))); end
                        break;
                    end
                    
                    if iChar+1 < length(lineData) && any(strcmp(lineData(iChar:iChar+1),{'//','\\'}))
                        H{iLine,2} = strtrim(lineData(1:iChar-1));
                        if iChar+2 < length(lineData), H{iLine,3} = strtrim(lineData(iChar+2:length(lineData))); end
                        break;
                    end
                    if iChar == length(lineData)
                        H{iLine,2} = strtrim(lineData(1:length(lineData)));
                    end
                    
                end
                
                
                iLine = iLine + 1;
            end
            
            
            obj.S_Header = H;
            
            obj.close;
        end
    end
    
end
