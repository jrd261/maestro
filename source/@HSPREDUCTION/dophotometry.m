function dophotometry(HSPReduction)
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
MasterField = HSPReduction.MasterFieldArray(1);
pid = mprocessinit('\n Performing aperture photometry...');

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
   
    % Copy the list of x and y positions of stars from the master
    % geometry. We will apply some geometric transforms to these positions
    % to obtain the location of these stars on the current image.
    x = MasterFieldTemplate(2,:);
    y = MasterFieldTemplate(3,:);
    s = HSPReduction.FieldSolutions(iFITSObject).GaussianSTD;
    
    dx = HSPReduction.FieldSolutions(iFITSObject).xxTranslation;
    dy = HSPReduction.FieldSolutions(iFITSObject).yyTranslation;
    
       
    % Obtain the sky removed image.
    flatimage = FITSList(iFITSObject).SkyRemovedPrimaryImage;
    image = FITSList(iFITSObject).CalibratedPrimaryImage;    
    noiseimage = FITSList(iFITSObject).NoisePrimaryImage;

            
    % Use a switch statement to determine the rotation style. The master
    % field array should be a scalar structure at this point but we
    % reference the first entry just to be sure.
    switch HSPReduction.MasterFieldArray(1).RotationStyle
        case 1
            % Rotation style 1 is no rotation. Record the cos and sine of
            % theta.
            C = 1; S = 0;
        case 2
            % Rotation style 2 means that a flip occurs. Check if the flip
            % happened before or after this object.
            if MasterField.RotationFlipIndex > iFITSObject
                if MasterField.RotationIsFlipInverted
                    C = -1; S = 0;
                else
                    C = 1; S = 0;
                end
            else
                % The flip happens before this object. Check if the flip is
                % inverted.
                if MasterField.RotationIsFlipInverted
                    C = 1; S = 0;
                else
                    C = -1; S = 0;
                end
            end                                            
        case 3
            rotationAngle = -(MasterField.JulianDate-FITSList(iFITSObject).JulianDate)/86400*2*pi;
            C = cos(rotationAngle); S = sin(rotationAngle);
        case 4                        
            rotationAngle = (MasterField.JulianDate-FITSList(iFITSObject).JulianDate)/86400*2*pi;
            C = cos(rotationAngle); S = sin(rotationAngle);
    end        
    
    % Apply the rotation and translation.
    
    xx = x; yy = y;
    x = xx*C+yy*S - dx*C - yy*S;
    y = -xx*S+yy*C - dy*C + dx*S;
                
             
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

