function cmd_kepred(args)



fileName = mrelpath(args.fileName{1},pwd);

if ~isempty(args.nPixels), nPixels = args.nPixels(1); else nPixels = 4; end


data = fitsread(fileName,'BinTable');
info = fitsinfo(fileName);



key = info.BinaryTable.Keywords;

bjed = key{strcmp(key(:,1),'BJDREFI'),2};


times = data{1};
signal = data{5};

[junk,order] = sort(nansum(signal,1),2,'descend'); %#ok<ASGLU>

signal = sum(signal(:,order(1:nPixels)),2);
times(isnan(signal)) = [];
signal(isnan(signal)) = [];



bjed = bjed + min(times);
times = times-min(times);
times = times*86400;


fid = fopen(args.outName{1},'w');
fprintf(fid,'#Bjed = ');
fprintf(fid,num2str(bjed,'%10.10f'));
fprintf(fid,'\n');
pid = mprocessinit('\n Creating lightcurve...');
for iLine = 1:length(times)
    fprintf(fid,[num2str(times(iLine)),'\t',num2str(signal(iLine)),'\n']) ;   
    mprocessupdate(pid,iLine/length(times));
end
mprocessfinish(pid,1);
mtalk('\n\n');
fclose(fid);









end

