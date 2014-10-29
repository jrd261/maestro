function cmd_fastdft(args)
%CMD_FASTDFT is the MAESTRO command to take the fast periodogram of data.
%   CMD_FASTDFT(ARGS) will calculate the fast periodogram of a data set and
%   write it to disk/plot it.
%
%   Copyright (C) 2009-2011 James Dalessio

%% READ IN THE DATA
% Read in the data using mread. We will assert it has two columns.
data = str2double(mread(args.fileName{1}));  
assert(size(data,2) > 1,'MAESTRO:cmd_fastdft:oneCol','Error: The data is not properly formatted.');

%% COMPUTE THE PERIODOGRAM
[f,a] = mfastperiodogram(data(:,1),data(:,2));

%% WRITE TO FILE
if ~isempty(args.outFileName)        
    out = [f,a]; %#ok<NASGU>
    save(args.outFileName{1},'out','-ASCII');
end

%% WRITE TO PROMPT
if args.writeOut
    for i=1:length(f)
        fprintf('%f %f\n',f(i),a(i));
    end    
end

%% MAKE A PLOT
if args.makePlot
    plot(f,a);       
    xlabel('Frequency')
    ylabel('Amplitude')
end

end