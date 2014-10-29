function cmd_command(args)
%CMD_COMMAND displays detailed information about the specified command.
%   CMD_COMMAND(ARGS) displays command information if the command exists. The only argument to this command if the name of the target command.
%
%   See also CMD_SYNTAX CMD_HELP CMD_COMMANDS
%
%   Copyright (C) 2009-2010 James Dalessio

% Load in the command list.
commandList = mcommandlist;

% Begin a loop over all command aliases.
for iCommand = 1:size(commandList,1)
        
    % See if the command alias matches.
    if any(strcmp(commandList{iCommand,2},args.COMMAND_NAME{1})), break, end
            
    % If we've reached this point no commands matched.
    if iCommand == size(commandList,1), error('MAESTRO:cmd_command:noMatch',['The specified command "',args.COMMAND_NAME{1},'" does not exist. Type "help commands" for a list of valid commands.']); end
    
end

% Rip command information.
commandData = commandList(iCommand,:);

% We will read the argument and flag configuration for the command. Its ok if either file 
% doesn't exist. But not if it exists and fails to be read.    
if exist([mrootpath,filesep,'commands',filesep,commandData{1},'.args'],'file'), argConfigData = mread([mrootpath,filesep,'commands',filesep,commandData{1},'.args'],'%s %s %s %q %q %q'); else argConfigData = cell(0,6); end        
if exist([mrootpath,filesep,'commands',filesep,commandData{1},'.flags'],'file'), flagConfigData = mread([mrootpath,filesep,'commands',filesep,commandData{1},'.flags'],'%s %s %s %s %s %s %q %q %q'); else flagConfigData = cell(0,9); end                
if exist([mrootpath,filesep,'commands',filesep,commandData{1},'.help'],'file'), helpText = mread([mrootpath,filesep,'commands',filesep,commandData{1},'.help'],'%q'); helpText = helpText{1}; else helpText = 'No detailed description available.'; end

% Display the name of the command, the aliases, and the description.
mtalk('\n[ '); for iAlias=1:length(commandData{2}), mtalk([commandData{2}{iAlias},'/']);  end 
mtalk('\b ]  ');
mtalk(commandData{3});
mtalk(['\n\n',helpText]);

% Begin to cycle over arguments to the command.
for iArgument = 1:size(argConfigData,1)
    mtalk(['\n\nArgument ',num2str(iArgument),' "',argConfigData{iArgument,4},'"']); 
    mtalk(['\nClass: ',mclasstype(argConfigData{iArgument,2})]);
    mtalk('\nRequired: ');
    if mstring2bool(argConfigData{iArgument,3}), mtalk('YES'); else mtalk('NO'); end
    mtalk(['\nDescription: ',argConfigData{iArgument,5}]);          
end

% Begin to cycle over the flags to the command.
for iFlag = 1:size(flagConfigData,1)
    mtalk(['\n\nFlag "',flagConfigData{iFlag,3},'/',flagConfigData{iFlag,4},'" ',flagConfigData{iFlag,7}]);
    mtalk(['\nClass: ',mclasstype(flagConfigData{iFlag,2})]);
    mtalk('\nNumber of Arguments: ');
    switch str2double(flagConfigData{iFlag,5})
        case inf
            mtalk('Any');
        case -1
            mtalk('At least 1');
        case -2
            mtalk('0 or 1');
        otherwise
            mtalk(num2str(flagConfigData{iFlag,5}));
      
    end
    mtalk('\nGroup: ');
    if str2double(flagConfigData{iFlag,6}), mtalk(flagConfigData{iFlag,6}); else mtalk('0 (NOT REQUIRED)'); end
    mtalk(['\nDecription: ',flagConfigData{iFlag,8}]);

end


mtalk('\n\n');


