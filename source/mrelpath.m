function relativePath = mrelpath(targetPath,currentPath)
%% SYNOPSIS
%   Figures out the full path of a path relative to another.
% VARIABLES
%   [targetPath] (cellstr) = Cell list of target paths. 
%   [currentPath] (string) = The absolute current path.
%   [relativePath] (cellstr) = Relative paths between the two directories.
% VITAL
%   Created 2009/09/16 James Dalessio
%   Modified 2010/11/29 James Dalessio
% NOTES
%   The current path should always be absolute.
%   No Windows support yet. 


if isempty(targetPath), relativePath = currentPath; return, end



%% Obtain File System Format (0)
% Check if the file system is unix type. This is important for file seperators.

% Use the built in matlab "isunix" function to record whether the system is unix like or not.
isUnix = isunix;

if(isUnix)
    % Record the backslash as the file seperator and the length of the root directory "/" as 1.
    fileSeperator = '/';        
    lengthRoot = 1;
else
    % Record the frontslash as the file seperator and the length of the root directory "C:\" as 3.
    fileSeperator = '\';
    lengthRoot = 3;
end

%% Initialize Data Format (0)
%   Check the format of the incoming data to see if we are dealing with a single string or a cell array of strings and initialize the output
%   accordingly

% Check if the incoming input is in cell format.
if(iscell(targetPath))    
    % Note that we are using the cell format in this routine.
    usingCells = true;        
    % Initialize the output variable. This saves some overhead.
    relativePath = cell(size(targetPath));        
    % Check if they are wildcar.

   
    
else    
    % Note that we are not using the cell format in this routine. We will convert to cell now but back to a string at the end.
    usingCells = false;    
    % Initialize the output variable.
    relativePath = cell(1);        
    % Change the input into cel format for the rest of the function.
    targetPath = {targetPath};    

end

% Extract @ symbols
aiFilelists = find(cellfun(@(x) ~isempty(x),strfind(targetPath,'@')));
for i=1:length(aiFilelists)
    targetPath{aiFilelists(i)}(targetPath{aiFilelists(i)} == '@') = [];
    targetPath{aiFilelists(i)}(length(targetPath{aiFilelists(i)})+1) = '@';
end

%% Remove Trailing File Seperators (0)
%   We do not want any file paths to end with a file slash. We will remove them. Untested in Windows.

% Record the logical indicies for the target path ending with a file seperator. We need to ensure that the path is not just "/".
ilMatches = cellfun(@(x) x(length(x)) == fileSeperator & length(x)>lengthRoot,targetPath);  
        
% Remove the trailing file seperator from the current path if there is one there.
if length(currentPath) > lengthRoot && currentPath(length(currentPath)) == fileSeperator,currentPath(length(currentPath)) = [];end
    
% Remove the file seperator from the target paths.    
targetPath(ilMatches) = cellfun(@(x) x(1:length(x)-1),targetPath(ilMatches),'UniformOutput',false);

%% Copy Empty Target Path Entries (0)
% If no target path is specified for a paticular entry we will just assume the target path should be the current path.

% Obtain logical indicies of the empty target paths.
ilMatches = cellfun(@(x) isempty(x),targetPath);

% Record the number of target paths which have been copied.
numEmpty = length(nonzeros(ilMatches));

% Copy the current path into the outgoing relative paths. 
relativePath(1:numEmpty) = repmat({currentPath},[numEmpty,1]);

% Remove these entries from the target path cell array.
targetPath(ilMatches) = [];

%% Copy Absolute Target Paths (0)
% If the target path is absolute we will assume the relative path is just the target path.

% This section is platform dependent.
if(isUnix)       
    
    % Obtain logical indicies for target paths which are absolute.
    liMatches = cellfun(@(x) x(1)==fileSeperator,targetPath);    
    
else
        
    % Obtain logical indicies for target paths which are absolute. I think this is appropriate for windows.
    liMatches = cellfun(@(x) length(x) > 1 & x(2) == ':',targetPath);
    
end

