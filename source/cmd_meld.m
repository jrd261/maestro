function cmd_meld(args)

if length(args.rawCommandCall) < 2
    mtalk('\n\nAt least two arguments are required.');
end

Files = FILE(args.rawCommandCall(1:length(args.rawCommandCall)-1));
data = cell(length(Files),1);

l = 0;
w = 0;

for iFile = 1:length(Files)    
    data{iFile} = mread(Files(iFile).FullName);
    l = l + size(data{iFile},1);
    w = max(w,size(data{iFile},2));
    
end


j = 1;
out = cell(l,w);
for iFile = 1:length(Files)
    
    out(j:j+size(data{iFile},1)-1,1:size(data{iFile},2)) = data{iFile};
    j = j + size(data{iFile},1);
    
    
end


%if(any(cellfun(@(x) isempty(x), newData(:))))
%    newData(cellfun(@(x) isempty(x), newData)) = {''};
%end
% callSoapService('http://cdsws.u-strasbg.fr/axis/services/Sesame','sesame',createSoapMessage('urn:Sesame','sesame',{'ec20058-5234','x'},{'name','resultType'}))

outFile = FILE(args.rawCommandCall{length(args.rawCommandCall)});
fid = outFile.open('w');
for i=1:size(out,1)
    for j=1:size(out,2)
        fprintf(fid,'%s',out{i,j});
        fprintf(fid,'\t');
    end
    fprintf(fid,'\n');
end


end

