function labelfield3(HSPReduction)




% Extract the configuration structure.
Config = mconfig;
if isempty(Config.STAR_LABELING_FILENAME)
      return;
end


mtalk('\n\nLABELING AND SORTING STARS');

%% Check the configuration



% Assert that the star labeling filename is a string. If not throw an
% error.
% Check that only one file was made% Check that at least one file was made and that it is not a directory.
assert(ischar(Config.STAR_LABELING_FILENAME),'MAESTRO:HSPREDUCTION:labelfield:fileNameNotChar','The Maestro configuration value for "STAR_LABELING_FILENAME" must evaluate to a MatLab string. Check the specified configuration.');
assert(isnumeric(Config.STAR_LABELING_MAX_STARS_PER_HASH) && Config.STAR_LABELING_MAX_STARS_PER_HASH > 1,'MAESTRO:HSPREDUCTION:labelfield:badNPerHash','The Maestro configuration value for "STAR_LABELING_MAX_STARS_PER_HASH" should be an integer greater than 1.');

% Attempt to build a file object from the filename.
File = FILE(Config.STAR_LABELING_FILENAME);

% Check the file.
assert(length(File)==1,'MAESTRO:HSPREDUCTION:labelfield:multipleFiles','Only one field file can be specified for star labeling. No wildcards can be used');
assert(File.Exists~=0,'MAESTRO:HSPREDUCTION:labelfield:notExist',['The specified field "',File.FullName,'" does not exist.']);
assert(~File.IsDir,'MAESTRO:HSPREDUCTION:labelfield:isDir',['The specified field "',File.FullName,'" is a directory. It must be a single file.']);

mtalk(['\n Searching for similar geometry in file "',File.Name,'"']);


%% Read in file
try File.open; catch ME, error('MAESTRO:HSPREDUCTION:labelfield:noOpen',['The specified field "',File.FullName,'" failed to open. Check the file.']); end


try
    fieldData = textscan(File.FID,'%s %s %s %s','CommentStyle','#','CollectOutput',true);
    fieldData = fieldData{1};
catch ME
    error('MAESTRO:HSPREDUCTION:labelfield:readFail',['Failed to read in field from file "',File.FullName,'"']);
end


%% Prepare geometry

% was x y z
XX_Target= HSPReduction.MasterFieldArray.Geometry(2,:);
YY_Target = HSPReduction.MasterFieldArray.Geometry(3,:);
ZZ_Target = HSPReduction.MasterFieldArray.Geometry(4,:);
mtalk(['\n ',num2str(length(XX_Target)),' stars found on images.']);

% was X Y Z
LL_Master = fieldData(:,1);
XX_Master = str2double(fieldData(:,2))';
YY_Master = str2double(fieldData(:,3))';
ZZ_Master = str2double(fieldData(:,4))';
mtalk(['\n ',num2str(length(LL_Master)),' stars in given field.']);



