function dophotometry2(HSPReduction)
%CENTERSTARS Summary of this function goes here
%   Detailed explanation goes here


MaestroConfiguration = mconfig;
as = MaestroConfiguration.APERTURE_SIZES;
FITSList = HSPReduction.FITSList;
MasterFieldTemplate = HSPReduction.MasterFieldArray(1).Geometry;
HSPReduction.CenteringData.XX = zeros(length(FITSList),size(MasterFieldTemplate,2));
HSPReduction.CenteringData.YY = zeros(length(FITSList),size(MasterFieldTemplate,2));
HSPReduction.CenteringData.FitParameters = zeros(length(FITSList),size(MasterFieldTemplate,2),4);
HSPReduction.CenteringData.FitCovariance = cell(length(FITSList),1);
HSPReduction.ApertureData.Sky = zeros(length(FITSList),size(MasterFieldTemplate,2));
HSPReduction.ApertureData.Counts = zeros(length(FITSList),size(MasterFieldTemplate,2),length(as));
a = HSPReduction.ApertureData.Counts;
HSPReduction.ApertureData.Noise = a;
HSPReduction.ApertureData.Area = a;
HSPReduction.ApertureData.Sizes = as;
pid = mprocessinit('\n Performing aperture photometry...');
%keyboard
%% LOOP OVER ALL FITS OBJECTS
% We will perform a loop over every object in the FITS list. For each FITS
% file we will center and perform aperture photometry for all stars which
% appear on image. If the file has been labeled as corrupt or had some
% problems we will skip it. 
for iFITSObject = 1:length(FITSList)   
    
    % Check if this file is labeled as corrupt. If so we should not attempt
    % to do anything with this image so we will just continue to the next
    % image in the set.
    if HSPReduction.liCorruptFiles(iFITSObject), mprocessupdate(pid,iFITSObject/length(FITSList)); continue, end
    if ~HSPReduction.FieldSolutions(iFITSObject).wasFound
        HSPReduction.liCorruptFiles(iFITSObject) = true; 
        continue
    end
   
    TG = FITSList(iFITSObject).findstars;
    if isempty(TG), s = 2; else s = median(TG(5,:)); end
    
    % Copy the list of x and y positions of stars from the master
    % geometry. We will apply some geometric transforms to these positions
    % to obtain the location of these stars on the current image.
    x = MasterFieldTemplate(2,:);
    y = MasterFieldTemplate(3,:);
    
    
    try
    x = x+HSPReduction.FieldSolutions(iFITSObject).xxTranslationPreRotation;
    y = y+HSPReduction.FieldSolutions(iFITSObject).yyTranslationPreRotation;
    catch ME
        'uhoh'
        keyboard
    end
   
    
    [x,y] = mrotate(x,y,HSPReduction.FieldSolutions(iFITSObject).ttRotationAngle);
    
    x = x+HSPReduction.FieldSolutions(iFITSObject).xxTranslationPosRotation;
    y = y+HSPReduction.FieldSolutions(iFITSObject).yyTranslationPosRotation;        
    
       
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
mprocessfinish(pid,1);





end

