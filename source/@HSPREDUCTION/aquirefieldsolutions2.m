function aquirefieldsolutions2(obj)
%keyboard

Configuration = mconfig;
Config = Configuration;
FITSList = mfits('RETRIEVE','OBJECT');
Solutions(1:length(FITSList)) = struct;
Solutions(length(FITSList)).xTranslation = [];
Solutions(length(FITSList)).yTranslation = [];
Solutions(length(FITSList)).wasFound = false;
originalCMG = obj.MasterFieldArray.Geometry;
goodObjectIndicies = false(length(FITSList),1);
MasterField = obj.MasterFieldArray;
pid = mprocessinit('\n Aquiring stars...');

for iFITSObject = 1:length(FITSList)
    Solutions(iFITSObject).wasFound = false; 
    CMG = originalCMG;
    CTG = FITSList(iFITSObject).findstars;    
    if isempty(CTG), FITSList(iFITSObject).clear; continue, end                   
    theta = 0;
    switch Configuration.FIELD_ROTATION_STYLE
        case 'NORMAL'            
        case 'FLIP'
            if iFITSObject <= Configuration.FIELD_ROTATION_DATA(1) 
                if Configuration.FIELD_ROTATION_DATA(2)
                    %CMG(2,:) = -CMG(2,:); 
                    %CMG(3,:) = -CMG(3,:);
                    theta = pi;
                end
            else
                if ~Configuration.FIELD_ROTATION_DATA(2)                                    
                    %CMG(2,:) = -CMG(2,:);
                    %CMG(3,:) = -CMG(3,:);
                    theta = pi;
                end
            end
        case 'ROTATING'
            data = Config.FIELD_ROTATION_DATA;
            if FITSList(iFITSObject).JulianDate < data(1,1)
               data = data(1:round(size(data,1)/2),:);
                par = polyfit(data(:,1),data(:,2),3);
                theta = polyval(par,FITSList(iFITSObject).JulianDate);
            elseif FITSList(iFITSObject).JulianDate > data(size(data,1),1)
               data = data(round(size(data,1)/2):size(data,1),:);
                par = polyfit(data(:,1),data(:,2),3);
                theta = polyval(par,FITSList(iFITSObject).JulianDate);
            else
                theta = pchip(data(:,1),data(:,2),FITSList(iFITSObject).JulianDate);
            end
         %   [CMG(2,:),CMG(3,:)] = mrotate(CMG(2,:),CMG(3,:),-theta);             
        otherwise
            error('Bad FIELD_ROTATION_METHOD');
    end
    
    Sigma = median(CTG(5,:));

    for NPS = min([size(CMG(2,:),2),size(CTG(2,:),2),8]):-1:2       
       
        NUT = size(CTG,2);
        NUM = size(CMG,2);        
      
        while NUT >= NPS && NUM >= NPS && nchoosek(NUT,NPS)*nchoosek(NUM,NPS) > Configuration.MAX_SOURCE_PERMUTATIONS
          
            if NUT > NUM
                NUT = NUT - 1;
            elseif NUM > NUT
                NUM = NUM - 1;
            else
                NUT = NUT - 1;
                NUM = NUM - 1;
            end
        end
        
        PTP = nchoosek(1:NUT,NPS);
        PMP = nchoosek(1:NUM,NPS);
        
        XXM = reshape(CMG(2,PMP)',size(PMP));
        YYM = reshape(CMG(3,PMP)',size(PMP));
        XXT = reshape(CTG(2,PTP)',size(PTP));
        YYT = reshape(CTG(3,PTP)',size(PTP));
           
        [junk,IIM] = sort((XXM-repmat(mean(XXM,2),[1,NPS])).^2+(YYM-repmat(mean(YYM,2),[1,NPS])).^2,2); %#ok<ASGLU>
        [junk,IIT] = sort((XXT-repmat(mean(XXT,2),[1,NPS])).^2+(YYT-repmat(mean(YYT,2),[1,NPS])).^2,2); %#ok<ASGLU>
             
        clear XXM YYM XXT YYT junk
       
        PMP = PMP'; PMP = PMP(IIM'+repmat((0:size(PMP,2)-1)*NPS,[NPS,1]))';
        PTP = PTP'; PTP = PTP(IIT'+repmat((0:size(PTP,2)-1)*NPS,[NPS,1]))';
        
        clear IIM IIT
               
        if NPS == 2, PTP = [PTP;[PTP(:,2),PTP(:,1)]]; PMP = [PMP;[PMP(:,2),PMP(:,1)]]; end
        
        PMP = repmat(PMP,[size(PTP,1),1]);
        PTP = reshape(repmat(PTP',[size(PMP,1)./size(PTP,1),1]),[NPS,size(PMP,1)])';
                   
        XXM = reshape(CMG(2,PMP)',size(PMP));
        YYM = reshape(CMG(3,PMP)',size(PMP));
        XXT = reshape(CTG(2,PTP)',size(PTP));
        YYT = reshape(CTG(3,PTP)',size(PTP));
        
        xxTranslationPreRotation = -mean(XXM,2);
        xxTranslationPosRotation = mean(XXT,2);
        yyTranslationPreRotation = -mean(YYM,2);
        yyTranslationPosRotation = mean(YYT,2);               
        
        XXM = XXM + repmat(xxTranslationPreRotation,[1,NPS]);
        YYM = YYM + repmat(yyTranslationPreRotation,[1,NPS]);
        
        [XXM,YYM] = mrotate(XXM,YYM,-theta);
        
        XXM = XXM + repmat(xxTranslationPosRotation,[1,NPS]);
        YYM = YYM + repmat(yyTranslationPosRotation,[1,NPS]);
                      
        xxDistance2 = (XXT-XXM).^2;
        yyDistance2 = (YYT-YYM).^2;
        rrDistance2 = xxDistance2+yyDistance2;
                
        goodSolutionIndicies = find(max(rrDistance2,[],2)<Sigma);
        rrDistance2 = rrDistance2(goodSolutionIndicies);                
        [junk,I] = sort(rrDistance2); %#ok<ASGLU>
        goodSolutionIndicies = goodSolutionIndicies(I);
        FITSList(iFITSObject).clear;
        if length(goodSolutionIndicies)>1
            iSolution = goodSolutionIndicies(1);        
            Solutions(iFITSObject).xxTranslationPreRotation = xxTranslationPreRotation(iSolution);
            Solutions(iFITSObject).yyTranslationPreRotation = yyTranslationPreRotation(iSolution);
            Solutions(iFITSObject).xxTranslationPosRotation = xxTranslationPosRotation(iSolution);
            Solutions(iFITSObject).yyTranslationPosRotation = yyTranslationPosRotation(iSolution);            
            Solutions(iFITSObject).ttRotationAngle = -theta;
            Solutions(iFITSObject).wasFound = true;
            break
        end              

    end
    FITSList(iFITSObject).clear;
      
    mprocessupdate(pid,iFITSObject/length(FITSList));
    
end
mprocessfinish(pid,1);
obj.FieldSolutions = Solutions;
    