for N = min([length(XX_Target),length(XX_Master),Config.STAR_LABELING_MAX_STARS_PER_HASH]):-1:2
    
    NN_Target = length(XX_Target);
    NN_Master = length(XX_Master);
    
    while nchoosek(NN_Target,N)*nchoosek(NN_Master,N) > Config.STAR_LABELING_PERMUTATIONS        
        if NN_Target > NN_Master
            NN_Target = NN_Target -1;
        elseif NN_Master > NN_Target
            NN_Master = NN_Master -1;
        else
            NN_Target = NN_Target-1;
            NN_Master = NN_Master-1;
        end        
    end        
    
    PP_Target_Permutations = nchoosek(1:NN_Target,N);
    PP_Master_Permutations = nchoosek(1:NN_Master,N);
    
    PP_Target_Permutations = repmat(PP_Target_Permutations,[size(PP_Master_Permutations,1),1]);
    PP_Master_Permutations = reshape(repmat(PP_Master_Permutations',[size(PP_Target_Permutations,1)./size(PP_Master_Permutations,1),1]),[N,size(PP_Target_Permutations,1)])';
 
    XX_Target_Permutations = XX_Target(PP_Target_Permutations);
    YY_Target_Permutations = YY_Target(PP_Target_Permutations);
    ZZ_Target_Permutations = ZZ_Target(PP_Target_Permutations);
    
    XX_Master_Permutations = XX_Master(PP_Master_Permutations);
    YY_Master_Permutations = YY_Master(PP_Master_Permutations);
    ZZ_Master_Permutations = ZZ_Master(PP_Master_Permutations);
        
    XX_Target_Offsets = mean(XX_Target_Permutations,2);
    YY_Target_Offsets = mean(YY_Target_Permutations,2);
    ZZ_Target_Scales = max(ZZ_Target_Permutations,[],2);
    
    XX_Master_Offsets = mean(XX_Master_Permutations,2);
    YY_Master_Offsets = mean(YY_Master_Permutations,2);
    ZZ_Master_Scales = max(ZZ_Master_Permutations,[],2);               
        
    XX_Target_Permutations = XX_Target_Permutations - repmat(XX_Target_Offsets,[1,N]);
    YY_Target_Permutations = YY_Target_Permutations - repmat(YY_Target_Offsets,[1,N]);
    ZZ_Target_Permutations = ZZ_Target_Permutations./repmat(ZZ_Target_Scales,[1,N]);
        
    XX_Master_Permutations = XX_Master_Permutations - repmat(XX_Master_Offsets,[1,N]);
    YY_Master_Permutations = YY_Master_Permutations - repmat(YY_Master_Offsets,[1,N]);
    ZZ_Master_Permutations = ZZ_Master_Permutations./repmat(ZZ_Master_Scales,[1,N]);
            
    RR_Target_Square_Distance = XX_Target_Permutations.^2 + YY_Target_Permutations.^2;
    RR_Master_Square_Distance = XX_Master_Permutations.^2 + YY_Master_Permutations.^2;
            
    [junk,II_Target_Sort_Order] = sort(RR_Target_Square_Distance,2); %#ok<ASGLU>
    [junk,II_Master_Sort_Order] = sort(RR_Master_Square_Distance,2); %#ok<ASGLU>
        
    PP_Target_Permutations = PP_Target_Permutations'; PP_Target_Permutations = PP_Target_Permutations(II_Target_Sort_Order'+repmat((0:size(PP_Target_Permutations,2)-1)*N,[N,1]))';
    PP_Master_Permutations = PP_Master_Permutations'; PP_Master_Permutations = PP_Master_Permutations(II_Master_Sort_Order'+repmat((0:size(PP_Master_Permutations,2)-1)*N,[N,1]))';    
    XX_Target_Permutations = XX_Target_Permutations'; XX_Target_Permutations = XX_Target_Permutations(II_Target_Sort_Order'+repmat((0:size(XX_Target_Permutations,2)-1)*N,[N,1]))';
    YY_Target_Permutations = YY_Target_Permutations'; YY_Target_Permutations = YY_Target_Permutations(II_Target_Sort_Order'+repmat((0:size(YY_Target_Permutations,2)-1)*N,[N,1]))';
    ZZ_Target_Permutations = ZZ_Target_Permutations'; ZZ_Target_Permutations = ZZ_Target_Permutations(II_Target_Sort_Order'+repmat((0:size(ZZ_Target_Permutations,2)-1)*N,[N,1]))';
    XX_Master_Permutations = XX_Master_Permutations'; XX_Master_Permutations = XX_Master_Permutations(II_Master_Sort_Order'+repmat((0:size(XX_Master_Permutations,2)-1)*N,[N,1]))';
    YY_Master_Permutations = YY_Master_Permutations'; YY_Master_Permutations = YY_Master_Permutations(II_Master_Sort_Order'+repmat((0:size(YY_Master_Permutations,2)-1)*N,[N,1]))';
    ZZ_Master_Permutations = ZZ_Master_Permutations'; ZZ_Master_Permutations = ZZ_Master_Permutations(II_Master_Sort_Order'+repmat((0:size(ZZ_Master_Permutations,2)-1)*N,[N,1]))';
	
   
    TT_Target_Rotations = atan2(YY_Target_Permutations(:,N),XX_Target_Permutations(:,N));
    TT_Master_Rotations = atan2(YY_Master_Permutations(:,N),XX_Master_Permutations(:,N));    
    
    [XX_Target_Permutations,YY_Target_Permutations] = mrotate(XX_Target_Permutations,YY_Target_Permutations,repmat(-TT_Target_Rotations,[1,N]));
    [XX_Master_Permutations,YY_Master_Permutations] = mrotate(XX_Master_Permutations,YY_Master_Permutations,repmat(-TT_Master_Rotations,[1,N]));
    
    
    RR_Max_Residuals = max(((XX_Target_Permutations-XX_Master_Permutations).^2+(YY_Target_Permutations-YY_Master_Permutations).^2).^(1/2),[],2);
    
    
    [RR_Max_Residual,II_Solution] = min(RR_Max_Residuals);
    
    if RR_Max_Residual > Config.STAR_LABELING_MAX_MATCH_DISTANCE, continue, end
    
    XX_Projected_Master = XX_Master - XX_Master_Offsets(II_Solution);
    YY_Projected_Master = YY_Master - YY_Master_Offsets(II_Solution);
    ZZ_Projected_Master = ZZ_Master/ZZ_Master_Scales(II_Solution)*ZZ_Target_Scales(II_Solution);
    
    [XX_Projected_Master,YY_Projected_Master] = mrotate(XX_Projected_Master,YY_Projected_Master,-TT_Master_Rotations(II_Solution)+TT_Target_Rotations(II_Solution));
    
    XX_Projected_Master = XX_Projected_Master + XX_Target_Offsets(II_Solution);
    YY_Projected_Master = YY_Projected_Master + YY_Target_Offsets(II_Solution);
   
    TargetGeometry = zeros(10,length(XX_Projected_Master));  
    OldTargetGeometry = HSPReduction.MasterFieldArray.Geometry;
    OldLabels = HSPReduction.MasterFieldArray.Labels;
    
    counterMatched = 0;
    counterUnmatched = 0;
    for iStar = 1:length(XX_Projected_Master)
        
        [Value,Index] = min(((XX_Projected_Master(iStar)-XX_Target).^2+(YY_Projected_Master(iStar)-YY_Target).^2).^(1/2));
                        
        if Value > Config.STAR_LABELING_MAX_MATCH_DISTANCE
            TargetGeometry(2,iStar) = XX_Projected_Master(iStar);
            TargetGeometry(3,iStar) = YY_Projected_Master(iStar);
            TargetGeometry(4,iStar) = ZZ_Projected_Master(iStar);
            TargetGeometry(5,iStar) = median(OldTargetGeometry(5,:));
            counterUnmatched = counterUnmatched + 1;
        else
            if Config.STAR_LABELING_FORCE_GEOMETRY || isempty(XX_Target)
               TargetGeometry(2,iStar) = XX_Projected_Master(iStar);
               TargetGeometry(3,iStar) = YY_Projected_Master(iStar);
               TargetGeometry(4,iStar) = ZZ_Projected_Master(iStar);  
               TargetGeometry(5,iStar) = median(OldTargetGeometry(5,:));
            else
