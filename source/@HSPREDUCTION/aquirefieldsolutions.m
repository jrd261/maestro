function aquirefieldsolutions(HSPReduction)

MasterField = HSPReduction.MasterFieldArray(1);
MasterGeometry = MasterField.Geometry;
FieldSolutions = HSPReduction.FieldSolutions;
FITSList = HSPReduction.FITSList;
Config = HSPReduction.MaestroConfiguration;


pid = mprocessinit(['\n Revisiting ',num2str(length(FITSList)),' images to aquire star positions...']);



for iFITSObject = 1:length(FITSList)        
    if FieldSolutions(iFITSObject).WasFound, continue, end  
    TargetGeometry = FITSList(iFITSObject).LocatedStars;   
    FITSList(iFITSObject).clear;
    if isempty(TargetGeometry), HSPReduction.liCorruptFiles(iFITSObject) = true; continue, end
    %% ROTATE
    switch MasterField.RotationStyle
        case 1
            rotationAngle = 0;
        case 2
            if MasterField.RotationFlipIndex > iFITSObject
                if MasterField.RotationIsFlipInverted
                    rotationAngle = pi;
                else
                    rotationAngle = 0;
                end
            else
                if MasterField.RotationIsFlipInverted
                    rotationAngle = 0;
                else
                    rotationAngle = pi;
                end
            end                                            
        case 3
            rotationAngle = (MasterField.JulianDate-FITSList(iFITSObject).JulianDate)/86400*2*pi;
        case 4                        
            rotationAngle = -(MasterField.JulianDate-FITSList(iFITSObject).JulianDate)/86400*2*pi;
    end        
    
    TargetGeometry(2:3,:) = [TargetGeometry(2,:)*cos(rotationAngle)+TargetGeometry(3,:)*sin(rotationAngle);-TargetGeometry(2,:)*sin(rotationAngle)+TargetGeometry(3,:)*cos(rotationAngle)];                
    TargetGeometry(6:7,:) = [TargetGeometry(5,:).^2*cos(rotationAngle)^2+TargetGeometry(3,:).^2*sin(rotationAngle)^2;-TargetGeometry(2,:).^2*sin(rotationAngle)^2+TargetGeometry(3,:).^2*cos(rotationAngle)^2].^(1/2);                
    
    %% LOOP OVER NUMBER OF HASH SOURCES   
    for iHashIndex = 0:min(size(TargetGeometry,2),size(MasterGeometry,2))-2                     
        nSourcesPerHash = min(size(TargetGeometry,2),size(MasterGeometry,2))- iHashIndex;
        nTargetSources = size(TargetGeometry,2);
        nMasterSources = size(MasterGeometry,2);

        %% DETERMINE NUMBER OF MASTER AND TARGET SOURCES    
        while nTargetSources >= nSourcesPerHash && nMasterSources >= nSourcesPerHash && nchoosek(nTargetSources,nSourcesPerHash)*nchoosek(nMasterSources,nSourcesPerHash) > Config.MAX_SOURCE_PERMUTATIONS
            if nTargetSources >= nMasterSources
                nTargetSources = nTargetSources - 1;
            elseif nMasterSources > nTargetSources
                nMasterSources = nMasterSources - 1;       
            end 
        end
        
        if any([nTargetSources,nMasterSources]<nSourcesPerHash), continue, end    
        
        %% GENERATE PERMUTATIONS       
        completeTargetSolutions = nchoosek(1:nTargetSources,nSourcesPerHash);
        completeMasterSolutions = nchoosek(1:nMasterSources,nSourcesPerHash);   
               
        %% ENSURE ORDER INVARIANCE
        xxPossibleTargetSolutions = reshape(TargetGeometry(2,completeTargetSolutions),size(completeTargetSolutions));
        xxPossibleMasterSolutions = reshape(MasterGeometry(2,completeMasterSolutions),size(completeMasterSolutions));
        [junk,aiTargetSortOrder] = sort(xxPossibleTargetSolutions,2); %#ok<ASGLU>
        [junk,aiMasterSortOrder] = sort(xxPossibleMasterSolutions,2);                     %#ok<ASGLU>        
        completeMasterSolutions = completeMasterSolutions'; 

        completeMasterSolutions = completeMasterSolutions(aiMasterSortOrder'+repmat((0:size(completeMasterSolutions,2)-1)*nSourcesPerHash,[nSourcesPerHash,1]))';
        completeTargetSolutions = completeTargetSolutions';
        completeTargetSolutions = completeTargetSolutions(aiTargetSortOrder'+repmat((0:size(completeTargetSolutions,2)-1)*nSourcesPerHash,[nSourcesPerHash,1]))';                                
        
        completeMasterSolutions = repmat(completeMasterSolutions,[size(completeTargetSolutions,1),1]);        
        completeTargetSolutions = reshape(repmat(completeTargetSolutions',[size(completeMasterSolutions,1)./size(completeTargetSolutions,1),1]),[nSourcesPerHash,size(completeMasterSolutions,1)])';
           
        
        %% Extract                
        xxPossibleTargetSolutions = reshape(TargetGeometry(2,completeTargetSolutions),size(completeTargetSolutions));
        yyPossibleTargetSolutions = reshape(TargetGeometry(3,completeTargetSolutions),size(completeTargetSolutions));
        xxPossibleMasterSolutions = reshape(MasterGeometry(2,completeMasterSolutions),size(completeMasterSolutions));
        yyPossibleMasterSolutions = reshape(MasterGeometry(3,completeMasterSolutions),size(completeMasterSolutions));
        zzPossibleTargetSolutions = reshape(TargetGeometry(4,completeTargetSolutions),size(completeTargetSolutions));
        zzPossibleMasterSolutions = reshape(MasterGeometry(4,completeMasterSolutions),size(completeMasterSolutions));
        
        xxPossibleTranslations = mean(xxPossibleMasterSolutions,2)-mean(xxPossibleTargetSolutions,2);
        yyPossibleTranslations = mean(yyPossibleMasterSolutions,2)-mean(yyPossibleTargetSolutions,2);
        zzPossibleScaleFactors = mean(zzPossibleTargetSolutions,2)./mean(zzPossibleMasterSolutions,2);
        
        dx = (-xxPossibleMasterSolutions + xxPossibleTargetSolutions + repmat(xxPossibleTranslations,[1,nSourcesPerHash]));
        dy = (-yyPossibleMasterSolutions + yyPossibleTargetSolutions + repmat(yyPossibleTranslations,[1,nSourcesPerHash]));
        
        R = (max(dx.^2+dy.^2,[],2)).^(1/2);
        [junk,aiIndex] = min(R); %#ok<ASGLU>
        if min(R) > 4, continue; end %#ok<ASGLU>
        
        FieldSolutions(iFITSObject).WasFound = true;
        FieldSolutions(iFITSObject).FieldIndex = 1;
        FieldSolutions(iFITSObject).xxTranslation = xxPossibleTranslations(aiIndex);
        FieldSolutions(iFITSObject).dxTranslation = 0;
        FieldSolutions(iFITSObject).yyTranslation = yyPossibleTranslations(aiIndex);
        FieldSolutions(iFITSObject).dyTranslation =  0;
        FieldSolutions(iFITSObject).mmRatio = zzPossibleScaleFactors(aiIndex);
        FieldSolutions(iFITSObject).dmRatio = 0;
        FieldSolutions(iFITSObject).nHashSources = nSourcesPerHash;
        FieldSolutions(iFITSObject).nTotalMatches = nSourcesPerHash;
        FieldSolutions(iFITSObject).RotationStyle = MasterField.RotationStyle;
        FieldSolutions(iFITSObject).GoodStaritude = Inf;
        FieldSolutions(iFITSObject).BadStaritude = 0;
        FieldSolutions(iFITSObject).TranslationalRC2 = 0;
        FieldSolutions(iFITSObject).ScalingAC2 = 0;
        FieldSolutions(iFITSObject).GaussianSTD = median(TargetGeometry(5,:));
        
        break
        
        
    end                       
    
    if ~FieldSolutions(iFITSObject).WasFound, HSPReduction.liCorruptFiles(iFITSObject) = true; end
    % Each iteration may take some time, especially on slower machines. For
    % this reason (and to make everything pretty) we will write the current
    % percentage we are through the images using the "mprocessupdate"
    % function. See this function for information.
    mprocessupdate(pid,iFITSObject/length(FITSList));
            
end



% We have completed our attempt to aquire stars with brute force hash
% matching. As some text was written out to indicate our progress we need
% to wrap up the progress too. This function will display some text that
% indicates that all has finished ok.
mprocessfinish(pid,1);

HSPReduction.FieldSolutions = FieldSolutions;



end