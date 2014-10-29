function cmd_commands(args)
%CMD_COMMANDS lists MAESTRO commands
%   CMD_COMMANDS(ARGS) will display a list of commands. There is one optional argument to the command, the "SEARCH_CRITERIA". Command aliases and
%   descriptions will be searched to match the search criteria. 
%
%   See also CMD_COMMAND CMD_SYNTAX CMD_HELP
%
%   Copyright (C) 2009-2010 James Dalessio


% Load up the command list.
commandList = mcommandlist;

% Indicate that all commands will be matched. This will be changed if a search criteria is specified.    
matchIndicies = true(size(commandList,1),1);

% Check if we are to search for a string.
if(~isempty(args.SEARCH_CRITERIA))

    % Make the search criteria all lower case.
    args.SEARCH_CRITERIA{1} = lower(args.SEARCH_CRITERIA{1});
                 
   % Obtain matches to command alias.
    nameMatches = cellfun(@(x) ~isempty(x),cellfun(@(x) strfind(lower(mcell2string(x)),lower(args.SEARCH_CRITERIA{1})),commandList(:,2),'UniformOutput',false));
    
    % Obtain matches to description.
    descriptionMatches = cellfun(@(x) ~isempty(x),strfind(lower(commandList(:,3)),lower(args.SEARCH_CRITERIA{1})));        
    
    % Obtain matches to all.
    matchIndicies = descriptionMatches | nameMatches;
    
end

% Extract the information we will display.
commandData = commandList(matchIndicies,2:3);

% Check if there are any matches.
if(isempty(commandData))
    
    % Let the user no that no matches work.
    mtalk('\nNo commands match search criteria.\n\n');
    
else
    
    % Add a whitespace
    mtalk('\n');
    
    % Loop over all matching commands.
    for iCommand = 1:size(commandData,1)
        
        % Extract alias text.
        aliasNames = commandData{iCommand,1}; mtalk('[ ');
                        
        % Loop over aliases.
        for iAlias = 1:length(aliasNames), mtalk([aliasNames{iAlias},'/']); end
                                                                  
        % Insert description and some formattng markups.
        mtalk(['\b ]  ',commandData{iCommand,2},'\n']);
        
    end
    
    % Add two spaces.  
    mtalk('\nFor help with a specific command type "maestro command <command name>".\n\n');
        
end