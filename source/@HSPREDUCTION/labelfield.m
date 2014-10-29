function labelfield(HSPReduction)

MaestroConfiguration = mconfig;
G = HSPReduction.MasterFieldArray(1).Geometry;

x = G(2,:);
y = G(3,:);
z = G(4,:);


% Begin to loop over all files that can be used for star labeling.
for iEntry = 1:length(MaestroConfiguration.STAR_LABELING_FILES)
    
    % Build a file list for each entry.
    fileList = FILE([muserpath,filesep,'fields',filesep,MaestroConfiguration.STAR_LABELING_FILES{iEntry}],'allowdirectories',false);
    
    [junk,liSortOrder] = sort([fileList.LastMod],'descend'); %#ok<ASGLU>
    fileList = fileList(liSortOrder);
    
    % Loop over all files in the file list.
    for iFile = 1:length(fileList)
        
        try
            fid = fileList(iFile).open;
            
            fileData = textscan(fid,'%s %s %s %s','CollectOutput',true);
            fileData = fileData{1};
        catch ME
            continue
        end
        keyboard
        L = fileData(:,1);
        X = str2double(fileData(:,2))';
        Y = str2double(fileData(:,3))';
        Z = str2double(fileData(:,4))';
        
        nmax = min([length(x),length(X)]);
        
        for index = 0:nmax-3
            NPP = nmax-index-2; %%%%
            n = length(x);
            N = length(X);
           
            while nchoosek(n,NPP)*nchoosek(N,NPP) > MaestroConfiguration.STAR_LABELING_MAX_PERMUTATIONS
                
                if N>n
                    N = N -1;
                elseif n>N
                    n = n -1;
                else
                    N = N-1;
                    n = n-1;
                end
                
            end
            
            
            p = nchoosek(1:n,NPP);                                    
            P = nchoosek(1:N,NPP);
            p = repmat(p,[size(P,1),1]);
            P = reshape(repmat(P',[size(p,1)./size(P,1),1]),[NPP,size(p,1)])';

            xx = x(p); 
            yy = y(p);
            
            XX = X(P);
            YY = Y(P);
          
            
            % Translation
            dx = mean(XX,2)-mean(xx,2);
            dy = mean(YY,2)-mean(yy,2);            
            xx = xx - repmat(dx,[1,NPP]);
            yy = yy - repmat(dy,[1,NPP]);
                        
            % Order invariance
            r2 = xx.^2+yy.^2;
            R2 = XX.^2+yy.^2;            
            [junk,ii] = sort(r2,2); %#ok<ASGLU>
            [junk,II] = sort(R2,2); %#ok<ASGLU>            
            p = p'; p = p(ii'+repmat((0:size(p,2)-1)*NPP,[NPP,1]))';
            P = P'; P = P(II'+repmat((0:size(P,2)-1)*NPP,[NPP,1]))';
            xx = xx'; xx = xx(ii'+repmat((0:size(xx,2)-1)*NPP,[NPP,1]))';
            XX = XX'; XX = XX(II'+repmat((0:size(XX,2)-1)*NPP,[NPP,1]))';
            yy = yy'; yy = yy(ii'+repmat((0:size(yy,2)-1)*NPP,[NPP,1]))';
            YY = YY'; YY = YY(II'+repmat((0:size(YY,2)-1)*NPP,[NPP,1]))';
            
            % Scaling
            scale = (XX(:,NPP).^2+YY(:,NPP).^2).^(1/2)./(xx(:,NPP).^2+yy(:,NPP).^2).^(1/2);            
            xx = xx.*repmat(scale,[1,NPP]);
            yy = yy.*repmat(scale,[1,NPP]);
            
            
            % Rotational invariance            
            angle = atan2(YY(:,NPP),XX(:,NPP))-atan2(yy(:,NPP),xx(:,NPP));
            a = repmat(angle,[1,NPP]);
            xx_temp = xx;
            yy_temp = yy;           
            xx = xx_temp.*cos(a)+yy_temp.*sin(a);
            yy = -xx_temp.*sin(a)+yy_temp.*cos(a);
            
          
            drmax = max(((xx-XX).^2+(yy-YY).^2).^(1/2),[],2);
            isScaleOk = (max([scale,1./scale],[],2) < MaestroConfiguration.STAR_LABELING_MAX_SCALING);
            isMatchOk = drmax < MaestroConfiguration.STAR_LABELING_MINIMUM_DISTANCE;
            matches = find(isScaleOk & isMatchOk);                                                                        
            if isempty(matches), continue, end
            
            best = Inf;
            iBest = 0;
            for iSolution = 1:length(matches)
                if drmax(iSolution) < best
                    best = drmax(iSolution);
                    iBest = matches(iSolution);
                end                                
            end
            
            
            p = p(iBest,:);
            P = P(iBest,:);
            dx = dx(iBest);
            dy = dy(iBest);
            angle = angle(iBest);
            scale = scale(iBest);
            xu = x;         
            xu(p) = [];
            yu = y;
            yu(p) = [];
            XU = X;
            XU(P) = [];
            YU = Y;
            YU(P) = [];
            pu = 1:length(x);
            pu(p) = [];
            PU = 1:length(X);
            PU(P) = [];
                                   
            xu = xu + dx;
            yu = yu + dy;
            xu = xu*scale;
            yu = yu*scale;
            x_temp = xu;
            y_temp = yu;          
            xu = x_temp.*cos(angle)+y_temp.*sin(angle);
            yu = -x_temp.*sin(angle)+y_temp.*cos(angle);
            
            while(1)
                if isempty(xu), break; end
                if isempty(XU), break; end
                        
                rmat = ((repmat(xu,[length(XU),1])-repmat(XU',[1,length(xu)])).^2+...
                    (repmat(yu,[length(YU),1])-repmat(YU',[1,length(yu)])).^2).^(1/2);
            
                [ai,AI] = ind2sub([length(xu),length(XU)],find(rmat < 1));
                
                if isempty(ai), break; end
                
                    
                p = [p,pu(ai(1))]; %#ok<AGROW>
                P = [P,PU(AI(1))]; %#ok<AGROW>
                pu(ai(1)) = [];
                PU(AI(1)) = [];
                xu(ai(1)) = [];
                XU(AI(1)) = [];
                yu(ai(1)) = [];
                YU(AI(1)) = [];            
            
            end
            
            [P,AIP] = sort(P);
            p = p(AIP);                   
            
            l = cell(length(x),1);                        
            l(1:length(P)) = L;
            
            c = 1;
            for i = 1:length(l)
                if isempty(l{i})
                    while(any(strcmp(['Unknown',num2str(c)],l)))
                        c = c + 1;
                    end                    
                    l{i} = ['Unknown',num2str(c)];
                    c = c + 1;
                end                
            end
            
            HSPReduction.MasterFieldArray.Labels = l;                      
            tempgeo = HSPReduction.MasterFieldArray.Geometry;
            
            
            newgeo = zeros(size(tempgeo));
            c = 1;
            for i=1:length(p)
                newgeo(:,c) = tempgeo(:,p(i));                                
                c = c + 1;
            end
            
            for i=1:length(pu)                
                newgeo(:,c) = tempgeo(:,pu(i));
                c = c + 1;
            end
          
            
            HSPReduction.MasterFieldArray.Geometry = newgeo;                                                                                                                                                                                                                                            
                       
            return                        
            
        end                                        
        
    end
    
end














end

