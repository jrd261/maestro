function cmd_lcconvert(args)

    if isempty(args.lcFileName)
        
        args.lcFileName = './*.lc1';
        
    end
        
    lcFiles = FILE(args.lcFileName,'allowdirectories',false,'forcenonempty',true,'forceexistence',true);
    
    
    
    for file = lcFiles
        [path_,name_,ext_] = fileparts(file.FullName);
        
 
        
        [data,header] = mread(file.FullName);
        
        if ~any(strcmp(header(:,1),'Bjed'))
            continue
            
        end
        
        data = str2double(data);
        
        data(:,1) = data(:,1)/86400 + str2double(header(strcmp(header(:,1),'Bjed'),2));
        
        if args.doConvertToMagnitudes
            wqedfile = FILE([path_,filesep,name_,'.wq'],'forceexistence',true);
            wdata = str2double(mread(wqedfile(1).FullName));
            V = wdata(:,str2double(ext_(4))+1);
            
            
            
            if isempty(args.wqedChannels)
                V(V==0) = [];                                
                data(:,2) = -2.5*log10((data(:,2) - median(data(:,2)) + 1)*median(V));   
                t = '_mag';
                if args.doNormalize
                    data(:,2) = data(:,2) - median(data(:,2));
                    t = '_mag_norm';
                end             
            else
                
                C = sum(wdata(:,args.wqedChannels+1),2);    
                
                R = V./C;
                R(R==0) = [];
                R(isnan(R)) = [];                               
                R = median(R);
                
                data(:,2) = -2.5*log10((data(:,2) - median(data(:,2)) + 1)*R);
                t = '_mag_abs';
  
            end

        else
            t = '_amp';
        end
   
        
        newfile = File([path_,filesep,name_,'_bjed',t,ext_]);
        
        fid = newfile.open('w');
        if args.doWriteHeader
            header(strcmp(header(:,1),'Bjed'),:) = [];
            for hline = 1:size(header,1)
                fprintf(fid,'#%s',header{hline,1});
                fprintf(fid,'\t%s',['=',header{hline,2}]);
                fprintf(fid,'\t%s\n',['#',header{hline,3}]);
            end
        end
        
        
        for i = 1:size(data,1)
            fprintf(fid,'%s\t%s\n',num2str(data(i,1),'%10.10f'),num2str(data(i,2),'%10.10f'));
            
        end
       
        
        

        
        
    end
    mtalk('\n\n');
        


end

