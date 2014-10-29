function pid = mprocessinit(text)
%MPROCESS Manages process initialization.
%   PID = MPROCESSINIT(TEXT,NAME) will initialize a process with status text "TEXT".
%
%   Example:
%       PID = MPROCESS('Building a pyramid')
%
%   Copyright (C) 2010 James Dalessio

% This is a global variable which stores all of the information about processes in maestro.
global MAESTRO_PROCESS_DATA

% If the process data has not been initialized do this now.
if isempty(MAESTRO_PROCESS_DATA), MAESTRO_PROCESS_DATA = struct('STATUS',0,'ISRUNNING',0,'TEXT','','STACK',[],'NUMUSERS',0,'PERCENTAGE',0,'LASTTIME',0); end
       
% Attempt to find an available storage location for the process.        
pid = find(~[MAESTRO_PROCESS_DATA.NUMUSERS],1);

% If there is no available index make it the next index of the structure.
if isempty(pid), pid = length(MAESTRO_PROCESS_DATA)+1; end

% Insert information into the process field.
MAESTRO_PROCESS_DATA(pid).STATUS = 0;
MAESTRO_PROCESS_DATA(pid).ISRUNNING = 0;
MAESTRO_PROCESS_DATA(pid).TEXT = text;
MAESTRO_PROCESS_DATA(pid).STACK = dbstack;
MAESTRO_PROCESS_DATA(pid).PERCENTAGE = 0;
MAESTRO_PROCESS_DATA(pid).NUMUSERS = 1;
MAESTRO_PROCESS_DATA(pid).LASTTIME = 0;
MAESTRO_PROCESS_DATA(pid).LASTPERCENTAGE = 0;
MAESTRO_PROCESS_DATA(pid).WASWARNING = 0;

% Write the process as being started.
mtalk(text); 
if mvolume == 1; mtalk('[ 00%% ]'); end