try
                TargetGeometry(:,iStar) = OldTargetGeometry(:,Index);                
catch ME
keyboard
end
            end
            OldTargetGeometry(:,Index) = [];
            OldLabels(Index) = [];
            XX_Target(Index) = [];
            YY_Target(Index) = [];
            ZZ_Target(Index) = [];
            counterMatched = counterMatched + 1;
            % Must delete XX_Target stuff too
        end
                                                                                
    end
    
    counterOther = length(OldLabels);
    for iNewLabel = 1:length(OldLabels)
        OldLabels{iNewLabel} = ['Unmatched',num2str(iNewLabel)];        
        
    end

    
    HSPReduction.MasterFieldArray.Geometry = [TargetGeometry,OldTargetGeometry];          
    HSPReduction.MasterFieldArray.Labels = [LL_Master;OldLabels];
    HSPReduction.MasterFieldArray.FieldName = File.Name;
    
    
    mtalk(['\n Match found with ',num2str(N),' stars.']);
    mtalk(['\n ',num2str(counterMatched),' stars matched.']);
    mtalk(['\n ',num2str(counterUnmatched),' stars from file did not match and were added.']);
    mtalk(['\n ',num2str(counterOther),' stars from images did not match.']);
    
  
   return
    
end      

error('MAESTRO:HSPREDUCTION:labelfield:noMatches','No stars matched for labeling.');


end
