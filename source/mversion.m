function [version,revision] = mversion
%MVERSION Retrieves the version of MAESTRO.
%   VERSION = MVERSION will output the current version of MAESTRO. This relies of information obtained from bazaar.
%
%   If we are in deployed mode or this program is not in a branch this will simply read the configuration file containing the version name and
%   return it. Otherwise this will obtain the version information from bazaar and write it to that file.
%
%   Example: 
%       VERSION = MVERSION
%
%   See also xxxx
%
%   Copyright (C) 2009-2010 James Dalessio

% 
persistent MAESTRO_VERSION MAESTRO_REVISION


if ~isempty(MAESTRO_VERSION) && ~isempty(MAESTRO_REVISION), version = MAESTRO_VERSION; revision = MAESTRO_REVISION; return; end

% Obtain the version information from file.
rawVersionData = mread([mrootpath,filesep,'version'],'%q %q');

 

% Check if the program is deployed.
if ~isdeployed 

    % Rip the revision number and revision name from bazzar.
    [failedTest1,rawRevisionNumber] = system('bzr log -l 1 | grep revno');
    [failedTest2,rawBranchName] = system('bzr log -l 1 | grep branch');
       
    % Check if this failed. This would likely fail if bzr was not installed on the system.
    if ~failedTest1 && ~failedTest2
    
        % Convert the build number and branch name into
        % something legible.
        revisionNumber = regexp(deblank(rawRevisionNumber),'\d*$','match');
        branchName = regexp(deblank(rawBranchName),'\S*$','match');
	if isempty(revisionNumber), revisionNumber{1} = 0; end
      

        % Do this in case bazaar is installed but they are not developing MAESTRO
        if  (~any(strfind(revisionNumber{1},'ERROR')) && ~any(strfind(branchName{1},'ERROR')))                        
            
            rawVersionData(strcmp(rawVersionData(:,1),'MAESTRO_REVISION'),2) = revisionNumber;           
            fID = fopen([mrootpath,filesep,'version'],'w');             
            if fID ~= -1
                for iEntry = 1:size(rawVersionData,1)
                    fprintf(fID,[rawVersionData{iEntry,1},' ',rawVersionData{iEntry,2},'\n']);                               
                end                       
                fclose(fID);
            end
            
        end
                                
    end
   
end

% Read in the version from file.
MAESTRO_VERSION = rawVersionData{strcmp(rawVersionData(:,1),'MAESTRO_VERSION'),2}; version = MAESTRO_VERSION;
MAESTRO_VERSION = [MAESTRO_VERSION(1:2),'.',MAESTRO_VERSION(3:4),'.',MAESTRO_VERSION(5:6)];

MAESTRO_REVISION = rawVersionData{strcmp(rawVersionData(:,1),'MAESTRO_REVISION'),2}; revision = MAESTRO_REVISION;

  
    
version = MAESTRO_VERSION;
revision = MAESTRO_REVISION;



