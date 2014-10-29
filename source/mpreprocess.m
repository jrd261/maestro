function argOut = mpreprocess(argIn,argClass)
%MPREPROCESS converts input strings into actual values.
%   ARGOUT = MPREPROCESS(ARGIN,ARGCLASS)
%
%   Copyright (C) 2009-2010 James Dalessio


% We will by default return an output variable indicating things went
% poorly.
argOut = [];

% We will mark two variables to let us know if the default values are being
% asked for. See the variable definitions to see why these statements are
% here.
isEmptyDefault = isempty(argIn) && ~iscell(argIn);
isCalledDefault = isempty(argIn) && iscell(argIn);

% For each class we will first check to return the default empty/called. If
% these are not true we will check the input and process it.
switch mclasstype(argClass)
    case {'string'}       
        % This is a very basic class. It will be sent to functions as a
        % cell array of strings only. 
        
        % Default called values for class string is {}. The empty value is
        % {}.
        % This means that string value should always have more than zero
        % argument specified. 
        if isEmptyDefault, argOut = {}; return, end
        if isCalledDefault, argOut = {''}; return, end                                                                          
        
        % The input is already a cell array of strings so just send it back out.
        argOut = argIn;
        
    case {'boolean','bool'}
        % The boolean class is logical arrays of true and false. This class
        % supports multiple entries.
        
        % Default empty boolean is false and called is true.
        if isEmptyDefault, argOut = false; return, end
        if isCalledDefault, argOut = true; return, end
        
        % Initialize an output array.
        argOut = false(length(argIn),1);
                
        % Check the input for boolean like words. If none match we will
        % report this and return a [] (error).
        for iEntry = 1:length(argIn), argOut(iEntry) = mstring2bool(argIn{iEntry}); end                                          
        
    case {'numeric','double'}
        % The numeric of double class is an array of numbers. We can have
        % multiple entries but no default called value. The default empty
        % value is 0.
        
        % Default empty double is [] and called is not allowed ([]).
        if isEmptyDefault, argOut = []; return, end
        if isCalledDefault, argOut = []; return, end
        
        argOut = zeros(size(argIn));
        for i=1:length(argIn)
            argOut(i) = eval(argIn{i});
        end
        % Convert the input array into numbers.
%        argOut = str2double(argIn);
        
        % Check if there are any NANs.
        if any(isnan(argOut)), error('MAESTRO:mpreprocess:nans','\nCould not parse entry into numeric array.'); return, end
        
end

