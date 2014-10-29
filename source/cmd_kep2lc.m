function cmd_kep2lc(args)	 
  for File=FILE(args.FileNames)
    data = fitsread(File.FullName,'BinTable');
    x = data{1};
    y = data{4};
    
    x(isnan(y)) = [];
    y(isnan(y)) = [];
    
    y = y/median(y);

    y = y - 1;
    
    bi = abs(y/mrobuststd(y)) > 5;
    
    x(bi) = [];
    y(bi) = [];

    x = x + 2454833;    
    x0 = min(x);         
    x = (x - x0)*86400;
    [~,outFileName] = fileparts(File.FullName);    
    fid = fopen([outFileName,'.lc'],'w');
    fprintf(fid,'# Bjed = %.15f\n',x0);
    for i=1:length(x)
	fprintf(fid,'%.2f\t%.8f\n',x(i),y(i));
    end
    fclose(fid);        
%    keyboard
%    break
  end	  
end
