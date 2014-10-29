function lc = mwqedload(filename)
    
    
    fid = fopen(filename);
    
    
    line = textscan(fid,'%s','delimiter','\n');    
    
    for i=1:length(line{1})
        %a = regexp(line{1}{i},'#Bjed','match');

        %if(~length(a))	

            bjed = regexp(line{1}{i},'24\d\d\d\d\d\.\d*','match');
            if(~isempty(bjed))	    
	      
	      

              bjed = str2double(bjed{1});

	      if bjed > 0

		 
		 
		 if line{1}{i}(2) == 'I'
		    continue
		 end
		break


	      end
            end
        %end



    end
    fclose(fid);
    fid = fopen(filename);    
    
    data = textscan(fid','%n %n','commentStyle','#','collectOutput',true);
    lc = data{1};
    lc(:,1) = lc(:,1)/86400+bjed;
   
    fclose(fid);
                
    
end
