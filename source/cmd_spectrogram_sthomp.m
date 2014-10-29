function cmd_spectrogram_sthomp(args)
%CMD_STHOMP_SPECTROGRAM is a MAESTRO command to generate a spectrogram from
%an ascii file.
%
%   CMD_STHOMP_SPECTROGRAM(ARGS) Will calculate a spectrogram and create
%   some pretty pictures. 
%   
%   Originally by Susan Thompson. Made into a Maestro command by James
%   Dalessio (2010/02/13)


data = readinfile(args.inFileName{1},0);




%
tic
% Sort the data by time and normalize t=0.
[junk,aiSortOrder] = sort(data(:,1)); %#ok<ASGLU>
data(:,1) = data(aiSortOrder,1);
data(:,2) = data(aiSortOrder,2);
data(:,1) = data(:,1)-data(1,1);
[junk,aiUnique] = unique(data(:,1));
data(:,2) = data(aiSortOrder,2);
data(:,1) = data(:,1)-data(1,1);
toc

tic
%Check to see if the time base for each running FT was specified. If
% it was specified use the given value, if not just use 1/8 of the total
% run length.
if isempty(args.fftBinSize), args.fftBinSize = (max(data(:,1))-min(data(:,1)))/8; end
len=args.fftBinSize;

dtime=median(data(2:size(data,1))-data(1:size(data,1)-1));  %Approximate time spacing of file in seconds.
args.timeRange
if isempty(args.timeRange), args.timeRange = [0,max(data(:,1))]; end
if isempty(args.freqRange), args.freqRange = [1/max(data(:,1)),1/dtime/2]; end
        
%plotting parameters
x1=args.timeRange(1);  %Starting and Ending Times in days.
x2=args.timeRange(2);
y1=args.freqRange(1); %Starting and ending frequencies
y2=args.freqRange(2);  %microHz.
toc

oversamp=10;  %oversampling factor

num=floor(len/dtime);
dnum=floor(num-.05*num);
tic
%Uncomment next line to get fake sine curve
%data(:,2)=.05*sin(2*pi*.002*data(:,1));
[t,d]=pad_zeros(data,dtime*2);
[junk,aiUnique] = unique(t);
t = t(aiUnique);
d = d(aiUnique);
toc
hold off;
tic
'r'
%resample data.
newt=t(1):dtime:t(length(t));
newd=pchip(t,d,newt);

freq=y1:1/(len*oversamp):y2;
toc
tic
fprintf('\n Building spectrogram...');
[S,F,T,P] = spectrogram(newd,num,dnum,freq,1/dtime);
toc
tic
fprintf('\n Building normalization for spectrogram... ');
[wS,wF,wT,wP,wN]=window_spgm(data(:,1),dtime,num,dnum,.0001,len*oversamp);
toc
%Normalize spectrogram with window_spgm
sz=size(P);
length(wN);
for i=1:sz(1) %loop over frequencies
    for j=1:sz(2) %loop over time
        P(i,j)=(P(i,j)^(1/2))/wN(j);
    end
end

%Normalize spectrogram window with window_spgm
sz=size(wP);
length(wN);
for i=1:sz(1) %loop over frequencies
    for j=1:sz(2) %loop over time
        wP(i,j)=(wP(i,j)^(1/2))/wN(j);
    end
end

%Create plots
%subplot(4,1,[1 3]);
subplot(7,1,[1 5]);
surf(T/(3600*24),F*1000000,P,'edgecolor','interp');
view(0,90);
%title (title_words);

xlim([x1/86400 x2/86400]);
ylim([y1*1E6 y2*1E6]);
%zlim([0 .08]);

colorbar;
ylabel('\mu Hz');
%subplot(4,1,4);
subplot(7,1,[6 7]);
surf(wT/(3600*24),wF*1000000,wP,'edgecolor','interp');
view(0,90);
colorbar;
dfr=y2-y1; %frequency range of original graph.
xlim([x1/86400 x2/86400]);
ylim([1000-dfr/5.5*1E6,1000+dfr/5.5*1E6]);
xlabel('Time');

if ~isempty(args.outFilename{1})
    print('-dpng',args.outFileName{1})
end

end

function [px,py]=pad_zeros(data,dt)
%pad an array with zeros
%If the gap in x is greater than the specified dt..
%Then create new points between those points of zeros at interval dt.
%data is an array with two columns.

%Sort by first column of data. ascending
[sd,sin]=sort(data(:,1));

%Use those indexes to create sorted x and y.
x=zeros(length(sin),1);
y=zeros(length(sin),1);

