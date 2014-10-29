function cmd_meldh(args)

Files = FILE(args.inFile{1},'allowdirectories',false);
data = cell(length(Files),1);
totalWidth = 0;
maxLength = 0;
for iFile = 1:length(Files)
    data{iFile} = mread(Files(iFile).FullName);    
    totalWidth = totalWidth + size(data{iFile},2);
    if size(data{iFile},1) > maxLength, maxLength = size(data{iFile},1); end
end

newData = cell(maxLength,totalWidth);
hPos = 1;

for iFile = 1:length(data)  
    

    newData(1:size(data{iFile},1),hPos:hPos+size(data{iFile},2)-1) = data{iFile};       
    hPos = hPos + size(data{iFile},2);
end

if(any(cellfun(@(x) isempty(x), newData(:))))
    newData(cellfun(@(x) isempty(x), newData)) = {''};
end


outFile = FILE(args.outFile{1});
fid = outFile.open('w');
for i=1:size(newData,1)
    for j=1:size(newData,2)
        fprintf(fid,newData{i,j});
        fprintf(fid,'\t');
    end
    fprintf(fid,'\n');
end


end

