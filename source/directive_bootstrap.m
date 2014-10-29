function directive_bootstrap(args)


  if isempty(args.MinimumFrequency), args.MinimumFrequency = 0; end
  if isempty(args.MaximumFrequency), args.MaximumFrequency = Inf; end
  if isempty(args.MinimumSignalToNoise), args.MinimumSignalToNoise = 8; end
  if isempty(args.MaximumNumberModes), args.MaximumNumberModes = Inf; end


  % CREATE OUTPUT DIRECTORY
  if isempty(args.OutputDirectoryName), 
    args.OutputDirectoryName = {['bootstrap_',datestr(now,'yyyy-mm-ddTHH:MM:SS.FFF')]};
  end
  mkdir(args.OutputDirectoryName{1})
  OutputDirectory = FILE(args.OutputDirectoryName{1});
  
  % LOAD IN TIME SERIES
  pid = mprocessinit('\nReading in time series files...');
  TimeSeriesFiles = FILE(args.TimeSeriesFileNames,'allowdirectories',false);
  TimeSeriesData = cell(size(TimeSeriesFiles));
  for i = 1:length(TimeSeriesFiles)
    if any(strcmp(TimeSeriesFiles(i).Ext,{'.lc','.lc1'}))
      TimeSeriesData{i} = mwqedload(TimeSeriesFiles(i).FullName);
      TimeSeriesData{i}(:,1) = (TimeSeriesData{i}(:,1)-2450000)*86400;
    else
      TimeSeriesData{i} = str2double(mread(TimeSeriesFiles(i).FullName));
    end
    mprocessupdate(pid,i/length(TimeSeriesFiles))
  end
  mprocessfinish(pid,true);

  % DETERMINE INDEX OF FILE TO BEGIN WITH
  if ~isempty(args.StartingFileIndex)
     i = args.StartingFileIndex;
  else    
    [~,i] = max(cellfun(@(x) length(x),TimeSeriesData));
  end


  % CREATE FILELIST 
  OutputFileListFID = fopen([OutputDirectory.FullName,filesep,'filelist'],'w');
  fprintf(OutputFileListFID,[TimeSeriesFiles(i).FullName,'\n']); 

  TableFID = fopen([OutputDirectory.FullName,filesep,'table'],'w');


  mtalk(['\n\nFile "',TimeSeriesFiles(i).Name,'" will be the first file used in the bootstrapping process.']);


  UsedFiles = TimeSeriesFiles(i);
  X = TimeSeriesData{i}(:,1); X0 = mean(X); X = X - X0;
  Y = TimeSeriesData{i}(:,2);
  TimeSeriesData(i) = [];
  TimeSeriesFiles(i) = [];


  for i=1:length(TimeSeriesData)      
      TimeSeriesData{i}(:,1) = TimeSeriesData{i}(:,1) - X0;      
  end



  if isempty(args.FrequencyFileName)

    A = [];
    dA = [];
    F = [];
    dF = [];
    T = [];
    dT = [];


    mtalk('\nIdentifying modes in time series from first file...');
    for i = 1:args.MaximumNumberModes    
      XX = X;
      YY = Y;        
      for j=1:length(F)        
        YY = YY - A(j)*sin(2*pi*F(j)*(XX-T(j)));                        
      end    
      [FF,AA] = mfastperiodogram(XX,YY);    
      AA = AA(FF>args.MinimumFrequency & FF<args.MaximumFrequency);
      FF = FF(FF>args.MinimumFrequency & FF<args.MaximumFrequency);    
      N = median(AA(:));    
      [S,k] = max(AA);FF_0 = FF(k);    
      if S/N < args.MinimumSignalToNoise, break; end    


      [A,dA,F,dF,T,dT] = mnlinsinfit(X,Y,[F;FF_0]);   
      



      mtalk(['\n',num2str(i,'%i'),':\tS/N=',num2str(S/N,'%.2f'),'\tA=',num2str(A(i)),'\tF=',num2str(F(i)),'\tP=',num2str(1/F(i))]);    
    end

    mtalk('\n');

  else

    data = str2double(mread(args.FrequencyFileName));
    F = data(:,1);

  end

  if isempty(F)
     mtalk('\n\nNo modes found in data!\n\n');
     return
  end


  FrequencySBSFileFID = fopen([OutputDirectory.FullName,filesep,'frequencies_step_by_step'],'w');
  CycleCountErrorFID = fopen([OutputDirectory.FullName,filesep,'cycle_count_error'],'w');    
  %ReportFID = fopen([OutputDirectory.FullName,filesep,'report'],'w');
  
  q = 1;
  while(~isempty(TimeSeriesData))

   % CurrentFiles = Time

    pid = mprocessinit('\nFitting frequencies to current time series...');
    F_old = F;

    [A,dA,F,dF,T,dT] = mnlinsinfit(X,Y,F,true); 

%    [A2,dA2,F2,dF2,T2,dT2] = mnlinsinfit(X,Y,F,true);    

 %   keyboard


    for i=1:length(F)
      %[FS,dFS] = msigfig(F(i),dF(i));
	
      fprintf(FrequencySBSFileFID,[num2str(F(i),'%.15E'),'\t',num2str(dF(i),'%.15E'),'\t']);
    end
    fprintf(FrequencySBSFileFID,'\n');
    
    mprocessfinish(pid,true);

    [DX,i] = min(min(abs([max(X)  - cellfun(@(c) min(c(:,1)),TimeSeriesData);min(X) - cellfun(@(c) max(c(:,1)),TimeSeriesData)])));

    
    
    for k=1:length(F)
	cc{k,q} = num2str(dF(k).*DX);
    end
%    fprintf(CycleCountErrorFID,'\n');
    fprintf(OutputFileListFID,[TimeSeriesFiles(i).FullName,'\n']);
   

    mtalk(['\nAdding file "',TimeSeriesFiles(i).Name,'".']);

    X = [X;TimeSeriesData{i}(:,1)];
    Y = [Y;TimeSeriesData{i}(:,2)];
    TimeSeriesData(i) = [];
    TimeSeriesFiles(i) = [];    
    q = q + 1;
  end

  for i=1:size(cc,1)
    for j=1:size(cc,2)
	fprintf(CycleCountErrorFID,[cc{i,j},'\t']);
    end     
    fprintf(CycleCountErrorFID,'\n')
  end

  
  fid = fopen([OutputDirectory.FullName,filesep,'frequencies'],'w');
  for i = 1:length(F)
        
%    [s1,s2,s3,s4] = msigfig(F(i),dF(i));
%    [ss1,ss2,s3,s4] = msigfig(F(i)*1E6,dF(i)*1E6);


%    fprintf(TableFID,' & ')
%    fprintf(TableFID,s3);
%    fprintf(TableFID,' & ');
%    fprintf(TableFID,s4);
%    fprintf(TableFID,' \\\\\n');




    fprintf(fid,num2str(F(i),'%.15E'));
    fprintf(fid,'\t');      
    fprintf(fid,num2str(dF(i),'%.15E'));
    fprintf(fid,'\t');
    fprintf(fid,'\n');
                                   
  end
    
  fclose('all');


  

end
