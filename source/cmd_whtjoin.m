function cmd_whtjoin(args)

Files = FILE(args.filesIn{1});

pid = mprocessinit('\nJoining WHT Files... ');
for i=1:length(Files)    
    fi = fitsinfo(Files(i).FullName);
    header = fi.PrimaryData.Keywords;    
       
    for j=1:length(fi.Contents)-1
         data{j} = fitsread(Files(i).FullName,'Image',j);         %#ok<AGROW>
    end    
    
    if length(fi.Contents) == 5
    
    im = zeros(2*100,2*100);
    im(1:100,1:100) = data{1}(1:100,1:100);
    im(101:200,1:100) = data{2}(1:100,1:100);
    im(1:100,101:200) = data{3}(1:100,1:100);
    im(101:200,101:200) = data{4}(1:100,1:100);
    else
        im = data{1};
        
    end
    
    [a,b,c] = fileparts(Files(i).FullName);    
    fitswrite(im,[a,filesep,b,'_joined',c],header);
    mprocessupdate(pid,i/length(Files));
end
mprocessfinish(pid,1);
fprintf('\n\n');



end