% Obtain the number of valid absolute target paths.
numAbsolute = length(nonzeros(liMatches));

% Copy the target paths directly.
relativePath(numEmpty+1:numEmpty+numAbsolute) = targetPath(liMatches);              

% Remove those entries from the list of target paths.
targetPath(liMatches) = [];

%% Copy Relative Target Paths (0)
% The remaining target paths must all be relative to the current path. 

% Merge the target and current path.
relativePath(numEmpty+numAbsolute+1:numEmpty+numAbsolute+length(targetPath)) = cellfun(@(x) [currentPath,fileSeperator,x],targetPath,'UniformOutput',false);

%% Collapse Paths (0)
% The . and .. parts of file paths need to be treated here. 

% Begin a loop over all of the relative paths. Perhaps we can turn this into a cellfun call someday. Someday...
for i=1:length(relativePath)        
    %% Obtain References to Sections of the Relative Path (0)
    % We will collect logical indicies about where the file slashes, . and ..'s are.
    
    % Obtain logical indicies to the location of file seperators.
    aiSlashes = find(relativePath{i} == fileSeperator); 
  
    % Obtain the number of entrees between each file seperator (starting with how many are after the first).
    numSlashes = ([aiSlashes(2:length(aiSlashes)),length(relativePath{i})+1] - aiSlashes)-1;
    
    % Obtain a preliminary logical index of sections with one charecter.
    liNothings = (numSlashes == 1);
    
    % Obtain a preliminary logical index of section with two charecters.
    liKillers = (numSlashes == 2);
  
    % Record the indicies for one charecter sections matching ".".
    liNothings(liNothings) = relativePath{i}(aiSlashes(liNothings)+1) == '.';        
    
    % Record the indicies for two charecter sections matching "..".
    liKillers(liKillers) = (relativePath{i}(aiSlashes(liKillers)+1) == '.') & (relativePath{i}(aiSlashes(liKillers)+2) == '.');
        
    %% Remove . and .. Sections (0)
    
    % Initialize a place to keep track of the removed sections.        
    liRemoved = false(size(aiSlashes));
    
    % Remove the entire section (including slashes) if they are . and ..
    relativePath{i}(aiSlashes(liNothings)) = ' ';   
    relativePath{i}(aiSlashes(liNothings)+1) = ' ';
    relativePath{i}(aiSlashes(liKillers)) = ' ';            
    relativePath{i}(aiSlashes(liKillers)+1) = ' ';    
    relativePath{i}(aiSlashes(liKillers)+2) = ' ';
    
    % Record the sections we just removed.
    liRemoved(liNothings | liKillers) = true;
            
    %% Collapse .. Sections (0)   
    
    % Obtain absolute indicies of sections with ..
    liKillers= find(liKillers);
        
    % Start a loop over those sections.
    for j=1:length(liKillers)                                                    
        
        % For each section start with the previous section.
        k = liKillers(j)-1; 
        
        % Check if we are at the first section. If we are the .. does nothing.
        if(k<1)
            continue
        end
            
        % Start dummy loop over sections.
        while(1)
            
            % Check if this section has been removed.
            if(~liRemoved(k))
                
                % If the section still exists we will collapse it.
                relativePath{i}(aiSlashes(k):aiSlashes(k+1)-1) = ' ';
                
                % Mark that it has been removed.
                liRemoved(k) = true;
                break
            end
            
            % Terminate if we are at the first section.
            if(k==1)
                break
            end
            
            % Move backwards a section
            k = k -1;
            
        end
        
    end
    
    % Remove the blank entries from this path.
    relativePath{i}(relativePath{i} == ' ') = [];
    
    % Make sure we put back in a file seperator if we have deleted it.        
    if(isUnix)
        if(isempty(relativePath{i}))
           relativePath{i} = '/'; 
        end        
    else
        if(length(relativePath{i}) == 2)
            relativePath{i}(3) = '\';
        end        
    end
                  
end




%% Restore Original Formatting (0)
if(~usingCells)
    relativePath = relativePath{1};     
end

end