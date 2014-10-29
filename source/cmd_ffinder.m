function cmd_ffinder(args)

timeFactor = 1;
frequencyMin = 0;
frequencyMax = Inf;
minSNLevel = 8;
maxModes = 100;
outFileName = ['frequencies_',datestr(now,'yyyymmddMMHHSSFFF')];

if ~isempty(args.timeFactor), timeFactor = args.timeFactor; end
if ~isempty(args.fRange), frequencyMin = args.fRange(1); frequencyMax = args.fRange(2); end
if ~isempty(args.fMin), frequencyMin = args.fMin; end
if ~isempty(args.fMax), frequencyMax = args.fMax; end
if ~isempty(args.snLevel), minSNLevel = args.snLevel; end
if ~isempty(args.maxModes), maxModes = args.maxModes; end
if ~isempty(args.outFileName), outFileName = args.outFileName{1}; end

data = mread(args.lcFileName{1});

x = str2double(data(:,1)); x = (x - mean(x))*timeFactor;
y = str2double(data(:,2));

A = []; dA = [];
F = []; dF = [];
T = []; dT = [];


for iFit = 1:maxModes

    xx = x;
    yy = y;
        
    for iMode=1:length(A)        
        yy = yy - A(iMode)*sin(2*pi*F(iMode)*(xx-T(iMode)));                        
    end

    [f,a] = mfastperiodogram(xx,yy,10,10);

    a = a(f>frequencyMin & f<frequencyMax);
    f = f(f>frequencyMin & f<frequencyMax);
    
    noiseLevel = median(a(:));
    
    [newA,iIndex] = max(a);
    newF = f(iIndex);
    
    if newA/noiseLevel <  minSNLevel,  break; end
          
    [A,dA,F,dF,T,dT] = mnlinsinfit(x,y,[F;newF]);    
              
    mtalk([num2str(iFit),':\tSN=',num2str(newA/noiseLevel),'\tA=',num2str(A(iFit)),'\tF=',num2str(F(iFit)),'\tP=',num2str(1/F(iFit)),'\n']);
    
end
  
fid = fopen(outFileName,'w');
for i = 1:length(F)
  fprintf(fid,num2str(F(i),'%.15E'));
  fprintf(fid,'\t');
  fprintf(fid,num2str(dF(i),'%.15E'));
  fprintf(fid,'\t');        
  fprintf(fid,num2str(A(i),'%.15E'));
  fprintf(fid,'\t');
  fprintf(fid,num2str(dA(i),'%.15E'));
  fprintf(fid,'\n');                                  
end    

end

