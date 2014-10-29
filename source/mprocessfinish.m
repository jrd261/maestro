function mprocessfinish(pid,status)
%MPROCESSFINISH will mark the process as finished.
%   MPROCESSFINISH(PID,STATUS) will indicate that the process was completed with the given status.
%
%   Example:
%   MPROCESSFINISH(PID,1) will mark the process PID as completed sucessfully.
%
%   Copyright (C) 2010 James Dalessio   

% Declare the process data as a global variable.
global MAESTRO_PROCESS_DATA

% Mark the given process as completed with the given status.
MAESTRO_PROCESS_DATA(pid).STATUS = status;
MAESTRO_PROCESS_DATA(pid).ISRUNNING = 0;

% Check whether or not to display text.

if mvolume == 1 
	if ~isdeployed	   
	    if MAESTRO_PROCESS_DATA(pid).WASWARNING
        	mtalk('\b\b\b\b\b\b\b[ WARNING ]',1,0);
	    elseif status == 0
        	mtalk('\b\b\b\b\b\b\b[ FAILED ]\n',1,0);
	    elseif status == 1
	        mtalk('\b\b\b\b\b\b\b[ OK ]',1,0);
	    elseif status == -1
	        mtalk('\b\b\b\b\b\b\b[ WARNING ]',1,0);
    	    end      
	else
	    if MAESTRO_PROCESS_DATA(pid).WASWARNING
        	mtalk('\b\b\b\b\b\b\b [ WARNING ] ',1,0);
	    elseif status == 0
        	mtalk('\b\b\b\b\b\b\b [ FAILED ]\n ',1,0);
	    elseif status == 1
	        mtalk('\b\b\b\b\b\b\b [ OK ] ',1,0);
	    elseif status == -1
	        mtalk('\b\b\b\b\b\b\b [ WARNING ] ',1,0);
    	    end   
	end
  
else
     if status == 0
        mtalk('[ FAILED ]\n',1,0);
    elseif status == 1
        mtalk('[ OK ]',1,0);
    elseif status == -1
        mtalk('[ WARNING ]',1,0);
    end        

    
end


 
    
