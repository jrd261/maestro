function directive_companion_find(args)

  timeSeriesData = []
  timeSeriesFiles = FILE(args.timeSeriesFiles)
  for i=1:length(args.timeSeriesFiles)
    timeSeriesData = [timeSeriesData;str2double(mloadtimeseries(timeSeriesFiles(i).FullName))];
  end
  [~,so] = sort(timeSeriesData(:,1));
  timeSeriesData = timeSeriesData(so,:);

  N1 = 8;
  N2 = 1000;


  binaryPeriods = timeSeriesData(end,1)
  
  binaryFrequencies = 1/N1




