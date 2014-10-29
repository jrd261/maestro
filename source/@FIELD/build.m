function build(Field)
%BUILD Builds a field from the current object fits list.
%   Copyright (C) 2011 James Dalessio

%% PREPARE TO BUILD A MASTER FIELD
% We will need some things to be initialized before we really get underway.
% The configuration needs to be loaded as we will use it quite frequently
% in this method. An array to hold some tenative master fields and a
% structure for storing geometric solutions need to be initialized. A
% maestro process will be initialized as well.

% Extract the current maestro configuration. Several pieces of information
% will be extracted. It would probably be advantageous to list them here
% and this will be done in the future. This is sort of a collection of
% global variables. When called with no arguments the "MCONFIG" function
% returns the current maestro confugration. See "MCONFIG" for more
% information.
MaestroConfiguration = mconfig;

% Extract the current object FITS list. This retrieves the list of fits
% objects currently loaded into maestro. If there are no FITS objects
% currently loaded this function will throw an error so we are guarenteed
% to retrieve at least one fits object. For more information on what a fits
% object actually is see the maestro "FITS" object.
FITSList = mfits('retrieve','OBJECT');

% Initialize a structure to store master fields. This will store the geometry
% of the stars, galaxies and objects found on images.
% For more information about what this variable looks like when populated
% look near the end of the code. Also initialize a structure to contain
% information about the solution to each of the images to be processed.
% This will store the geometric transform required to take stars from this
% image and project them onto the master field. Both variables are
% written directly to the HSPReduction property by the same name when this
% routine completes.
MasterField = [];
rotationAngles = nan(length(FITSList),1);
rotationStyles = zeros(length(FITSList),1);
sVAL = nan(length(FITSList),3);
% This function can take some time to execute as all images will be loaded
% once if they are not already loaded. Use a process to keep the user
% notified as to the state of this function. Record the process ID "pid".
% See the "MPROCESSINIT" function for more information.
pid = mprocessinit(['\n Searching for stars on ',num2str(length(FITSList)),' images...']);

