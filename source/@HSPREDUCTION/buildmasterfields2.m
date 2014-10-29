function buildmasterfields2(HSPReduction)
%BUILDMASTERFIELDS Generates a master field
%   BUILDMASTERFIELDS(REDUCTION) will build a master field from the FITS
%   objects stored in the "OBJECT" list.

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
rotationStyles = zeros(length(FITSList),1);

% This function can take some time to execute as all images will be loaded
% once if they are not already loaded. Use a process to keep the user
% notified as to the state of this function. Record the process ID "pid".
% See the "MPROCESSINIT" function for more information.
pid = mprocessinit(['\n Searching for stars on ',num2str(length(FITSList)),' images... ']);

%% LOOP OVER ALL OBJECT FITS FILES
% We will loop over every FITS file in the list in a random order to get an
% idea of the geometry of stars on these images. Every file will be visited
% once.
counter = 0;
for iFITSObject = randperm(length(FITSList))
    
    solutionIsAcceptable = false;
    
    % Extract the geometry of the sources on the current image. The
    % "findstars" method will return an nxm matrix containing m pieces of
    % information about the n stars on image. If no stars were found an
    % empty [] is returned. See the "findstars" method for more
    % information. The "FINDSTARS" method will eventually be replaced by a
    % static function. Record the target geometry and check that is is not
    % empty. If it is empty this image can tell us nothing about the
    % geometry of the images. Make sure to update the process (to display
    % the current status to the user). We then continue to the next image.
    CTG = FITSList(iFITSObject).findstars; if isempty(CTG), mprocessupdate(pid,(counter+1)/length(FITSList)); continue, end
    
    % If no "Master Field" exists create one from the current image.
    if isempty(MasterField)
        MasterField.Geometry = [CTG;zeros(1,size(CTG,2))];
        MasterField.JulianDate = FITSList(iFITSObject).JulianDate;
        MasterField.FieldName = datestr(now,'yyyymmdd_HHMMSS_FFF');
        MasterField.Labels = {};
        continue
    else
        CMG = MasterField.Geometry;
    end
    LAST = CMG;
    
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
        
        % For each permutation calculate the mean x and y values and
        % subtract these values from the the x and y values
        % respectively. We have to use REPMAT to make the size of the
        % mean of each permutation equal to the size of each
        % permutation. Sort the resultant permutations (along the
        % direction of the stars). This will return the sorted matrix
        % (which we dont care about) and indicies reflected the order
        % things were sorted by, ie... [1,2,3,4;4,3,1,2;3,2,4,1].
        [junk,IIM] = sort((XXM-repmat(mean(XXM,2),[1,NPS])).^2+(YYM-repmat(mean(YYM,2),[1,NPS])).^2,2); %#ok<ASGLU>
        [junk,IIT] = sort((XXT-repmat(mean(XXT,2),[1,NPS])).^2+(YYT-repmat(mean(YYT,2),[1,NPS])).^2,2); %#ok<ASGLU>
        
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
        PMP = repmat(PMP,[4,1]);
        PTP = repmat(PTP,[4,1]);
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
        PRS = reshape(repmat(1:4,[NAS/4,1]),[NAS,1]);
        liR1 = PRS==1;
        liR2 = PRS==2;
        liR3 = PRS==3;
        liR4 = PRS==4;
        
        % <<TODO>>
        % We will also record the angle of rotation given that this
        % field was rotating 2pi per day. We will call this ttTheta.
        % Note we access the julian date of the image here and in the
        % future we may want to put some checks here to make sure the
        % date is translated properly. Otherwise an error with one FITS file
        % will crash this whole function.
        ttTheta = (FITSList(iFITSObject).JulianDate - MasterField.JulianDate)*2*pi;
        
        % We are going to be playing a bit with the geometry between
        % the target and the master fields. Extract the X and Y
        % coordinates for all target solutions.
        XXT = reshape(CTG(2,PTP)',[NAS,NPS]);
        DXT = reshape(CTG(6,PTP)',[NAS,NPS]);
        YYT = reshape(CTG(3,PTP)',[NAS,NPS]);
        DYT = reshape(CTG(7,PTP)',[NAS,NPS]);
        
        % The first quarter of solutions does not need to be rotated.
        % These are the solutions which have zero rotation.
        % Apply flipping to the second quarter. To flip we negate all x
        % and y
        % values. There is no error propogation associated with this
        % process.
        XXT(liR2,:) = XXT(liR1,:);
        YYT(liR2,:) = -YYT(liR1,:);
        
        % Now we just need to flip the rotating fields in position 3
        % and 4. Calculate the sin and cosine of the angle they would
        % be rotated by.
        S = sin(ttTheta);
        C = cos(ttTheta);
        ttRotationAngle = ttTheta;
        
        % Now its time to rotate them. This is just a simple Euleren
        % rotation. We are rotating the 3rd position by theta and the
        % 4th by -theta. We have also messed with the statistics by
        % interchanging power between x and y.  Take care of the
        % statistics too. This is a simple propogation of error
        % problem. It may seem like the error in x and y should be the
        % same but out of focus images and images with elippitical psfs
        % can produce quite a difference between the x and y variance.
        XXT(liR3,:) = XXT(liR1,:)*C+YYT(liR1,:)*S;
        YYT(liR3,:) = YYT(liR1,:)*C-XXT(liR1,:)*S;
        XXT(liR4,:) = XXT(liR1,:)*C-YYT(liR1,:)*S;
        YYT(liR4,:) = XXT(liR1,:)*S+YYT(liR1,:)*C;
        DXT(liR3,:) = (DXT(liR1,:).^2*C^2+DYT(liR1,:).^2*S^2).^(1/2);
        DYT(liR3,:) = (DXT(liR1,:).^2*S^2+DYT(liR1,:).^2*C^2).^(1/2);
        DXT(liR4,:) = (DXT(liR1,:).^2*C^2+DYT(liR1,:).^2*S^2).^(1/2);
        DYT(liR4,:) = (DXT(liR1,:).^2*S^2+DYT(liR1,:).^2*C^2).^(1/2);                
        
        %% FIND THE BEST MATCHES
        % We have already ensured that for each possible solution the
        % relative brightness of stars agrees down to some reduced chi
        % squared. A more telling constraint is to force the stars to line
        % up geometrically in the x y plane. We have already generated a possible match for
        % each possible rotation angle. At this point a simple translation
        % should line up each set of stars. We will calculate the X and Y
        % translation required to minimize chi2, apply this translation,
        % and than eliminate solutions which do not match well enough.
        
        % The first thing to do is to extract the master x and y
        % values. We will need these and the relative errors in x and y
        % to calculate the translation and to  calculate reduced chi2.
        XXM = reshape(CMG(2,PMP)',[NAS,NPS]);
        YYM = reshape(CMG(3,PMP)',[NAS,NPS]);
        DXM = reshape(CMG(6,PMP)',[NAS,NPS]);        
        DYM = reshape(CMG(7,PMP)',[NAS,NPS]);
       
        DR = repmat(median(reshape(CMG(5,PMP)',[NAS,NPS]),2),[1,NPS]);
        
        % The full chi2 minimization here is also a non linear process. We
        % want to solve for the tranlsation needed to minimize the x
        % and y distance between the master and target fields. As it
        % was with scaling the brightness of the master and target
        % fields we will give the user the option to perform an
        % iterative method which includes the statistics, or a non
        % iterative method which is likely less robust. The initial
        % guess for the iterative method will be the soution for the
        % non iterative one. The initial guess for the x and y
        % translation will simply be the difference between the mean x
        % and y positions of the sets of master and target stars. The
        % error in the x and y translation is also calculated.
        xxPossibleTranslations = mean(XXM,2)-mean(XXT,2);
        yyPossibleTranslations = mean(YYM,2)-mean(YYT,2);
        dxPossibleTranslations = sum([DXM,DXT].^2,2).^(1/2)/NPS/2;
        DXPT = dxPossibleTranslations;
        dyPossibleTranslations = sum([DYM,DYT].^2,2).^(1/2)/NPS/2;
        DYPT = dyPossibleTranslations;
        
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
        xxDistance2 = (XXT-XXM+repmat(xxPossibleTranslations,[1,NPS])).^2;
        yyDistance2 = (YYT-YYM+repmat(yyPossibleTranslations,[1,NPS])).^2;
        
        %possibleTranslationalRChi2s = sum((xxDistance2+yyDistance2).^2./(xxDistance2.*(DXM.^2+DXT.^2)+yyDistance2.*(DYM.^2+DYT.^2)),2)./(NPS*2-2-(PRS>1));
        possibleTranslationalRChi2s = sum((xxDistance2+yyDistance2).^2./(xxDistance2.*DR.^2+yyDistance2.*DR.^2),2)./(NPS*2-2-(PRS>1));
        
        
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
        
        
        xxPossibleTranslations = xxPossibleTranslations(goodSolutionIndicies);
        yyPossibleTranslations = yyPossibleTranslations(goodSolutionIndicies);
        dxPossibleTranslations = dxPossibleTranslations(goodSolutionIndicies);
        dyPossibleTranslations = dyPossibleTranslations(goodSolutionIndicies);
        NAS = size(PMP,1);
        
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
            
            % We will now check if the rotation is as simple as no
            % rotation or a 180 degree flip. If a flip is the case we
            % can just negate the x and y values. The statistics (the
            % standard deviation of the x and y positions) are not
            % effected by this transformation.
            if any(PRS(iSolution) == [1,2])
                
                % We have determined the rotation style is either no
                % rotation or a flip. Lets further check if it is a
                % flip.
                if PRS(iSolution) == 2
                    
                    % The rotation style is a flip. To flip 180 degrees
                    % is simply to negate the x and y values. no
                    % attention needs to be paid to the statistics.
                    LPTG(2:3,:) = -LPTG(2:3,:);
                    LPMG(2:3,:) = -LPMG(2:3,:);
                    MPTG(2:3,:) = -MPTG(2:3,:);
                    
                end
                
            else
                
                % If we've reached this point it means that the
                % telescope is mounted so that it rotates thoughout the
                % night. We have already calculated the counter
                % clockwise angle at which this image would be with
                % respect to the master. Here we will check if the
                % rotation is clockwise (rotation style = 4) or ccw
                % (rotation style = 3). If the rotation style is
                % clockwise (4) than we will simply rotate ccw by
                % -Theta. Negate theta if this is the case. We will
                % record the rotation angle as "ttActiveRotationAngle"
                % to distinguish it from ttRotationAngle.
                if PRS(iSolution) == 3
                    ttActiveRotationAngle = ttRotationAngle;
                else
                    ttActiveRotationAngle = -ttRotationAngle;
                end
                C = cos(ttActiveRotationAngle);
                S = sin(ttActiveRotationAngle);
                
                % Now it is time to rotate the target field. We will
                % perform a simple euleren rotation X' = XC+YS, Y =
                % -XS+YC. We do the whole calculation in one fell swoop
                % using the newly calculate "ttActiveRotationAngle".
                LPTG(2:3,:) = [LPTG(2,:)*C+LPTG(3,:)*S;-LPTG(2,:)*S+LPTG(3,:)*C];
                LPMG(2:3,:) = [LPMG(2,:)*C+LPMG(3,:)*S;-LPMG(2,:)*S+LPMG(3,:)*C];
                MPTG(2:3,:) = [MPTG(2,:)*C+MPTG(3,:)*S;-MPTG(2,:)*S+MPTG(3,:)*C];
                
                
                % We also need to take care of statistics. With the
                % rotation we shuffle around the errors in the x and y
                % direction. Although typically the error in a stars
                % position will be the same in x and y this is not true
                % when the psf is elliptical. This is a rather simple
                % propgation of error problem.
                LPTG(6:7,:) = ([LPTG(6,:).^2*C^2+LPTG(7,:).^2*S^2;LPTG(6,:).^2*S^2+LPTG(7,:).^2*C^2]).^(1/2);
                LPMG(6:7,:) = ([LPMG(6,:).^2*C^2+LPMG(7,:).^2*S^2;LPMG(6,:).^2*S^2+LPMG(7,:).^2*C^2]).^(1/2);
                MPTG(6:7,:) = ([MPTG(6,:).^2*C^2+MPTG(7,:).^2*S^2;MPTG(6,:).^2*S^2+MPTG(7,:).^2*C^2]).^(1/2);
                
            end
            
            %% APPLY SCALING AND TRANSLATION
            % We want to project the master and target fields onto
            % eachother. Use the calculated values to apply this
            % translation and scaling to the unmatched stars. This also
            % scales the statistics of the star brightness.
            mmRatio = median(MMG(4,:)./MTG(4,:));
            
            MPTG(4,:) = MPTG(4,:)*mmRatio;
            MPTG(8,:) = MPTG(8,:)*mmRatio;
            MPTG(2,:) = MPTG(2,:)+xxPossibleTranslations(iSolution);
            MPTG(3,:) = MPTG(3,:)+yyPossibleTranslations(iSolution);
            
            LPTG(4,:) = LPTG(4,:)*mmRatio;
            LPTG(8,:) = LPTG(8,:)*mmRatio;
            LPMG(4,:) = LPMG(4,:)/mmRatio;
            LPMG(8,:) = LPMG(8,:)/mmRatio;
            LPTG(2,:) = LPTG(2,:)+xxPossibleTranslations(iSolution);
            LPTG(3,:) = LPTG(3,:)+yyPossibleTranslations(iSolution);
            LPMG(2,:) = LPMG(2,:)-xxPossibleTranslations(iSolution);
            LPMG(3,:) = LPMG(3,:)-yyPossibleTranslations(iSolution);
            
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
                
                % Check image size. If the position of the supposed
                % star is off image we can get no information about
                % whether this solution appears correct or whether this
                % is really a master star. The value for this star in
                % "unmatchedType" is already zero so we can just
                % continue on.
                if LPMG(2,iStar) < 1 || LPMG(2,iStar) > xImageSize || LPMG(3,iStar) < 1 || LPMG(3,iStar) > yImageSize, continue, end
                
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
            XXW1 = 1./(MPTG(6,:).^2+DXPT(iSolution)^2);
            XXW2 = 1./(MMG(6,:).^2);
            YYW1 = 1./(MPTG(7,:).^2+DYPT(iSolution)^2);
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
            MasterField.Geometry(10,aiIndirectMasterMatches) = MasterField.Geometry(10,aiIndirectMasterMatches)+MaestroConfiguration.STARITUDE_INDIRECT_MATCH_BONUS;
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
                rotationStyles(iFITSObject) = PRS(iSolution);                                
            end
            
            solutionIsAcceptable = true;
            
            break
            
           
        end
        
        if solutionIsAcceptable, break, end
        
    end
    try
    if ~solutionIsAcceptable
       
        MasterField.Geometry(10,:) = MasterField.Geometry(10,:) - 1;
        MasterField.Geometry(:,MasterField.Geometry(10,:)< 0) = [];
        MasterField.Geometry(1,:) = 1:size(MasterField.Geometry,2);
        if isempty(MasterField.Geometry)
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
            
    
    MasterField.Geometry = MasterField.Geometry(:,MasterField.Geometry(10,:)>10);
    
    
    %% COPY RELAVANT INFORMATION
    % We will now record the information obtained in this function
    
    % All that needs to be recorded is the master field array and the field solutions.
    % The master field array ("MasterFieldArray") contains one or multiple master fields
    % (configurations of stars found on the images). The field solutions
    % ("FieldSolutions") contain the information needed to know how to perform
    % a geometric transformation on each image to line that images stars up
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
    
    
    %  MasterFieldArray(iMasterField).FieldName = 'unknown';
    fixedFieldPoints = length(nonzeros(rotationStyles==1));
    flippedFieldPoints = length(nonzeros(rotationStyles==2));
    rotatingCWPoints = length(nonzeros(rotationStyles==3));
    rotatingCCWPoints = length(nonzeros(rotationStyles==4));
    
    
    
    if fixedFieldPoints+flippedFieldPoints < rotatingCWPoints
        %Deal with rotating
        mconfig('FIELD_ROTATION_METHOD','CW');
        mconfig('FIELD_ROTATION_DATA',1)
    elseif fixedFieldPoints+flippedFieldPoints <rotatingCCWPoints
        mconfig('FIELD_ROTATION_METHOD','CCW');        
        mconfig('FIELD_ROTATION_DATA',1);
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
            mconfig('FIELD_ROTATION_METHOD','None');            
        else
            mconfig('FIELD_ROTATION_METHOD','Flip');
            mconfig('FIELD_ROTATION_DATA',[iFITSObject,FlipIndex]);            
        end
     
    end
    

HSPReduction.MasterFieldArray = MasterField;


