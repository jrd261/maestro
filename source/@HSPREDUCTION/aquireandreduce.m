function aquireandreduce(obj)
HSPReduction = obj;

Configuration = mconfig;
Config = Configuration;
FITSList = mfits('RETRIEVE','OBJECT');
Solutions(1:length(FITSList)) = struct;
Solutions(length(FITSList)).xTranslation = [];
Solutions(length(FITSList)).yTranslation = [];
Solutions(length(FITSList)).wasFound = false;
originalCMG = obj.MasterFieldArray.Geometry;

MaestroConfiguration = mconfig;
as = MaestroConfiguration.APERTURE_SIZES;
FITSList = obj.FITSList;
MasterFieldTemplate = HSPReduction.MasterFieldArray(1).Geometry;

obj.CenteringData.XX = zeros(length(FITSList),size(MasterFieldTemplate,2));
obj.CenteringData.YY = zeros(length(FITSList),size(MasterFieldTemplate,2));
obj.CenteringData.FitParameters = zeros(length(FITSList),size(MasterFieldTemplate,2),4);
obj.CenteringData.FitCovariance = cell(length(FITSList),1);
obj.ApertureData.Sky = zeros(length(FITSList),size(MasterFieldTemplate,2));
obj.ApertureData.Counts = zeros(length(FITSList),size(MasterFieldTemplate,2),length(as));

a = HSPReduction.ApertureData.Counts;
HSPReduction.ApertureData.Noise = a;
HSPReduction.ApertureData.Area = a;
HSPReduction.ApertureData.Sizes = as;
pid = mprocessinit('\n Aquiring targets and performing aperture photometry...');

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
   
   
    
    if ~Solutions(iFITSObject).wasFound, continue; end
   
    TG = FITSList(iFITSObject).findstars;
    if isempty(TG), s = 2; else s = median(TG(5,:)); end
    
    % Copy the list of x and y positions of stars from the master
    % geometry. We will apply some geometric transforms to these positions
    % to obtain the location of these stars on the current image.
    x = MasterFieldTemplate(2,:);
    y = MasterFieldTemplate(3,:);
    
    
    try
    x = x+Solutions(iFITSObject).xxTranslationPreRotation;
    y = y+Solutions(iFITSObject).yyTranslationPreRotation;
    catch ME
        'uhoh'
        keyboard
    end
   
    
    [x,y] = mrotate(x,y,Solutions(iFITSObject).ttRotationAngle);
    
    x = x+Solutions(iFITSObject).xxTranslationPosRotation;
    y = y+Solutions(iFITSObject).yyTranslationPosRotation;        
    
       
    % Obtain the sky removed image.
    flatimage = FITSList(iFITSObject).SkyRemovedPrimaryImage;
    image = FITSList(iFITSObject).CalibratedPrimaryImage;    
    noiseimage = FITSList(iFITSObject).NoisePrimaryImage;
  
  
             
    % Obtain the size of the image. 
    [yyImageSize,xxImageSize] = size(image);
    gi = ~(x>xxImageSize | y>yyImageSize | x < 1 | y < 1);
    %if ~gi(1), 'bad',keyboard, end
    oldx = x;
    oldy = y;
    
    x = x(gi);
    y = y(gi);
    
    ai = find(gi);
    
    HSPReduction.liStarOffImage(iFITSObject,~gi) = true;
    
    if ~isempty(x)
        [x,y,par,cov] = mcenterstars(flatimage,x,y,2*s);
        gi2 = ~(x>xxImageSize | y>yyImageSize | x < 1 | y < 1);
        newbad = ai(~gi2);
        par(:,~gi2) = [];
        gi(newbad) = false;
        x = oldx(gi);
        y = oldy(gi);
        
        HSPReduction.CenteringData.XX(iFITSObject,gi) = x;
        HSPReduction.CenteringData.YY(iFITSObject,gi) = y;
        
        HSPReduction.CenteringData.FitParameters(iFITSObject,gi,:) = par';
        HSPReduction.CenteringData.FitCovariance{iFITSObject} = cov;
        sky = mskycalc(image,x,y,8*s,12*s);
        bothimages = repmat(image,[1,1,2]);
        bothimages(:,:,2) = noiseimage;
        [c,a,n] = maperture(bothimages,x,y,as);
        HSPReduction.ApertureData.Sky(iFITSObject,gi) = sky;
        HSPReduction.ApertureData.Counts(iFITSObject,gi,:) = c-a.*repmat(sky,[1,length(as)]);
        HSPReduction.ApertureData.Noise(iFITSObject,gi,:) = n;
        HSPReduction.ApertureData.Area(iFITSObject,gi,:) = a;
    end
        
    FITSList(iFITSObject).clear;        
      
    mprocessupdate(pid,iFITSObject/length(FITSList));
    
end
 obj.FieldSolutions = Solutions;     % Check if this file is labeled as corrupt. If so we should not attempt
mprocessfinish(pid,1);
obj.FieldSolutions = Solutions;
    