for i=1:length(sin)
    x(i)=data(sin(i),1);
    y(i)=data(sin(i),2);
end

%Go through and look for differences larger than dt.
%Created padded arrays px and py
px(1)=x(1);
py(1)=y(1);

for i=1:length(x)-1
    diff=x(i+1)-x(i);
    newx=[];
    newy=[];
    if (diff > dt)
        newx=x(i)+dt:dt:x(i+1)-dt*.1; %Made non-inclusive (ugly);
        newy=zeros(1,length(newx));
        px=[px newx];
        py=[py newy];
    end
    px(length(px)+1)=x(i+1);
    py(length(py)+1)=y(i+1);
end
end


function [S,F,T,P,N] = window_spgm(t,dtime,num,dnum,dfreq,res)
%Create a single peak at 1000muHz using spectrogram amp=1.
%evenly spaced and padded with zeros using pchip.
%Input is time and the evenly spaced times.
%The rest are the same values you put into your spectrogram.
%dfreq is the half length from 1000m

%Only need a frequency range based on res, the length of one lc
freq=[0.001-dfreq:1/(res):.001-1/res .001 .001+1/res:1/res:.001+dfreq];

rawdat(:,2)=1*sin(2*pi*.001*t+0);
rawdat(:,1)=t;

%Pad with zeros.
[nt,nd]=pad_zeros(rawdat,dtime*2);  %Note *2 might need changing.

%adjust overlapping time points.
diff=double(zeros(length(t)-1,1));
for i=1:length(nt)-1
    diff(i)=nt(i+1)-nt(i);
    if (diff(i) == 0.0)
        nt(i+1)=nt(i)+dtime/1000;
    end
end

%Interpolate between points on even grid.
%create the evenly spaced times.
newt=t(1):dtime:t(length(t));
dat=pchip(nt,nd,newt);


fprintf('%d\n',num);
fprintf('%d\n',dnum);
%Take the Spectrogram.
[S,F,T,P] = spectrogram(dat,num,dnum,freq,1/dtime);

%This returns raw with no normalization done.
%So this can be used to normalize your outputs.
prevdiff=999;
for i=1:length(F)
    diff=abs(F(i)-.001);
    if (diff < prevdiff)
        myi=i;
        prevdiff=diff;
    end
end

sz=size(P);
for k=1:sz(2)
    N(k)=P(myi,k)^(1/2);
end
end

function [model,header] = readinfile(file,skip)
%Function to read in a data file witha header. It returns a 2d vector of
%the data and the header in a a separate string array.
%This is mostly a copy of matlab's hdrload

% check number and type of arguments
if nargin < 1
  error('Function requires one input argument');
elseif ~ischar(file)
  error('Input must be a string representing a filename');
end

% Open the file.  If this returns a -1, we did not open the file 
fid = fopen(file);
if fid==-1
  error('File not found or permission denied');
end
%Some probably unnecessary initialization.
no_lines=0;
max_line = 0;
ncols = 0;
data = [];

%Get first skip lines.
for i=0:skip
	line = fgetl(fid);
end
if ~ischar(line)
  disp('Warning: file contains no header and no data')
end;
[data, ncols, errmsg, nxtindex] = sscanf(line, '%f');

while (isempty(data)||(nxtindex==1))
  no_lines = no_lines+1;
  max_line = max([max_line, length(line)]);
  % Create unique variable to hold this line of text information.
  % Store the last-read line in this variable.
  eval(['line', num2str(no_lines), '=line;']);
  line = fgetl(fid);
  if ~ischar(line)
    disp('Warning: file contains no data')
    break
  end;
  [data, ncols, errmsg, nxtindex] = sscanf(line, '%d');
 end % while

 %Now read in data.
data = [data; fscanf(fid, '%f')];
fclose(fid);

% Create header output from line information.
header = char(' '*ones(no_lines, max_line));
for i = 1:no_lines
  varname = ['line' num2str(i)];
  % Note that we only assign this line variable to a subset of 
  % this row of the header array.  We thus ensure that the matrix
  % sizes in the assignment are equal. We also consider blank 
  % header lines using the following IF statement.
  if eval(['length(' varname ')~=0'])
     eval(['header(i, 1:length(' varname ')) = ' varname ';']);
  end
end % for
  
% Resize output data, based on the number of columns  
% and the total number of data elements. 
% Since the data was read in row-wise, and 
% MATLAB stores data in columnwise format, we have to reverse the
% size arguments and then transpose the data.  

eval('data = reshape(data, ncols, length(data)/ncols)'';', '');

model=data;

end
