function mlogfid = mlog(action,data,volume)
%MLOG Manages messages to the log in MAESTRO.
%   MLOG(ACTION,DATA) will perform the action as described in ACTION.
%
%   MLOG(ACTION,DATA,VOLUME) will assume a message volume as specified by VOLUME
%
%   MLOGFID = MLOG(...) will return the fid of the current log.
%
%   ACTION is a string that can either be "write", "open", or "close". If it is "write", the string contained in data will be written to the log.
%   If the log does not exist it will be opened in the default location. If "open" is specified, data will be the name of the file the log will
%   be written in. If "close" is specified, DATA can be empty.
%
%   Example:
%       MLOG('write','Hello, this is a verbose message being written to the log.',2);
%       MLOG('open','/myfiles/log');
%       MLOG('close');
%       fid = MLOG;
%
%   See also MLOGVOLUME, MTALK, MVOLUME
%
%   Copyright (C) 2009-2010 James Dalessio

% The fid of the log will be stored in a persistent variable. This will be blank if no log is opened.
persistent MAESTRO_LOG_FID 

% Check if we are attempting to close the log or open a new log.
if nargin   
    switch action
        case {'write'}
            
            % Check if a log is opened. If not, open the default log and write the opening time. In the future the version might be included in
            % here.
            if isempty(MAESTRO_LOG_FID) || MAESTRO_LOG_FID == -1, mlog('open',[mpath,filesep,'log']); mlog('write',['Log opened ',datestr(now,31)]); end    
            
            % Find the volume of the message.
            if nargin<3, volume = 1; end              
            
            % Check whether this message will be written and write it.
            if mlogvolume>=volume, fprintf(MAESTRO_LOG_FID,data); end            
            
        case {'open'}         
            
            % Attempt to open the log in the specified location.
            MAESTRO_LOG_FID = fopen(data,'w'); 
            
            % If the log fails to open we should throw an error.
            if MAESTRO_LOG_FID == -1, error('MAESTRO:mlog:failedOpen',['Error opening log. Failed to open log with filename ',data,'.']); end  
            
        case {'close'}
            
            % Try to close the log. Don't need to throw an error here if it fails.
             try fclose(MAESTRO_LOG_FID); catch, end; MAESTRO_LOG_FID = [];                         
             
        otherwise
            
            % Throw an error as this is an unknown action.
            error('MAESTRO:BUG','Could not write to log. Invalid parameter specified as action.');
    end    
end

% Record the logfid
mlogfid = MAESTRO_LOG_FID;