%% LOOP OVER ALL OBJECT FITS FILES
% We will loop over every FITS file in the list in a random order to get an
% idea of the geometry of stars on these images. Every file will be visited
% once.
counter = 0;
for iFITSObject = randperm(length(FITSList))
   
    solutionIsAcceptable = false;
    
    
    %FITSList(iFITSObject).
    
    % Extract the geometry of the sources on the current image. The
    % "findstars" method will return an nxm matrix containing m pieces of
    % information about the n stars on image. If no stars were found an
    % empty [] is returned. See the "findstars" method for more
    % information. The "FINDSTARS" method will eventually be replaced by a
    % static function. Record the target geometry and check that is is not
    % empty. If it is empty this image can tell us nothing about the
    % geometry of the images. Make sure to update the process (to display
    % the current status to the user). We then continue to the next image.            
    CTG = FITSList(iFITSObject).findstars; 
    
    
    
    if isempty(CTG), 
        FITSList(iFITSObject).clear; 
        mprocessupdate(pid,(counter+1)/length(FITSList)); 
        continue
    end
    
    % 
    if isempty(MasterField) || isempty(MasterField.Geometry)
        MasterField.Geometry = [CTG;zeros(1,size(CTG,2))];
        MasterField.JulianDate = FITSList(iFITSObject).JulianDate;
        MasterField.FieldName = datestr(now,'yyyymmdd_HHMMSS_FFF');
        MasterField.ReferenceFile = FITSList(iFITSObject).FileObject;
        
        MasterField.Signal = FITSList(iFITSObject).CalibratedPrimaryImage;
        MasterField.Noise = FITSList(iFITSObject).NoisePrimaryImage;
        MasterField.Range = [1,size(MasterField.Signal,2),1,size(MasterField.Noise,1)];      
        
        MasterField.Labels = {};
        
        continue
    else
        CMG = MasterField.Geometry;
    end
   
    
    %% LOOP OVER ALLOWED NUMBER OF SOURCES PER PERMUTATION
    % We will refer to sets of stars on the current images and other images
    % as "permutations". Starting with the maximum number of sources/stars
    % allowed in any individual permutation we will try to match the
    % current field the master field. If a suitable match is
    % found at any point in this loop, it is terminated and the match is
    % recorded.
    for NPS = min([size(CTG,2),size(CMG,2),MaestroConfiguration.MAX_SOURCES_PER_PERMUTATION]):-1:2
       
        % Initialize the number of target and master stars to use. Both of
        % these numbers will start at the current number of target and
        % master stars and will be decreased until the number of
        % permutations reaches some critical value.
        NUT = size(CTG,2);
        NUM = size(CMG,2);
        
        %% DETERMINE NUMBER OF MASTER AND TARGET STARS
        % The actual number of target and master stars would ideally be
        % "all of them" but there are computational issues with this.
        % Here we will ensure that the number of permutations that will
        % be generated will not exceed some customizable limit (in the
        % locale). The while loop will execute until the number of
        % target and master stars satisfies this limit or the number of
        % target or master stars gets too small.
        while NUT >= NPS && NUM >= NPS && nchoosek(NUT,NPS)*nchoosek(NUM,NPS) > MaestroConfiguration.MAX_SOURCE_PERMUTATIONS
            
            % Start an if else statement to determine whether to remove
            % master or target stars. The way this is chosen to be done
            % is to remove stars from whichever is larger. If they are
            % the same size we remove one from both.
            if NUT > NUM
                NUT = NUT - 1;
            elseif NUM > NUT
                NUM = NUM - 1;
            else
                NUT = NUT - 1;
                NUM = NUM - 1;
            end
        end
        
        % Check to see whether the number of master or target stars
        % dropped below the current number of stars per hash. This can
        % only really happen if the number of stars per hash is set to
        % a high value and the max hash permutations is very low. If
        % this is the case continue on to the next master field.
        if any([NUT,NUM]<NPS),continue, end
        
        %% BUILD PERMUTATION MATRICIES
        % Here we will generate sets of indicies we will refer to as
        % permutations. A permutation of target stars/sources might
        % look like [1,2,3,4] meaning stars/sources [1,2,3,4] are part
        % of this permutation. This code will simply generate all
        % possible combinations (n choose k, meaning [1,2,3,4] will be
        % generated but not [3,2,1,4]) of both target and master
        % stars/sources. Above we determined how many sources we could
        % include per permutation (NNS, in all of these examples I
        % included 4 but a permutation could look like [1,2,3,4,5]) and
        % how many stars we would take from the target and master
        % fields (NNT and NNS). This is limited in cases where too many
        % stars are present for computational purposes. The data will
        % have n rows, where n is the number of possible permuataions.
        % We store the data in the variables PPT and PPM for "Target
        % Permutations" and "Master Permutations" respectively. Note
        % that at this point the matricies PPT and PPM have no
        % relationship to eachother as they will in the future. The
        % only thing they have in common is the same number of
        % stars/sources per row. See the matlab built in function
        % NCHOOSEK for more information. Note the arrays are transposed
        % from the output of NCHOOSEK.
        PTP = nchoosek(1:NUT,NPS);
        PMP = nchoosek(1:NUM,NPS);
        
        %% ENSURE STAR ORDER INVARIANCE
        % The order of appearance of the stars in each permutation is
        % mildly random and as the permutations are nchoosek we do not
        % repeat the same permutation in a different order. What I mean
        % by this is that we will not have a permutation [1,2,3,4] and
        % [2,3,4,1], this combination will only appear once. It would
        % square the number of computations needed (at least) to use
        % all possible orders. Because we only used each permutation of
        % stars/sources once, we want to make sure that the order of
        % stars/sources is invarient, so that if [1,2,3] is the same on
        % the target image as stars/sources [3,2,4], but the order
        % generated is [2,3,4]. We need to ensure that the stars will
        % line up regardless. To accomplish this we will sort the order
        % of the stars/sources as to make the order, ie 1,2,3, spiral
        % the stars/sources out from the stars/sources average
        % position. In the case where there are only two stars this
        % method doesn't really work well. For two star cases we will
        % perform another algorithm.
        
        % The first thing to do is to extract the x and y positions for
        % each permutation. This will create nxm matricies where n is
        % the index of the permutation and m is the index of the stars
        % within the permutation. The name of the variables is XXM for
        % the x position of the master field etc. Remember that the 2nd
        % and 3rd rows of the GGM and TTM (which contain all of of the
        % information about the stars/sources on the target and master
        % images) store the x and y positions of the stars
        % respectively.
        XXM = reshape(CMG(2,PMP)',size(PMP));
        YYM = reshape(CMG(3,PMP)',size(PMP));
        XXT = reshape(CTG(2,PTP)',size(PTP));
        YYT = reshape(CTG(3,PTP)',size(PTP));
        
        % Calculate the mean of each.
        XXM_0 = mean(XXM,2);
        YYM_0 = mean(YYM,2);
        XXT_0 = mean(XXT,2);
        YYT_0 = mean(YYT,2);
        
        % For each permutation calculate the mean x and y values and
        % subtract these values from the the x and y values
        % respectively. We have to use REPMAT to make the size of the
        % mean of each permutation equal to the size of each
        % permutation. Sort the resultant permutations (along the
        % direction of the stars). This will return the sorted matrix
        % (which we dont care about) and indicies reflected the order
        % things were sorted by, ie... [1,2,3,4;4,3,1,2;3,2,4,1].
        [junk,IIM] = sort((XXM-repmat(XXM_0,[1,NPS])).^2+(YYM-repmat(YYM_0,[1,NPS])).^2,2); %#ok<ASGLU>
        [junk,IIT] = sort((XXT-repmat(XXT_0,[1,NPS])).^2+(YYT-repmat(YYT_0,[1,NPS])).^2,2); %#ok<ASGLU>
        
        % We have used some memory to store variables that are no
        % longer needed. The only thing created in this section that is
        % needed later are the sorted permutation matricies. Clear
        % everything else.
        clear XXM YYM XXT YYT junk
        
        % The sort function is not very effective for reordering
        % everything. The sorted matrix cannot simply be evaluated at
        % the returned indicies as they are with respect to each row,
        % not to the whole matrix. We need to convert the indicies for
        % simple reference. The indicies are transposed, essentilly added to a
        % correction matrix, and transposed back. Its sort of a
        % convoluted idea and someone should write a smarter sort
        % function.
        PMP = PMP'; PMP = PMP(IIM'+repmat((0:size(PMP,2)-1)*NPS,[NPS,1]))';
        PTP = PTP'; PTP = PTP(IIT'+repmat((0:size(PTP,2)-1)*NPS,[NPS,1]))';
        
        % Clean up the indicies used to reference the sort order.
        clear IIM IIT
        
        % In the case that there are only two stars the order is arbitrary.
        % Make a copy of all of the permutations. The 
        if NPS == 2, PTP = [PTP;[PTP(:,2),PTP(:,1)]]; PMP = [PMP;[PMP(:,2),PMP(:,1)]]; end
        
        %% GENERATE PERMUTATIONS FOR ALL POSSIBLE SOLUTIONS
        % Right now the PPM and PPT permutation matricies have nothing
        % to do with eachother, only that they hold all possible
        % permutations of target and master stars. We will now generate
        % a permutation in each matrix that corresponds to the other
        % matrix. This means the total number of permutations in each
        % of the matricies will now be the same and that each has a one
        % to one correspondence to the other. We now call these
        % corresponding sets of permutations "possible solutions"
        
        % Make as many copies of the master and target permutations.
        % These matricies will have the same style as the permutation
        % matrix did before we modified it.  The master permutation
        % matrix is a rather simple calculation, while the target
        % permutation matrtix was a little tougher.
        PMP = repmat(PMP,[size(PTP,1),1]);
        PTP = reshape(repmat(PTP',[size(PMP,1)./size(PTP,1),1]),[NPS,size(PMP,1)])';
        
        %% ROTATE THE TARGET COORDINATES
        % Unforunately the target images may be rotated with respect to
        % the master field. There are four possibilities for rotation.
        % The first is no rotation, then flipping, CCW 1/day, and CW
        % 1/day. We will take the current possible solutions and copy
        % each of them so that the solution exists 4 times. For each
        % one of those solutions we will rotate the target field in
        % each of these patterns. This will allow us to completely
        % forget about rotation as a degrree of freedom and sacrifice
        % 4 times computational efficiency. IMO the robustness of this
        % process is worth the extra computation.
        
        % First increase the number of possible solutions by a factor
        % of four. What this essentially does is make four copies of
        % all of the current solutions. Each of these four copies will
        % be assigned a different style of rotation. We have to make
        % copies of all of the brightness ratio information as well.
        PMP = repmat(PMP,[3,1]);
        PTP = repmat(PTP,[3,1]);
        NAS = size(PTP,1);
        
        % Generate indicies to refer to the rotation type that will be
        % applied to these solutions. By quarters the first will be not
        % rotated, the second flipped, the third rotated ccw and the
        % forth rotated cw. This will allow us to track which rotation
        % type was applied to which solution. For future simplicity we
        % also record the indicies for each quartile. These are stored
        % in the variables IIX where X stands for the quartile being
        % referenced. RRI will simply have an entry for each solution
        % indicating the style of rotation that was applied to that
        % solution.
        PRS = reshape(repmat(1:3,[NAS/3,1]),[NAS,1]);
        liR1 = PRS==1;
        liR2 = PRS==2;
        liR3 = PRS==3;                                  
        PRA = zeros(NAS,1);
        
        % We are going to be playing a bit with the geometry between
        % the target and the master fields. Extract the X and Y
        % coordinates for all target solutions.
        XXT = reshape(CTG(2,PTP)',[NAS,NPS]);
        DXT = reshape(CTG(6,PTP)',[NAS,NPS]);
        YYT = reshape(CTG(3,PTP)',[NAS,NPS]);
        DYT = reshape(CTG(7,PTP)',[NAS,NPS]);
        
        XXM = reshape(CMG(2,PMP)',[NAS,NPS]);
        DXM = reshape(CMG(6,PMP)',[NAS,NPS]);
        YYM = reshape(CMG(3,PMP)',[NAS,NPS]);
        DYM = reshape(CMG(7,PMP)',[NAS,NPS]);
                
        xxTranslationsPreRotation = -mean(XXT,2);       
        yyTranslationsPreRotation = -mean(YYT,2);
        xxTranslationsPosRotation = mean(XXM,2);
        yyTranslationsPosRotation = mean(YYM,2);
        
        PRA(liR1) = 0;
        PRA(liR2) = pi;
        TAngles = atan((YYT(liR3,:)+repmat(yyTranslationsPreRotation(liR3),[1,NPS]))./(XXT(liR3,:)+repmat(xxTranslationsPreRotation(liR3),[1,NPS])));
        MAngles = atan((YYM(liR3,:)-repmat(yyTranslationsPosRotation(liR3),[1,NPS]))./(XXM(liR3,:)-repmat(xxTranslationsPosRotation(liR3),[1,NPS])));
        PRA(liR3) = median(MAngles-TAngles,2);
        
        
      
        
        XXT = XXT + repmat(xxTranslationsPreRotation,[1,NPS]);
        YYT = YYT + repmat(yyTranslationsPreRotation,[1,NPS]);
        
        
        
        % Do flip.
        YYT(liR2,:) = -YYT(liR2,:);
        XXT(liR2,:) = -XXT(liR2,:);
        
        XXT_TEMP = XXT(liR3,:);
        YYT_TEMP = YYT(liR3,:);
        
        XXT(liR3,:) = XXT_TEMP.*repmat(cos(PRA(liR3)),[1,NPS])-YYT_TEMP.*repmat(sin(PRA(liR3)),[1,NPS]);
        YYT(liR3,:) = XXT_TEMP.*repmat(sin(PRA(liR3)),[1,NPS])+YYT_TEMP.*repmat(cos(PRA(liR3)),[1,NPS]);
        
        XXT = XXT + repmat(xxTranslationsPosRotation,[1,NPS]);
        YYT = YYT + repmat(yyTranslationsPosRotation,[1,NPS]);
                                                     
        
        %% FIND THE BEST MATCHES
        % We have already ensured that for each possible solution the
        % relative brightness of stars agrees down to some reduced chi
        % squared. A more telling constraint is to force the stars to line
        % up geometrically in the x y plane. We have already generated a possible match for
        % each possible rotation angle. At this point a simple translation
        % should line up each set of stars. We will calculate the X and Y
        % translation required to minimize chi2, apply this translation,
        % and than eliminate solutions which do not match well enough.              
       
        DR = repmat(median(reshape(CMG(5,PMP)',[NAS,NPS]),2),[1,NPS]);
        
      
        
        % Calculate the reduced chi squared for R, the total distance
        % between the target and master fields stars. The number of
        % degrees of freedom is the number of stars per permutation
        % times 2 (because of two dimensions) minus 2 (one for each
        % translational direction). If you do not agree with me on that
        % please let me know, I'm not extremely confident about it.
        % First we calculate the distance squared between the two
        % fields (after translation), than reduced chi squared. As the
        % distance squared between the two fields appears multiple
        % times in the calculation for reduced chi2 this should save us
        % some time.
        xxDistance2 = (XXT-XXM).^2;
        yyDistance2 = (YYT-YYM).^2;
        
        %possibleTranslationalRChi2s = sum((xxDistance2+yyDistance2).^2./(xxDistance2.*(DXM.^2+DXT.^2)+yyDistance2.*(DYM.^2+DYT.^2)),2)./(NPS*2-2-(PRS>1));
        possibleTranslationalRChi2s = sum((xxDistance2+yyDistance2).^2./(xxDistance2.*DR.^2+yyDistance2.*DR.^2),2)./(NPS*2-2-2*(PRS==3));                
        possibleTranslationalRChi2s(PRS==3) = possibleTranslationalRChi2s(PRS==3)*10;
        % Find all of the absolute indicies for which the reduced chi squared is
        % below some critical threshold. This will create a numeric
        % array indicating which solutions matched. If solutions 2 and
        % 4 had a reduced chi2 better than our threshold the value for
        % "translationalMatchIndicies" would be [2,4]. We also want to
        % ensure that only these solutions are still included in our
        % solution matricies. Evalutating these matricies at these
        % indicies will do the trick. Also the rotation type needs to
        % be tracks so we will know what rotation was applied to each
        % solution. Evaluate that array at the match indicies to obtain
        % the new rotation type array.
        goodSolutionIndicies = find(possibleTranslationalRChi2s<MaestroConfiguration.POSITION_MATCH_MAX_ACHI2);
        [junk,goodSolutionIndiciesOrder] = sort(possibleTranslationalRChi2s(goodSolutionIndicies)); goodSolutionIndicies = goodSolutionIndicies(goodSolutionIndiciesOrder);   %#ok<ASGLU>
        
        PMP = PMP(goodSolutionIndicies,:);
        PTP = PTP(goodSolutionIndicies,:);
        PRS = PRS(goodSolutionIndicies); 
        PRA = PRA(goodSolutionIndicies);
        xxTranslationsPreRotation = xxTranslationsPreRotation(goodSolutionIndicies);
        yyTranslationsPreRotation = yyTranslationsPreRotation(goodSolutionIndicies);
        xxTranslationsPosRotation = xxTranslationsPosRotation(goodSolutionIndicies);
        yyTranslationsPosRotation = yyTranslationsPosRotation(goodSolutionIndicies);
       
        
        %% BEGIN LOOP OVER POSSIBLE SOLUTIONS
        % At this point most of these solutions are probably valid.
        % However, we will still investigate further to ensure we find
        % a solution that is truely ok. This is especially important if
        % multiple fields have accidentally been mixed up into these
        % images. The loop is indexed by "iSolution" and we will plan
        % to iterate over all of the solutions which \matched the
        % brightness and position tests. However, if a possible
        % solution passes some criteria we will not go any further and
        % we will then call this the final solution.
        for iSolution = 1:min(1,length(goodSolutionIndicies))
                      
            
            %% PREPARE TO INVESTIGATE THE SOLUTION
            % Only a limited number of stars were used to generate this
            % possible solution (due to computational limitations). The
            % current possible solution (which master stars are which
            % target stars) will be used. Most possible solutions
            % that reach this point are really solutions.
            
            % First extract the current permutation of target and
            % master stars.Remember that each row of the target and
            % master solution matricies contain a possible solution
            % with indicies refering to stars within the master and
            % target fields. We will extract the "current solution",
            % meaning the "possible solution" that we are working on
            % currently.
            try
            CTS = PTP(iSolution,:);
            CMS = PMP(iSolution,:);
            MTG = CTG(:,CTS);
            MMG = CMG(:,CMS);
            catch ME
                keyboard
            end
            
            % Make a copy of the total master and target geometry. We
            % will remove the current solution from the geometry so we
            % will name this matrix "leftover". Use the indicies from
            % the current solution to eliminate all matching stars. The
            % leftover  geometry will list all stars that have not been
            % matched. Some of these could be matches but wern't
            % sampled above.
            LTG = CTG;
            LTG(:,CTS) = [];
            LMG = CMG;
            LMG(:,CMS) = [];
            
            %% APPLY ROTATION TO BOTH GEOMETRIES
            % We also already know the rotation angle for this solution
            % (the angle to go from the target to master image). We can
            % rotate every leftover target star and master star right
            % now and save some computation later. We will make a copy
            % of the target and master leftover geometry that will be
            % project onto the other geometry. I.e. rotated, scaled and
            % shifted to line up.
            LPTG = LTG;
            LPMG = LMG;
            MPTG = MTG;
            
            % Check what type of rotation was applied to find a
            % solution. For each type of rotation record the
            % "ttCurrentRotationAngle". This will be used to rotate the
            % data
            LPTG(2,:) = LPTG(2,:) + xxTranslationsPreRotation(iSolution);
            LPTG(3,:) = LPTG(3,:) + yyTranslationsPreRotation(iSolution);
            
            LPMG(2,:) = LPMG(2,:) - xxTranslationsPosRotation(iSolution);
            LPMG(3,:) = LPMG(3,:) - yyTranslationsPosRotation(iSolution);
            
            MPTG(2,:) = MPTG(2,:) + xxTranslationsPreRotation(iSolution);
            MPTG(3,:) = MPTG(3,:) + yyTranslationsPreRotation(iSolution);
            
            [LPTG(2,:),LPTG(3,:)] = mrotate(LPTG(2,:),LPTG(3,:),PRA(iSolution));
            [MPTG(2,:),MPTG(3,:)] = mrotate(MPTG(2,:),MPTG(3,:),PRA(iSolution));
            [LPMG(2,:),LPMG(3,:)] = mrotate(LPMG(2,:),LPMG(3,:),-PRA(iSolution));
                        
            LPTG(2,:) = LPTG(2,:) + xxTranslationsPosRotation(iSolution);
            LPTG(3,:) = LPTG(3,:) + yyTranslationsPosRotation(iSolution);
            
            LPMG(2,:) = LPMG(2,:) - xxTranslationsPreRotation(iSolution);
            LPMG(3,:) = LPMG(3,:) - yyTranslationsPreRotation(iSolution);
            
            MPTG(2,:) = MPTG(2,:) + xxTranslationsPosRotation(iSolution);
            MPTG(3,:) = MPTG(3,:) + yyTranslationsPosRotation(iSolution);
         
       
            
            %% APPLY SCALING AND TRANSLATION
            % We want to project the master and target fields onto
            % eachother. Use the calculated values to apply this
            % translation and scaling to the unmatched stars. This also
            % scales the statistics of the star brightness.
            mmRatio = median(MMG(4,:)./MTG(4,:));            
            MPTG(4,:) = MPTG(4,:)*mmRatio;
            MPTG(8,:) = MPTG(8,:)*mmRatio;                     
            LPTG(4,:) = LPTG(4,:)*mmRatio;
            LPTG(8,:) = LPTG(8,:)*mmRatio;
            LPMG(4,:) = LPMG(4,:)/mmRatio;
            LPMG(8,:) = LPMG(8,:)/mmRatio;
        
            
            %% FIND GEOMETRIC MATCHES BETWEEN UNKNOWN STARS
            % There are likely matches between the master and target
            % fields that were not found in our original solution. We
            % will use the current proejction of the target onto the
            % master to check for solutions that match geometrically. We
            % do not care about brightness anymore.
            
            % Obtain the distance between all target and master stars
            % that have not been matched. To do this we will generate a
            % matrix indeced by target stars in the first dimension and
            % master stars in the second dimension. Note we are
            % subtracting the projected target (meaning projected into
            % master coordinates) from the master.
            DXTM = repmat(LPTG(2,:),[size(LMG,2),1])-repmat(LMG(2,:)',[1,size(LPTG,2)]);
            DYTM = repmat(LPTG(3,:),[size(LMG,2),1])-repmat(LMG(3,:)',[1,size(LPTG,2)]);
            
            % Another piece of information we will need to figure out if
            % any of these stars match is the total variance (combined master and target) in both the
            % x and y direction.
            dxTotalVariance = repmat(LPTG(6,:).^2,[size(LMG,2),1])+repmat(LMG(6,:)'.^2,[1,size(LPTG,2)]);
            dyTotalVariance = repmat(LPTG(7,:).^2,[size(LMG,2),1])+repmat(LMG(7,:)'.^2,[1,size(LPTG,2)]);
            
            % Now calculate the value of reduced chi squared for every
            % combination of leftover target and master stars. This is
            % essentially the goodness of fit between the master and
            % target leftover stars given our solution. The degrees of
            % freedom is 2 because we have two stars and the fit parameters
            % were not found from these variables. If you object to this
            % let me know.
            possibleNewMatchesRChi2s = (DXTM.^2+DYTM.^2).^2./(dxTotalVariance.*DXTM.^2+dyTotalVariance.*DYTM.^2);
            
            % Obtain the absolute indicies of the target and master stars
            % that matched. Each of these should be nx1 arrays of
            % indicies relative to the leftover stars in the master and
            % target geometry respectively.
            [aiIndirectMasterMatches,aiIndirectTargetMatches] = ind2sub(size(DXTM),find(possibleNewMatchesRChi2s<4 | (DXTM.^2+DYTM.^2).^(1/2)<1));
            
            % Remove the stars that matched. These stars were most likely
            % not matched earlier due to computational limitations. We
            % will just remove them from the leftover and projected
            % geometry.     
            
            aiNEWIndirectMasterMatches = LPMG(1,aiIndirectMasterMatches);

            LTG(:,aiIndirectTargetMatches) = [];
            LPTG(:,aiIndirectTargetMatches) = [];
            LMG(:,aiIndirectMasterMatches) =[];
            LPMG(:,aiIndirectMasterMatches) = [];
            
            
            %% OBTAIN INFORMATION ABOUT UNMATCHED MASTER STARS
            % For each unmatched master star we will check if it should
            % have been on image. If so we will test if the image is
            % consistent with that star having been there. If there are
            % lots of master stars that statisically aren't there on
            % the target image we might have a faulty solution. Also
            % there are master stars that might just have been cosmic
            % rays. This will also help distinguish those.
            
            % Initialize an array to keep track of whether each unmatched master
            % star is: 0 - Off the target image, 1 - On the image,
            % consistent with pixel value, 2 - On the image and
            % inconsistent.
            leftoverConsistencyType = zeros(size(LPMG,2),1);
            
            % Extract the image. These images
            % represent the signal and noise. We will use the
            % statistics here to compare with the master field. The
            % signalImage is the calibrated image with the sky
            % approximately removed. Note the signal image can have
            % negative values so we should be careful with square roots
            % and such. The noise image contains the standard deviation
            % of each pixel of the signal image.
            signalImage = FITSList(iFITSObject).SkyRemovedPrimaryImage;
            noiseImage = FITSList(iFITSObject).NoisePrimaryImage;
            
            % Extract the size of the images. We need to know the image
            % size to test if the unknown master stars should be on the
            % images.
            [yImageSize,xImageSize] = size(signalImage);
            
            % Loop over the unknown master stars. For each star we will
            % check if it is on image. If so, we will check if it is
            % consistent with the supposed amplitude and record the
            % result in the "unmatchedType" array.
            for iStar = 1:size(LPMG,2)
                
                % SOME LPMG ARE NAN, MUST FIX THIS!
                
                % Check image size. If the position of the supposed
                % star is off image we can get no information about
                % whether this solution appears correct or whether this
                % is really a master star. The value for this star in
                % "unmatchedType" is already zero so we can just
                % continue on.
                if LPMG(2,iStar) < 1 || LPMG(2,iStar) > xImageSize || LPMG(3,iStar) < 1 || LPMG(3,iStar) > yImageSize || any(isnan(LPMG(2:3,iStar))), continue, end
                
                % Calculate chi2 for this star. A value of 9 for chi
                % means that the amplitude on image is within 3 sigma
                % of the master value.
                statisticalDifference = (LPMG(4,iStar)-signalImage(round(LPMG(3,iStar)),round(LPMG(2,iStar)))).^2/(noiseImage(round(LPMG(3,iStar)),round(LPMG(2,iStar))).^2+LPMG(8,iStar)^2+MaestroConfiguration.MAX_SOURCE_VARIABILITY^2*(LPMG(4,iStar)^2+signalImage(round(LPMG(3,iStar)),round(LPMG(2,iStar)))));
                
                % If the statistical difference is greater than the  we will record the image as bad (2), otherwise we
                % will record it as good (1).
                if statisticalDifference>MaestroConfiguration.BRIGHTNESS_MATCH_MAX_REDUCED_CHI2, leftoverConsistencyType(iStar) = 2; else leftoverConsistencyType(iStar) = 1; end
                
            end
            
            %% CHECK IF SOLUTION IS VALID
            % We will now sum up the staritude of all stars that were
            % detected and all stars that were inconsistant with being
            % on the image. If the ratio of these two numbers is above
            % some threshold the solution is acceptable. The staritude
            % of a star is a measurement of how confident we are that
            % master star that it exists.
            
            % Add together the staritude of all matched master stars.
            % We will call this "totalGoodStaritude" as it is the total
            % amount of staritude coming from stars that matched on the
            % target image. Staritude is stored in the tenth column of
            % the geometry.
            try
            totalGoodStaritude = sum(CMG(10,[CMS,aiIndirectMasterMatches']));
            catch ME
                ME
                keyboard
            end
                
            
            
            
            % Add together the staritude of all unmatched master stars
            % which were statistically inconsistant with the target
            % image (the entries in unmatchedType with index 2)
            totalBadStaritude = sum(LPMG(10,leftoverConsistencyType==2));
            
            % Check if the ratio of "totalBadStaritude" to
            % "totalGoodStaritude" is above some critical threshold
            % specified in the config as
            % "MAX_BAD2GOOD_STARITUDE_RATIO". If it is, this solution
            % in unacceptable and we will continue onto the next
            % possible solution.
            if totalBadStaritude/totalGoodStaritude > MaestroConfiguration.STARITUDE_MAX_BAD2GOOD_RATIO, continue, end
            
            % If we have reached this point our final solution for this
            % image has been found!
            
            
            
            %% UPDATE MATCHED FIELD GEOMETRY
            % Now that we are sure that the solution is good we should
            % update the geometry of the master field. To do this we
            % will average together the "matchedTargetGeometry" with
            % the geometry in "matchedMasterGeometry". After we are finished
            % merging the two we will copy the "matchedMasterGeometry"
            % back into the master field.
            
            % The x and y positions need to be merged. Combine them
            % using the errors in x and y (recipriol variance) as
            % weights. Remember to include the translation in the error
            % terms. given some X1 X2 and DX1 DX2 this is just the formula...
            % |X| = (X1/DX1^2+X2/DX2^2)/(1/DX1^2+1/DX2^2)
            XXW1 = 1./(MPTG(6,:).^2);
            XXW2 = 1./(MMG(6,:).^2);
            YYW1 = 1./(MPTG(7,:).^2);
            YYW2 = 1./(MMG(7,:).^2);
            %ZZW1 = 1./(MPTG(8,:).^2+dmPossibleMasterToTargetBrightnessRatios(iSolution)^2);
            %ZZW2 = 1./(matchedMasterGeometry(8,:).^2);
            
            MasterField.Geometry(2,CMS) = (MPTG(2,:).*XXW1+MMG(2,:).*XXW2)./(XXW1+XXW2);
            MasterField.Geometry(3,CMS) = (MPTG(3,:).*YYW1+MMG(3,:).*YYW2)./(YYW1+YYW2);
            
            % Now take care of the errors. The square error in the master
            % positions is just 1 over the sum of the weights.
            %    MasterFieldArray(iMasterField).Geometry(6,currentMasterSolution) = 1./(XXW1+XXW2).^(1/2);
            %    MasterFieldArray(iMasterField).Geometry(7,currentMasterSolution) = 1./(YYW1+YYW2).^(1/2);
            
            % Now we need to update the brightness of the stars by
            % merging the two images. This is pretty much the same
            % calculation as above except with a scaling factor instead
            % of an offset.
            %MasterField.Geometry(4,currentMasterSolution) = (MPTG(4,:).*ZZW1+matchedMasterGeometry(4,:).*ZZW2)./(ZZW1+ZZW2);
            %   MasterFieldArray(iMasterField).Geometry(8,currentMasterSolution) = 1./(ZZW1+ZZW2).^(1/2);
            
            %% UPDATE STARITUDE
            % The master stars that directly matched stars on the
            % target field deserve some love. We will add one to their
            % staritude. This will give them more weight in the future
            % when checking if a solution is valid. Its sort of saying
            % I now believe that there is really a star in this
            % position a little more than before.
            MasterField.Geometry(10,CMS) = MasterField.Geometry(10,CMS)+MaestroConfiguration.STARITUDE_DIRECT_MATCH_BONUS;
            
            % Stars that were matched after the fact, i.e. were not
            % included in the initial solution but still were matched
            % will also get a bonus to their staritude.
            % Here something funny!
            MasterField.Geometry(10,aiNEWIndirectMasterMatches) = MasterField.Geometry(10,aiNEWIndirectMasterMatches)+MaestroConfiguration.STARITUDE_INDIRECT_MATCH_BONUS;
            try
            % Stars that were off of the image get what should be a small
            % penalty. We really can't say anything about whether or not
            % they are there. If they show up several times this penalty
            % shouldn't be bad enough to kill them off.
            MasterField.Geometry(10,LMG(1,leftoverConsistencyType==0)) = MasterField.Geometry(10,LMG(1,leftoverConsistencyType==0)) - MaestroConfiguration.STARITUDE_OFF_IMAGE_PENALTY;
            catch ME
                ME
                keyboard
            end
            % The stars which were in agreement with the image but were
            % not detected as stars. Their staritude will slowly decay as
            % other stars are matched. The decay rate is controlled by
            % the config. The real purpose of this is in case one bad
            % match occurs. In this case thse stars would slowly fade
            % away even if they are off image. It also gets rid of some
            % really faint stars that aren't worth caring about. Think
            % about this as saying "We are punishing these stars for not
            % showing up enough."
            MasterField.Geometry(10,LMG(1,leftoverConsistencyType==1)) = MasterField.Geometry(10,LMG(1,leftoverConsistencyType==1)) - MaestroConfiguration.STARITUDE_CONSISTANCY_PENALTY;
            
            % The stars that were not in agreement with the image get
            % punished severely.
            MasterField.Geometry(10,LMG(1,leftoverConsistencyType==2)) = MasterField.Geometry(10,LMG(1,leftoverConsistencyType==2)) - MaestroConfiguration.STARITUDE_DISAGREEMENT_PENALTY;
            
            % Remove stars that have a negative staritude.
            MasterField.Geometry(:,MasterField.Geometry(10,:)<0) = [];
            
            
            %% ADD NEW MASTER STARS
            % The unmatched target stars will all be added to the
            % master field with zero staritude.
            
            MasterField.Geometry = [MasterField.Geometry,[LPTG;zeros(1,size(LPTG,2))]];
            MasterField.Geometry(1,:) = 1:size(MasterField.Geometry,2);
            
            if NPS > 2
                rotationAngles(iFITSObject) = PRA(iSolution);
                if rotationAngles(iFITSObject) == 0
                    rotationStyles(iFITSObject) = 1;
                elseif rotationAngles(iFITSObject) == pi
                    rotationStyles(iFITSObject) = 2;
                else 
                    rotationStyles(iFITSObject) = 3;
                end
               
            end
            
            
            
            solutionIsAcceptable = true;                                                           
                        
 
            Z1 = MasterField.Signal;
            N1 = MasterField.Noise;            
            [X1,Y1] = meshgrid(MasterField.Range(1):MasterField.Range(2),MasterField.Range(3):MasterField.Range(4));
                                              
            Z2 = FITSList(iFITSObject).CalibratedImage*mmRatio;            
            N2 = FITSList(iFITSObject).NoisePrimaryImage*mmRatio;                                    
            [X2,Y2] = meshgrid(1:size(Z2,2),1:size(Z2,1));
            X2 = X2 + xxTranslationsPreRotation(iSolution);
            Y2 = Y2 + yyTranslationsPreRotation(iSolution);
            [X2,Y2] = mrotate(X2,Y2,PRA(iSolution));
            X2 = X2 + xxTranslationsPosRotation(iSolution); X2 = round(X2);
            Y2 = Y2 + yyTranslationsPosRotation(iSolution); Y2 = round(Y2);
                                                
            X_Min = round(min([X1(:);X2(:)]));
            Y_Min = round(min([Y1(:);Y2(:)]));
            X_Max = round(max([X1(:);X2(:)]));
            Y_Max = round(max([Y1(:);Y2(:)]));            
            
                        
            X1_I = X1 - X_Min + 1;
            Y1_I = Y1 - Y_Min + 1;
            
            X2_I = X2 - X_Min + 1;
            Y2_I = Y2 - Y_Min + 1;   
                                    
            [X,Y] = meshgrid(X_Min:X_Max,Y_Min:Y_Max);
            
            Z4 = zeros(size(X));            
            N4 = inf(size(X));
            Z5 = zeros(size(X));
            N5 = inf(size(X));
                        
            Z4(sub2ind(size(X),Y1_I(:),X1_I(:))) = Z1;
            N4(sub2ind(size(X),Y1_I(:),X1_I(:))) = N1;
            Z5(sub2ind(size(X),Y2_I(:),X2_I(:))) = Z2;
            N5(sub2ind(size(X),Y2_I(:),X2_I(:))) = N2;

            Z = (Z4./N4.^2 + Z5./N5.^2)./(1./N4.^2+1./N5.^2);
            N = 1./(1./N4.^2+1./N5.^2).^(1/2);
            
            MasterField.Signal = Z;
            MasterField.Noise = N;
            MasterField.Range = [X_Min,X_Max,Y_Min,Y_Max];
                                           
            break                       
           
        end
        
        sVAL(iFITSObject,:) = [min(MTG(5,:)),median(MTG(5,:)),max(MTG(5,:))];
        
        if solutionIsAcceptable, break, end
        
    end
    try
    if ~solutionIsAcceptable
       
        MasterField.Geometry(10,:) = MasterField.Geometry(10,:) - 1;
        MasterField.Geometry(:,MasterField.Geometry(10,:)< 0) = [];
        MasterField.Geometry(1,:) = 1:size(MasterField.Geometry,2);
        if isempty(MasterField.Geometry)
            rotationAngles(rotationAngles > 0) = nan;  
            rotationStyles(rotationStyles > 0) = 0;
        end
    end
    catch ME
        ME
        keyboard
    end
    
    %% UPDATE THE PROCESS
    % Update the process.We update the process after each image is
    % analysed.  
    counter = counter + 1;

    mprocessupdate(pid,counter/length(FITSList));
    FITSList(iFITSObject).clear;
    
end

mprocessfinish(pid,1);
            
    
    MasterField.Geometry = MasterField.Geometry(:,MasterField.Geometry(10,:)>length(FITSList)*.01);
    
   mtalk(['\n Field built containing ',num2str(size(MasterField.Geometry,2)),' stars.']);
    %% COPY RELAVANT INFORMATION
    % We will now record the information obtained in this function
    
    % All that needs to be recorded is the master field array and the field solutions.
    % The master field array ("MasterFieldArray") contains one or multiple master fields
    % (configurations of stars found on the images). The field solutions
    % ("FieldSolutions") contain the information needed to know how to perform    % a geometric transformation on each image to line that images stars up
    % with one of the master fields. It also contains statistical information
    % about the process and several pieces of information that may be useful to
    % store. For information about these variables see the properties
    % "MasterFieldArray" and "FieldSolutions" of the HSPREDUCTION user defined
    % class. The current HSPREDUCTION object is stored in the variable
    % "HSPReduction" in this workspace. Write the information into the relavant
    % properties...
    
    
    
    %% DETERMINE ROTATION STYLE OF EACH MASTER FIELD
    
    
    MasterField.Labels = cell(size(MasterField.Geometry,2),1);
    for iStar = 1:size(MasterField.Geometry,2)
        MasterField.Labels{iStar} = ['Unknown',num2str(iStar)];
    end
    
    
    
    n1 = length(nonzeros(rotationStyles == 1));
    n2 = length(nonzeros(rotationStyles == 2));
    n3 = length(nonzeros(rotationStyles == 3));
    
    Config = MaestroConfiguration;
    
    if strcmp(Config.FIELD_ROTATION_STYLE,'AUTO')
        if n1+n2 < n3
            mconfig('FIELD_ROTATION_STYLE','ROTATING');
            julianDates = [FITSList.JulianDate]';
            data = [julianDates(rotationStyles==3),rotationAngles(rotationStyles==3)];
            mconfig('FIELD_ROTATION_DATA',data);
        else
            
            RNoFlip = length(nonzeros(nonzeros(rotationStyles)~=1));
            RFlip = Inf;
            FlipIndex = 0;
            isINV = false;
            
            for iFITSObject = 1:length(FITSList)
                RREG = length(nonzeros([nonzeros(rotationStyles(1:iFITSObject-1))~=1;nonzeros(rotationStyles(iFITSObject:length(rotationStyles)))~=2]));
                RINV = length(nonzeros([nonzeros(rotationStyles(1:iFITSObject-1))~=2;nonzeros(rotationStyles(iFITSObject:length(rotationStyles)))~=1]));
                
                
                if RREG < RFlip
                    RFlip = RREG;
                    FlipIndex = iFITSObject;
                    isINV = false;
                end
                
                if RINV < RFlip
                    RFlip = RINV;
                    FlipIndex = iFITSObject;
                    isINV = true;
                end
            end
            
            if RNoFlip<=RFlip
                mconfig('FIELD_ROTATION_STYLE','NORMAL');
            else
                mconfig('FIELD_ROTATION_STYLE','FLIP');
                mconfig('FIELD_ROTATION_DATA',[FlipIndex,isINV]);
            end
            
        end
        
    end
    
    Field.JulianDate = MasterField.JulianDate;
    Field.Signal = MasterField.Signal;
    Field.Noise = MasterField.Noise;
    Field.Range = MasterField.Range;
    Field.Rotation = [[FITSList.JulianDate]',rotationAngles];
    
    
    Field.Labels = MasterField.Labels;
    
    
    
   
    
   
    
     noiseThreshold = MaestroConfiguration.STAR_FINDING_NOISE_THRESHOLD;
    noiseThreshold = 20;
    MaestroConfiguration.STAR_FINDING_MAX_STARS = Inf;
    maxPercentagePossibleStars = MaestroConfiguration.STAR_FINDING_MAX_PERCENT_POSSIBLE_STARS;
    sigmaEstimated = MaestroConfiguration.STAR_FINDING_SIGMA_ESTIMATED;
    searchBoxSize = ceil(MaestroConfiguration.STAR_FINDING_SEARCH_BOX_SIZE*sigmaEstimated);
    maxLinear = MaestroConfiguration.MAX_LINEAR;
    
    
    s = sVAL;
    
    crCutoff = nanmedian(s(:,1)) - 5*mrobuststd(s(:,1));        
    galaxyCutoff = nanmedian(s(:,3)) + 5*mrobuststd(s(:,3));    
    sguess = nanmedian(s(:,2));
    
    ssGuess = sguess;
    sigmaGuess = sguess;
    
   % galaxyCutoff = 10;
   % crCutoff = 0;
    fitInitialLambda = MaestroConfiguration.STAR_CENTERING_PRELIMINARY_FIT_LAMBDA;
    fitTolerance = MaestroConfiguration.STAR_CENTERING_PRELIMINARY_FIT_TOLERANCE;
    fitIterations = MaestroConfiguration.STAR_CENTERING_PRELIMINARY_FIT_ITERATIONS;
    lambdaMultiplier = MaestroConfiguration.STAR_CENTERING_PRELIMINARY_FIT_LAMBDA_MULTIPLIER;
    minConvergence = MaestroConfiguration.STAR_CENTERING_PRELIMINARY_FIT_MIN_CONVERGENCE;
    
    
    % Extract the signal and the noise of the master field.
    signalImage = Field.Signal; noiseImage = Field.Noise;
                   
    
     
     
     % Assume we have signalImage and noiseImage
    
    SEARCH_BOX_SIZE = Config.DEV_FIELD_BUILDING_SEARCH_BOX_SIZE; 
    CENTERING_BOX_SIZE = Config.DEV_FIELD_BUILDING_CENTERING_BOX_SIZE;
    
    
    [yImageSize,xImageSize] = size(signalImage);        
    [xGrid,yGrid] = meshgrid(1:xImageSize,1:yImageSize);        
    liPossibleTargets = false(yImageSize,xImageSize);
    
    for iX = 1 + SEARCH_BOX_SIZE : xImageSize - SEARCH_BOX_SIZE
        for iY = 1 + SEARCH_BOX_SIZE : yImageSize - SEARCH_BOX_SIZE
            partialImage = signalImage(iY - SEARCH_BOX_SIZE : iY + SEARCH_BOX_SIZE , iX - SEARCH_BOX_SIZE : iX + SEARCH_BOX_SIZE);            
            [junk,iMax] = max(partialImage(:)); %#ok<ASGLU>
            if iMax == ((2*SEARCH_BOX_SIZE+1)^2-1)/2+1, liPossibleTargets(iY,iX) = true; end                        
        end
    end
    
    liPossibleTargets = find(liPossibleTargets);
    zzPossibleTargets = signalImage(liPossibleTargets);
    [zzPossibleTargets,sortOrder] = sort(zzPossibleTargets,'descend'); %#ok<ASGLU>       
    liPossibleTargets = liPossibleTargets(sortOrder);
     
    xxPossibleTargets = xGrid(liPossibleTargets);
    yyPossibleTargets = yGrid(liPossibleTargets);
    kkPossibleTargets = mskycalc(signalImage,xxPossibleTargets,yyPossibleTargets,Config.SKY_MIN,Config.SKY_MAX);       
    ssPossibleTargets = sigmaGuess + 0*xxPossibleTargets; 
    dxPossibleTargets = 1 + 0*xxPossibleTargets;
    dyPossibleTargets = 1 + 0*xxPossibleTargets;
    dzPossibleTargets = 1 + 0*xxPossibleTargets;
    dsPossibleTargets = 1 + 0*xxPossibleTargets;
    
    zzPossibleTargets = zzPossibleTargets - kkPossibleTargets;
  
    % Create an index to record the stars.
    goodStarIndex = false(length(xxPossibleTargets),1);
    
    % Initialize number of stars found.
    numStarsFound = 0;
    
    
    % Start loop over all possible stars.
    for iStar = 1:length(xxPossibleTargets)
        
   
            
            % We are fitting a gaussian of the functional form f=A*exp(-(x-x0)^2/2/s^2-(y-y0)^2/2/s^2)
            
            % Record an estimate for fitting parameters.
            AA = zzPossibleTargets(iStar);
            X0 = xxPossibleTargets(iStar);
            Y0 = yyPossibleTargets(iStar);
            SS = ssPossibleTargets(iStar);
            
            % Rip a piece of the grid and image for evaluation.
            DD = max(ceil(CENTERING_BOX_SIZE*SS),2);
            yRange = max(Y0-DD,1):min(Y0+DD,yImageSize);
            xRange = max(X0-DD,1):min(X0+DD,xImageSize);
            
            XX = xGrid(yRange,xRange);
            YY = yGrid(yRange,xRange);
            ZZ = signalImage(yRange,xRange);            
            WW = real(1./noiseImage(yRange,xRange).^2);
            
            % Obtain indicies which lie within the appropriate radius.
            activeIndicies = (XX(:)-X0).^2+(YY(:)-Y0).^2 <= CENTERING_BOX_SIZE^2;
            
            % Obtain grid and image.
            XX = XX(activeIndicies);
            YY = YY(activeIndicies);
            ZZ = ZZ(activeIndicies);
            WW = diag(WW(activeIndicies));
            
            % Jacobian stored here.
            J = zeros(length(ZZ),4);
            
            % Nllsqr M-L Lambda
            L = fitInitialLambda;
            
            % Reset the continuation paramter.
            goOn = true;
            
            % Begin loop to iterate solution.
            for iIteration=1:fitIterations
                if abs(imag(AA))>0, keyboard, end
                % Obtain the residual.
                preResidual = sum((AA*exp(-(XX-X0).^2/2/SS^2-(YY-Y0).^2/2/SS^2)-ZZ).^2);
                
                
                % Obtain the jacobian.
                J(:,1) = 1./exp((XX - X0).^2/(2*SS^2) + (YY - Y0).^2/(2*SS^2));
                J(:,2) = (AA*(2*XX - 2*X0))./(2*SS^2*exp((XX - X0).^2/(2*SS^2) + (YY - Y0).^2/(2*SS^2)));
                J(:,3) = (AA*(2*YY - 2*Y0))./(2*SS^2*exp((XX - X0).^2/(2*SS^2) + (YY - Y0).^2/(2*SS^2)));
                J(:,4) = (AA*((XX - X0).^2/SS^3 + (YY - Y0).^2/SS^3))./exp((XX - X0).^2/(2*SS^2) + (YY - Y0).^2/(2*SS^2));
                
                % Perform a fitting iteration.
                %dPar = (J'*J + L*eye(size(J,2)))^(-1)*J'*(Z-A*exp(-(X-X0).^2/2/S^2-(Y-Y0).^2/2/S^2));
                
                dPar = (J'*WW*J + L*eye(size(J,2)))^(-1)*J'*WW*(ZZ-AA*exp(-(XX-X0).^2/2/SS^2-(YY-Y0).^2/2/SS^2));
                %dPar = (J'*W*J + L*eye(size(J,2)))\(J'*W*(Z-A*exp(-(X-X0).^2/2/S^2-(Y-Y0).^2/2/S^2)));
                
                
                % Update the parameters.
                AA = AA + dPar(1);
                X0 = X0 + dPar(2);
                Y0 = Y0 + dPar(3);
                SS = SS + dPar(4);
                SS = abs(SS);
                
                % Obtain the residual.
                postResidual = sum((AA*exp(-(XX-X0).^2/2/SS^2-(YY-Y0).^2/2/SS^2)-ZZ).^2);
                
                % Check the the star is within the search box.
                if abs(X0-xxPossibleTargets(iStar)) > CENTERING_BOX_SIZE || abs(Y0-yyPossibleTargets(iStar)) > CENTERING_BOX_SIZE, goOn = false; break, end
                
                % Check that the standard deviation is not too small.
                if SS<crCutoff, goOn = false; break, end
                
                % Check that the standard deviation is not too large.
                if SS>galaxyCutoff, goOn = false; break, end
                
                % Check if we have gotten to the tolerance desired.
                if(abs(postResidual/preResidual - 1) < fitTolerance)
                    break;
                elseif(postResidual/preResidual > minConvergence)
                    L = L/lambdaMultiplier;
                else
                    L = L*lambdaMultiplier;
                end
                
                
            end
            
     
        
        
        % Check if we should continue with this star.
        if(~goOn)
            continue
        end
        
        
        
        
        M = (J'*WW*J)^-1;
        
        %    M = (J'*J)^-1*postResidual/(length(X(:))-4);
        
        if AA<0 || M(2,2)^.5 > searchBoxSize || M(3,3)^.5 > CENTERING_BOX_SIZE, continue, end
        % Mark this star as good.
        goodStarIndex(iStar) = true;
        
        % Copy over x,y, and z values.
        xxPossibleTargets(iStar) = X0;
        yyPossibleTargets(iStar) = Y0;
        zzPossibleTargets(iStar) = AA;
        ssPossibleTargets(iStar) = SS;
        dzPossibleTargets(iStar) = M(1,1).^.5;
        dxPossibleTargets(iStar) = M(2,2).^.5;
        dyPossibleTargets(iStar) = M(3,3).^.5;
        dsPossibleTargets(iStar) = M(4,4).^.5;
        
        % Indicate that we found another star.
        numStarsFound = numStarsFound+1;
        
        if numStarsFound > MaestroConfiguration.STAR_FINDING_MAX_STARS, break, end
    end
    
    
    if length(nonzeros(goodStarIndex))>MaestroConfiguration.STAR_FINDING_MAX_STARS
        goodStarIndex = find(goodStarIndex);
        goodStarIndex = goodStarIndex(1:MaestroConfiguration.STAR_FINDING_MAX_STARS);
    end
    
    
    xxPossibleTargets = xxPossibleTargets(goodStarIndex);
    yyPossibleTargets = yyPossibleTargets(goodStarIndex);
    zzPossibleTargets = zzPossibleTargets(goodStarIndex);
    ssPossibleTargets = ssPossibleTargets(goodStarIndex);
    dxPossibleTargets = dxPossibleTargets(goodStarIndex);
    dyPossibleTargets = dyPossibleTargets(goodStarIndex);
    dzPossibleTargets = dzPossibleTargets(goodStarIndex);
    dsPossibleTargets = dsPossibleTargets(goodStarIndex);
    nnPossibleTargets = (1:length(xxPossibleTargets))';
    
    
keyboard

end


function geometry = findstars(Fits)
    


end
