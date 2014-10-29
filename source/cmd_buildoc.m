function cmd_buildoc(args)
%CMD_BUILDOC Builds an O-C from a series of lightcurves and frequencies
%   CMD_BUILDOC(args) will linearly fit sinusoids at the specified
%   frequencys assuming a zero time of JD=2450000 and write out a Maestro
%   O-C file (*.moc) containing the information.
%
%   Copyright (C) 2007-2011 James Dalessio

% Set the zero time. This is Jan 1, 2000 at midnight.
%offset = 2451544.500000;

% Fitting sinusoids can spawn warnings. Lets turn them all off.
%warning off all
%mtalk('\n\nBuilding an O-C');

% Load in freq data from the given file.
%pid = mprocessinit(['\n Loading in frequencies from file "',args.freqFileName{1},'"...']);
%Fs = mread(args.freqFileName{1},'%s');
%F = zeros(size(Fs));
%for i=1:length(F), F(i) = eval(Fs{i}); end
%mprocessfinish(pid,1);
%mtalk(['\n ',num2str(length(F)),' frequencies to be used.']);

% Load in file data files and fit data


pid = mprocessinit('\n Loading frequency data...');
FrequencyFile = FILE(args.FrequencyFileName{1},'allowdirectories',false,'forceexistence',true,'forcenonempty',true);
data = mread(FrequencyFile.FullName);
FrequencyData = str2double(data(:,1));
mprocessfinish(pid,true);

pid = mprocessinit('\n Loading time series files...');
TimeSeriesFiles = FILE(args.TimeSeriesFileNames{1},'allowdirectories',false);
TimeSeriesData = cell(size(TimeSeriesFiles));
for i=1:length(TimeSeriesFiles)
    TimeSeriesData{i} = mloadtimeseries(TimeSeriesFiles(i).FullName);
    mprocessupdate(pid,i/length(TimeSeriesFiles));
end
mprocessfinish(pid,true);

pid = mprocessinit('\n Sorting files...');
[~,aiSortOrder] = sort(cellfun(@(x) mean(x(:,1)),TimeSeriesData));
TimeSeriesData = TimeSeriesData(aiSortOrder);
TimeSeriesFiles = TimeSeriesFiles(aiSortOrder);
mprocessfinish(pid,true);

pid = mprocessinit('\n Normalizing times...');
X0 = mean(cellfun(@(x) mean(x(:,1)),TimeSeriesData));
for i=1:length(TimeSeriesFiles)
    TimeSeriesData{i}(:,1) = (TimeSeriesData{i}(:,1) - X0)*86400;
end
mprocessfinish(pid,true);


Model = mgetmodel('linsinpar');
pid = mprocessinit('\n Calculating O-C...');
AmplitudeData = zeros(length(TimeSeriesData),length(FrequencyData));
AmplitudeErrorData = zeros(length(TimeSeriesData),length(FrequencyData));
PhaseData = zeros(length(TimeSeriesData),length(FrequencyData));
PhaseErrorData = zeros(length(TimeSeriesData),length(FrequencyData));
for i=1:length(TimeSeriesFiles)
 [AmplitudeData(i,:),AmplitudeErrorData(i,:),PhaseData(i,:),PhaseErrorData(i,:)] = mlinsinfit(TimeSeriesData{i}(:,1),TimeSeriesData{i}(:,2),FrequencyData(:,1));
    

  mprocessupdate(pid,i/length(TimeSeriesFiles));
end
mprocessfinish(pid,true);

TimeData = cellfun(@(x) mean(x(:,1)),TimeSeriesData);


fidoc = fopen('oc','w');
fidam = fopen('amp','w');

TimeData = TimeData/86400 + X0;
for i=1:size(PhaseData,1)

    fprintf(fidoc,[num2str(TimeData(i),'%.15E')]);
    fprintf(fidam,[num2str(TimeData(i),'%.15E')]);
    for j=1:size(PhaseData,2)
	fprintf(fidoc,['\t',num2str(PhaseData(i,j),'%.10E'),'\t',num2str(PhaseErrorData(i,j),'%.10E'),'\t']);
	fprintf(fidam,['\t',num2str(AmplitudeData(i,j),'%.10E'),'\t',num2str(AmplitudeErrorData(i,j),'%.10E'),'\t']);
    end
    fprintf(fidoc,'\n');
    fprintf(fidam,'\n');

end


