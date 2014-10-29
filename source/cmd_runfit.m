function cmd_runfit(args)


warning off all
mtalk('\n\nPERFORMING RUNNING NONLINEAR FIT');

% Load in freq data
pid = mprocessinit(['\n Loading in frequencies from file "',args.freqFileName{1},'"...']);
F = str2double(mread(args.freqFileName{1},'%s'));
mprocessfinish(pid,1);
mtalk(['\n ',num2str(length(F)),' frequencies to be used.']);

% Load in file data
pid = mprocessinit(['\n Loading in data from file "',args.dataFileName{1},'"...']);
data = str2double(mread(args.dataFileName{1},'%s %s'));
mprocessfinish(pid,1);
mtalk(['\n File has ',num2str(size(data,1)),' data points.']);


pid = mprocessinit('\n Sorting and shifting data...');
X = data(:,1);
Y = data(:,2);
[junk,liSortOrder] = sort(X); %#ok<ASGLU>
X = X(liSortOrder);
Y = Y(liSortOrder);
X = X-X(1);
Y = Y-mean(Y);
mprocessfinish(pid,1);
mtalk(['\n Data spans ',num2str(max(X)),' time units.']);


W = args.timePerBin;
S = args.timeIncrement;
outData = zeros(max(X)/S,1+6*length(F));
mtalk(['\n Using ',num2str(W),' time units per bin.']);
mtalk(['\n using ',num2str(S),' time units between starting point of each bin.']);


pid = mprocessinit('\n Begining fit...');
xMarker = 0;
iIndex = 1;



while(true)
    
    XX = X(X > xMarker & X < xMarker+W);
    YY = Y(X > xMarker & X < xMarker+W);
          
    [A,dA,Fnew,dF,T,dT] = mnlinsinfit_errorestimate(XX,YY,F);
    
    if ~args.fixFreq, F = Fnew; end

    outData(iIndex,1) = mean(XX);
    outData(iIndex,2:6:6*length(F)) = Fnew;
    outData(iIndex,3:6:6*length(F)) = dF;
    outData(iIndex,4:6:6*length(F)) = A;
    outData(iIndex,5:6:6*length(F)) = dA;
    outData(iIndex,6:6:6*length(F)) = T;
    outData(iIndex,7:6:6*length(F)+1) = dT;
   
    
               
    mprocessupdate(pid,iIndex/size(outData,1));
    iIndex = iIndex + 1;
    xMarker = xMarker + S;

    if xMarker + W > max(X), mprocessfinish(pid,1); break; end
                                       
end

outData(outData(:,1)==0,:) = [];

keyboard


end