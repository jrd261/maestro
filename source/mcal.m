function output = mcal(action,value)




% Declare a persistent variable to store the current MAESTRO calibration.
% We give this variable the prefix P to indicate that this is the
% persistent variable. The current MAESTRO calibration will always be
% stored here and any function can access the calibration by calling this
% function with no input arguments.
persistent P_Calibration

% Check that the P_Calibration variable has been initialized. If it has not
% been initialized we will set it to be a CALIBRATION object with the
% default property values.
if isempty(P_Calibration), P_Calibration = CALIBRATION; end

% The default output for MCAL is to return the CALIBRATION object. Set the
% output to the CALIBRATION object. Remember this is a handle object and is
% pass by reference.
output = P_Calibration;

% If there were no input arguments we will just return the output variable
% set to the value of the P_Calibration variable. 
if ~nargin, return, end

% Begin a switch statement to determine the action we are to perform 
% with the calibration object.
switch action
    case 'build'
        
        % We are asked to build a calibration given the current state of
        % the FITS lists. This is all done within the calibration object
        % itself. Call the method which will build the calibration.
        P_Calibration.build;
        
        
        
    otherwise
        
        % If we reach this point none of the actions were recognized. Throw
        % an error.
        error('MAESTRO:mcal:badAction','Unknown action for MAESTRO calibration.');

end