function maestro(varargin)
%MAESTRO Starts Maestro, the Matlab Astronomy Toolkit.
%   This is the top level entry point of Maestro, and is essentially serves
%   as a parser and wrapper for other functions called commands.
%
%   Type "maestro help" or see the MAESTRO documentation for more
%   information.
%
%   Copyright (C) 2007-2012 James Dalessio



% Enclose the entire program in a try catch statement. When an error
% actually reaches this top level we will use this to control what the
% actually sees when there is a problem.
try
               
    % Check that input has been specified. If no input was specified
    % display the help contents.
    if isempty(varargin), maestro('help'); return, end
    
    % Check that all entries/words of varargin are strings. If any are not
    % strings shame on whoever called MAESTRO.
    if ~all(cellfun(@ischar,varargin)), error('MAESTRO:maestro:badInput','The input to MAESTRO must be a string.'); end
    
    % We will loop over all arguments and check for global flags. Global
    % flags used to be before the command but now they are after. Start at
    % argument 2.
    iArgument = 2;        
    while(iArgument < length(varargin))

        switch varargin{iArgument}
            % Use a switch statement to determine which flag was specified. For
            % each case we will perform some desired action.
            
            case {'-c','--config'}
                % If -c of --config was specified the user is attempting to
                % specify a specific configuration to load. The next words
                % should be the name of the configuration.                 
                while iArgument + 1 <= length(varargin) && varargin{iArgument+1}(1) ~= '-'                    
                    mconfig('append',varargin{iArgument + 1});
                    varargin(iArgument+1) = [];                                            
                end                                               
              
            case {'-q','--quiet'}, mvolume(0);
            case {'-v','--verbose'}, mvolume(2);
            case {'-l','--loud'}, mvolume(3);
                % The above statements affect the amount of output that
                % will be displayed at the command line. The mvolume
                % command sets the programs verbosity.
                
            case {'--log-volume-quiet'}, mlogvolume(0);
            case {'--log-volume-verbose'}, mlogvolume(2);
            case {'--log-volume-load'}, mlogvolume(3);
                % The above statements control the amount of output
                % that will be written to the log. The mlogvolume command
                % controls the log verbosity. These commands will probably
                % not get much usage.
                
            case {'--version'}, mtalk([mversion,'\n']);
            case {'--about'}, mtalk([mabout,'\n']);
            case {'--copyright'}, mtalk([mcopyright,'\n']);
                % The above commands will display information about
                % Maestro. The --version flag will return the current
                % version of Maestro in plain text (good for grepping). The
                % --about flag will display some detailed information about
                % maestro and --copyright/--license will display copyright
                % and license information.
                
            case {'-h','--help'}, maestro('help');
                % The -h or --help flag will recall maestro to execute the
                % help command.
                
            case {'-d','--debug'}, mdebugmode(true);
                % Debug mode will control if we are going to clear all
                % peristant variables when Maestro is complete. In the case
                % of a deployed function this will do nothing. 
                
            otherwise, 
                
                % There was no global flag in this position. Move to the
                % next position.
                iArgument = iArgument + 1;                
                continue                
           
        end
        
        % A global flag was found. Remove it.
        varargin(iArgument) = [];                
        
    end
    
    % Initialize a cleanup function to wipe all variables when Maestro is
    % finished. Note we only want to do this if debug mode is off. this
    % function is located at the end of this file.
    if ~mdebugmode, cleanupObj = onCleanup(@cleanupfunction); end
    
    % If no command was specified just return. There is no reason to
    % attempt to execute anything else.
    if isempty(varargin), return, end
    
    
    %% NEEDS WORK
    
    
    % From this point on we will be processing arguments and flags to
    % the specified command.
    
    % Extract the name of the command and remove it from varargin.
    commandName = varargin{1}; varargin(1) = []; commandCall = varargin;
    
    % Retrieve the command list.
    commandList = mcommandlist;
    
    % Begin loop to search for the actual command name. The first cell array is
    % the actual names of the commands. The second cell array is a list of
    % aliases to the named command.
    for iCommand = 1:size(commandList,1)
        
        % Check if any of the command aliases match the called command. If one
        % does, write over the called command and break the loop.
        if any(strcmp(commandName,commandList{iCommand,2})), formalCommandName = commandList{iCommand,1}; break; end
        
        % Check if we have tried all possible commands. If this is true the
        % command does not exist.
        if iCommand == size(commandList,1), error('MAESTRO:maestro:badCommandName',['Command "',commandName,'" was not found.\nType "maestro commands" for a list of commands.']); end
        
    end
    
    % Initialize Data to Pass to the Command. This will be the sole input argument to a command. We will include all
    % specified flags and arguments later but for now we will be sure to
    % include the command as it was called. This is why "rawCommandCall" is a
    % reserved arg/flag name.
    
    % Include the command as it was called.
    commandArguments.rawCommandCall = commandCall;    
    
    % We will read the argument and flag configuration for the command. Its ok if either file
    % doesn't exist. But not if it exists and fails to be read.
    if exist([mrootpath,filesep,'commands',filesep,formalCommandName,'.args'],'file'),  argConfigData = mread([mrootpath,filesep,'commands',filesep,formalCommandName,'.args'],'%s %s %s %q %q %q'); else argConfigData = cell(0,6); end
    if exist([mrootpath,filesep,'commands',filesep,formalCommandName,'.flags'],'file'),flagConfigData = mread([mrootpath,filesep,'commands',filesep,formalCommandName,'.flags'],'%s %s %s %s %s %s %q %q %q'); else flagConfigData = cell(0,9); end
    
    % We will cycle through all arguments configured for this command and read them one by one matching them with the specified input until we reach
    % the flag section. We then will check that enough arguments were specified.
    
    % Indicate that we are still in the argument (begining) section of the call.
    inArgumentSection = true;
    
    % Loop over the command arguments.
    for iConfigArgument=1:size(argConfigData,1);
        
        % Find if we are still in the argument section of the call.
        inArgumentSection = (inArgumentSection && ~isempty(commandCall) && (commandCall{1}(1) ~= '-'));
        
        % Check if we are still in the argument section.
        if (inArgumentSection)
            
            % Process and record the raw command input into the appropriate variable to pass to the command.
            commandArguments.(argConfigData{iConfigArgument,1}) = mpreprocess(commandCall(1),argConfigData{iConfigArgument,2});
            
            % Check if the preprocessor returned an empty value. This would indicate that it did not preprocess correctly.
            if isempty(commandArguments.(argConfigData{iConfigArgument,1})), mcommandhelp(commandName); return, end
            
            % Remove this entry from the command input.
            commandCall(1) = [];
            
        else
            
            % We are through the command section. Check if enough arguments were specified. If not notify the user and return.
            if str2double(argConfigData{iConfigArgument,3}) == 1 || any(strcmp(argConfigData{iConfigArgument,3},{'Y','y','Yes','YES','true','True','yes'})), error('MAESTRO:maestro:notEnoughArgs',['Not enough arguments specified to command "',commandName,'".\n',mcommandhelp(commandName)]); end
            
            % Otherwise record the default value for command arguments of this class. By sending the preprocessor a blank argument we are requesting
            % to recieve the default value for this input class.
            commandArguments.(argConfigData{iConfigArgument,1}) = mpreprocess([],argConfigData{iConfigArgument,2});
            
        end
        
    end
    
    % This step is a doosy. We have to cycle through all configured flags and try to match them with the arguments.
    % Let me know if you have any questions about how this step works, its rather complicated. -James
    
    % Record number of flags in configuration.
    nConfigFlags = size(flagConfigData,1);
    
    % Record the max number of groups at zero to initialize.
    usedFlagGroups = zeros(max(str2double(flagConfigData(:,6))),1);
    
    % Loop over the flags.
    for iConfigFlag=1:nConfigFlags
        
        % Record the name of this flag.
        flagName = [flagConfigData{iConfigFlag,3},'/',flagConfigData{iConfigFlag,4}];
        
        % Find matches to the flag values.
        aiFlags = find(strcmp(commandCall,flagConfigData{iConfigFlag,3}) | strcmp(commandCall,flagConfigData{iConfigFlag,4}));

        % Switch over the number of flag matches.
        switch length(aiFlags)
            % If there are no matches record the default value for flags of this type.
            case 0, commandArguments.(flagConfigData{iConfigFlag,1}) = mpreprocess([],flagConfigData{iConfigFlag,2});
            case 1
                
                % There is a match. Delete the flag from the call.
                commandCall(aiFlags) = [];
                
                % Initialize a variable to keep track of the arguments to the flag.
                flagVal = {};
                
                % Loop over the call while we dont reach a new flag.
                while(length(commandCall) >= aiFlags && commandCall{aiFlags}(1) ~= '-')
                    
                    % Record the flag arguments and remove them from the call.
                    flagVal = [flagVal,commandCall{aiFlags}]; %#ok<AGROW>
                    commandCall(aiFlags) = [];
                    
                end
                
                % Check the number of arguments. Here are the rules...
                %
                %   Integer >= 0: Num args must match
                %   Inf: Any number allowed
                %   -1: Any number but 0
                %   -2: 0 or 1
                
                % Record the number of actual flags and the number of required flags.
                numActual = length(flagVal);
                numRequired = str2double(flagConfigData{iConfigFlag,5});
                
                % Ensure that these rules have been followed.
                if(~isinf(numRequired) && numRequired >= 0)
                    
                    % In this case the numbers should match.
                    if numRequired ~= numActual, error('MAESTRO:maesto:wrongArgNum',['Wrong number of arguments specified for flag "',flagName,'".\n',mcommandhelp(commandName)]); end
                    
                elseif(numRequired == -1)
                    
                    % In this case we should have at least one flag.
                    if ~numActual, error('MAESTRO:maestro:wrongArgNum',['Wrong number of arguments specified for flag "',flagName,'".\n',mcommandhelp(commandName)]); end
                    
                elseif(numRequired == -2)
                    % In this case we should have 0 or 1 flags.
                    if(~any(numActual == [0,1])), error('MAESTRO:maestro:wrongArgNum',['Wrong number of arguments specified for flag "',flagName,'".\n',mcommandhelp(commandName)]); end
                end
                
                % Preprocess the raw input string.
                flagVal = mpreprocess(flagVal,flagConfigData{iConfigFlag,2});
                
                % Make sure the preprocessing was succesful for this value.
                if isempty(flagVal), mcommandhelp(commandName); return, end
                
                % Record flag values to pass to the command.
                commandArguments.(flagConfigData{iConfigFlag,1}) = flagVal;
                
                % Check if groups are being used here.
                if(str2double(flagConfigData{iConfigFlag,6}))
                    
                    % Check if duplicate flag groups were used.
                    if(usedFlagGroups(str2double(flagConfigData{iConfigFlag,6})))
                        
                        % Notify the user that too many flags from the group have been used.
                        error('MAESTRO:maestro:tooManyFlagsFromGroup',['More than one flag of same type were specified.\n',mcommandhelp(commandName)]);
                        
                    else
                        
                        % Mark that flag as in use.
                        usedFlagGroups(str2double(flagConfigData{iConfigFlag,6})) = true;
                        
                    end
                end
                
            otherwise
                
                % More than one of the same flag appeared.
                error('MAESTRO:maestro:multiFlagUse',['Repeated use of flag "',flagName,'".\n',mcommandhelp(commandName)]);
        end
        
    end
    
    % Check if all groups were used.
    if(~all(usedFlagGroups))
        
        % Notify the user if not all flags were used.
        error('MAESTRO:maestro:notAllFlags',['Not all necessary flag types were used.\n',mcommandhelp(commandName)]);
        
    end
    
    % Execute the command.
    feval(str2func(formalCommandName),commandArguments);
    
    
    
    
catch ME
    % If an error occurs we will be dropped off here
    
    if mdebugmode,  rethrow(ME); end
    
    % Create a fake ME structure with an empty stack so that the user isn't
    % overwelmed with
    fprintf('\n');
    newME.identified = ME.identifier;
    newME.message = ME.message;
    newME.stack = struct('file','Maestro','name','Maestro','line',0);
    error(newME);       
    
end

    function cleanupfunction, clear all; end
end