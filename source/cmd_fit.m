function cmd_fit(args)

Files = FILE(args.inFiles{1},'allowdirectories',false); 

if ~isempty(args.outFileName)
    OutFile = FILE(args.outFileName{1});
    fid = OutFile(1).open('w');
else
    fid = 1;
end
model = mgetmodel(args.functionName{1});

if ~isempty(args.filePar)   
    args.initialGuess = str2double(mread(args.filePar{1}))';      
end


for iFile = 1:length(Files)    
    data = mread(Files(iFile).FullName);                                       
    
    assert(size(data,2)>1,'not enough values in file');
    
    if any([args.aiXX,args.aiYY,args.aiDY] > size(data,2))
        error('not enough values in file');
    end
    
    if size(data,2)/3 ~= round(size(data,2)/3)
        if isempty(args.aiXX)
            args.aiXX = 1:2:size(data,2)-1;        
        end
        if isempty(args.aiYY)
            args.aiYY = 2:2:size(data,2);
        end
        if isempty(args.aiDY)
            args.aiDY = [];
        end
    else 
        if isempty(args.aiXX)
            args.aiXX = 1:3:size(data,2)-2;        
        end
        if isempty(args.aiYY)
            args.aiYY = 2:3:size(data,2)-1;
        end
        if isempty(args.aiDY)
            args.aiDY = 3:3:size(data,2);
        end      
    end                   
    
    XX = str2double(data(:,args.aiXX));
    YY = str2double(data(:,args.aiYY));
    DY = str2double(data(:,args.aiDY));
    
    if model.islinear    
        BB = model.basis(XX,args.initialGuess);
        [PP,DP] = mllsqr(BB,YY,DY);
        [PP,DP] = model.translate(PP,DP,args.initialGuess);
    else
        PP = model.guess(XX,YY,DY,args.initialGuess);                 
        [PP,DP] = mnllsqr(model.evaluate,model.jacobian,XX,YY,PP,DY);
    end
    
    R2 = (model.evaluate(XX,PP)-YY).^2;
    
    fprintf(fid,['#',Files(iFile).FullName,'\n']);
    if isempty(DY)
        fprintf(fid,[num2str(sum(R2(:)),'%10.10d'),'\t']);
    else      
        fprintf(fid,[num2str(sum(R2(:)./DY(:).^2)/(length(XX(:)-length(PP))),'%10.15d'),'\t']);
    end
    
    for iPar = 1:length(PP)
        fprintf(fid,[num2str(PP(iPar),'%10.15d'),'\t',num2str(DP(iPar),'%10.15d'),'\t']);
    end
    
    if args.makePlots
    
        figure(iFile);
        
        if length(XX) < 100
            DX = .1*(max(XX)-min(XX));
            XX2 = min(XX)-DX:DX/100:max(XX)+DX;
            
        else
            XX2 = XX;
        end
      
        if isempty(DY)
           plot(XX,YY,'o'); 
        else
           errorbar(XX,YY,DY,'o');
        end
        hold on
                  
        plot(XX2,model.evaluate(XX2,PP));        
        hold off
            
    end
    
    
    fprintf(fid,'\n');
end        

end

