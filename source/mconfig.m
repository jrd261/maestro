function config = mconfig(action,value)
%MCONFIG Manages the global configuration for MAESTRO
%   CONFIG = MCONFIG will return the currently loaded configuration as a
%   structure. If no configuration is currently loaded the default
%   configuration will be loaded.
%
%   MCONFIG('load') will load the default configuration.
%
%   MCONFIG('load',NAME) will load the configuration specified by NAME
%   ignoring the current configuration.
%
%   MCONFIG('append',NAME) will load the configuration specified by NAME
%   overtop of the current configuration.
%
%   Copyright (C) 2009-2011 James Dalessio

% CONFIG is a structure containing the current locale. If it is empty a
% locale has not yet been loaded.
persistent CONFIG

% First check for the case when no arguments. If there are no arguments
% the user is requesting the current configuration be returned. 
if isempty(CONFIG) && nargin==0, mconfig('load'); config = CONFIG; return, end


if nargin == 0, config = CONFIG; return, end

% Initialize a switch statement to deal with the many ways this function
% can be called.
switch action    
    case{'clear'}
	CONFIG = [];
	config = mconfig;
    case{'load'}
        
        % It was requested to load a configuration. Check if a value was specified
        % for this action. If no value was specified initialize the value
        % portion to 
        if nargin==1, value = {}; end      
        
        % Initialize the persistant variable. This will erase the previous
        % locale (if any).
        CONFIG = struct;                       
         % It was requested to append onto a configuration.
        if ischar(value), value = mstring2cell(value); end
        % Append the default locale onto the action field. Make sure each
        % locale was only specified once.
        value = ['default',value];
                
        % Load in the configuration.
        loadinconfig;              
        
        % Insert some data into the locale.
        CONFIG.LOCALE_NAME = mcell2string(value);
                
    case 'append'
        
        if isempty(CONFIG), mconfig('load'); end
         % It was requested to append onto a configuration.
        if ischar(value), value = mstring2cell(value); end
       % Load in the configuration on top of what we already have.
       loadinconfig;
 
        
        
        
    otherwise
        if isempty(CONFIG), mconfig('load'); mconfig(action,value); end
        CONFIG.(action) = value;
      
        
        
        % Throw an error if none of the actions have been recognized.
     %   error('MAESTRO:mlocale:unknownAction','Unknown action arguement to mlocale.');
     
     
     
end

% Record the current configuration as the ouput value.
config = CONFIG;


    function loadinconfig
         
        
       
        
        
        % Begin a loop to load each locale.
        
        for iConfig = 1:length(value)
            
            
            % Attempt to load in the locale data. Enclose this is a try            
            % catch loop for error reporting.
            try
                if strcmp(value{iConfig},'default')
                    rawData = mread([mrootpath,filesep,'default'],'%s %q');
                else
                    rawData = mread([muserpath,filesep,'config',filesep,value{iConfig}],'%s %q');
                end
            catch ME
                error('MAESTRO:mlocale:badLocale',['Unable to load configuration ',value{iConfig},'. Check that this configuration exists.']);
            end
            
            % Begin loop over all entries in the data.
            for iEntry=1:size(rawData,1)
                
                % Attempt to evaluate each entry.
                CONFIG.(rawData{iEntry,1}) = eval(rawData{iEntry,2});
                
            end
            
        end
        
        
        
    end

end
