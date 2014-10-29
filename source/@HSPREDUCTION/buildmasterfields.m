function buildmasterfields(HSPReduction)
%BUILDMASTERFIELDS Generates a set of master star fields.
%   BUILDMASTERFIELDS(REDUCTION) will use the fits objects stored in the
%   reduction to generate a set of master light source arrays.  

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
MaestroConfiguration = HSPReduction.MaestroConfiguration;

% Extract the current object FITS list. This retrieves the list of fits
% objects currently loaded into maestro. If there are no FITS objects
% currently loaded this function will throw an error so we are guarenteed
% to retrieve at least one fits object. For more information on what a fits
% object actually is see the maestro "FITS" object.
FITSList = HSPReduction.FITSList;

% Initialize an array to store master fields. This will store the geometry
% of various arrangements of stars, galaxies and objects found on images.
% For more information about what this variable looks like when populated
% look near the end of the code. Also initialize a structure to contain
% information about the solution to each of the images to be processed.
% This will store the geometric transform required to take stars from this
% image and project them onto one of the master fields. Both variables are
% written directly to the HSPReduction property by the same name when this
% routine completes.
MasterFieldArray([]) = struct;
FieldSolutions(1:length(FITSList)) = struct;

% This function can take some time to execute as all images will be loaded
% once if they are not already loaded. Use a process to keep the user
% notified as to the state of this function. Record the process ID "pid".
% See the "MPROCESSINIT" function for more information.
pid = mprocessinit(['\n Searching for stars on ',num2str(length(FITSList)),' images... ']);

%% LOOP OVER ALL FITS FILES
% We will loop over every FITS file in the list from first to last to get
% an idea of the geometry of stars on these images.. Note that the images
% should already be in the desired order, be it sorted by date or whatever.
% Every file will be visited once. This does introduce some slight biases
% to the order of the images but this is minimalized with a larger data
% set.
for iFITSObject = 1:length(FITSList)    
    
    % First record that no solution was found for this image. A solution is
    % a match between some known configuration of stars and the stars on
    % this image. We record there being no match by default and record that
    % there is a match later in the routine (if we get that far).                
    FieldSolutions(iFITSObject).WasFound = false;
            
    % Extract the geometry of the sources on the current image. The
    % "findstars" method will return an nxm matrix containing m pieces of
    % information about the n stars on image. If no stars were found an
    % empty [] is returned. See the "findstars" method for more
    % information. The "FINDSTARS" method will eventually be replaced by a
    % static function.
    % The columns of "completeTargetGeometry" are as follows:
    %   1 - INDEX
    %   2 - X
    %   3 - Y
    %   4 - Z
    %   5 - S (Sigma from a Gaussian fit)
    %   6 - dX
    %   7 - dY
    %   8 - dZ
    %   9 - dS    
    % Record the target geometry and check that is is not empty. If it is
    % empty this image can tell us nothing about the geometry of the
    % images. Make sure to update the process (to display the current
    % status to the user). We then continue to the next image.
    completeTargetGeometry = FITSList(iFITSObject).findstars; if isempty(completeTargetGeometry), mprocessupdate(pid,iFITSObject/length(FITSList)); continue, end   
           
    %% LOOP OVER ALLOWED NUMBER OF SOURCES PER PERMUTATION
    % We will refer to sets of stars on the current images and other images
    % as "permutations". Starting with the maximum number of sources/stars
    % allowed in any individual permutation we will try to match the
    % current field with one of the master fields. If a suitable match is
    % found at any point in this loop, it is terminated and the match is
    % recorded. See below for the rationale explaining the choice for the
    % variable in this for loop.
    for iHashIndex = 0:size(completeTargetGeometry,2)-2 
    
        % If there are no master fields the current target field will
        % become the master field. We break out of the loop. As no solution
        % was recorded something on the other side of this loop will need
        % to record the stars on this image as the first master field.
        if isempty(MasterFieldArray), break, end
                
        % The current number of allowed hash stars is the maximum number of
        % hash stars minus "iHashIndex". This is done so that we start
        % with the maximum number of stars per permutation and end with 2 stars.
        % Note that one star hashes are not performed.
        nSourcesPerPermutation = size(completeTargetGeometry,2)-iHashIndex;
        if nSourcesPerPermutation > 5, continue, end
    
        %% BEGIN LOOP OVER MASTER FIELDS
        % We will loop over the master fields and attempt to match each one
        % to the target field. When certain criteria are met a match will
        % be recorded.
        for iMasterField = 1:length(MasterFieldArray)
      
            % Extract the current master field for easy reference. This
            % will look exactly like the "completeTargetGeometry" variable above.
            % See the comments by that for a detailed description.
            completeMasterGeometry = MasterFieldArray(iMasterField).Geometry;
                                    
            % Check that the number of stars in the master field is at
            % least the number of stars used per hash.
            % If it is not continue on to the next master field. This field
            % will be returned to if a solution is not found before the
            % number of permutation stars drops enough to include this
            % field.
            if size(completeMasterGeometry,2) < nSourcesPerPermutation, continue, end                               
                
            % Initialize the number of target and master stars to use. Both
            % of these numbers will start at the current number of target
            % and master stars and will be decreased until the number of
            % permutations reaches some critical value.
            nUsableTargetStars = size(completeTargetGeometry,2);
            nUsableMasterStars = size(completeMasterGeometry,2);                                                         
            
            %% DETERMINE NUMBER OF MASTER AND TARGET STARS
            % The actual number of target and master stars would ideally be
            % "all of them" but there are computational issues with this.
            % Here we will ensure that the number of permutations that will
            % be generated will not exceed some customizable limit (in the
            % locale). The while loop will execute until the number of
            % target and master stars satisfies this limit or the number of
            % target or master stars gets too small. 
            while nUsableTargetStars >= nSourcesPerPermutation && nUsableMasterStars >= nSourcesPerPermutation && nchoosek(nUsableTargetStars,nSourcesPerPermutation)*nchoosek(nUsableMasterStars,nSourcesPerPermutation) > MaestroConfiguration.MAX_SOURCE_PERMUTATIONS
                
                % Start an if else statement to determine whether to remove
                % master or target stars. The way this is chosen to be done
                % is to remove stars from whichever is larger. If they are
                % the same size we remove one from both.
                if nUsableTargetStars > nUsableMasterStars                    
                    nUsableTargetStars = nUsableTargetStars - 1;
                elseif nUsableMasterStars > nUsableTargetStars 
                    nUsableMasterStars = nUsableMasterStars - 1;
                else
                    nUsableTargetStars = nUsableTargetStars - 1;
                    nUsableMasterStars = nUsableMasterStars - 1;
                end                
            end            
                      
            % Check to see whether the number of master or target stars
            % dropped below the current number of stars per hash. This can
            % only really happen if the number of stars per hash is set to
            % a high value and the max hash permutations is very low. If
            % this is the case continue on to the next master field.          
            if any([nUsableTargetStars,nUsableMasterStars]<nSourcesPerPermutation),continue, end
            nSourcesPerSolution = nSourcesPerPermutation;
            NNP = nSourcesPerPermutation;
            NNT = nUsableTargetStars;
            NNM = nUsableMasterStars;
            GGM = completeMasterGeometry;
            GGT = completeTargetGeometry;
          
            
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
            PPT = nchoosek(1:NNT,NNP);
            PPM = nchoosek(1:NNM,NNP);
     
            
                           
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
 
            % Check if this is the two star case. We will use different
            % algorithms for two and multi star cases.
            if NNP == 2
                
                % Extract the amplitude and the standard error in the amplitude of the stars.
                % We will need the standard error to make sure that we can
                % distinguish between the two stars in each permutation with this method.
                ZZM = reshape(GGM(4,PPM)',size(PPM));
                ZZT = reshape(GGT(4,PPT)',size(PPT));
                DZM = reshape(GGM(8,PPM)',size(PPM));
                DZT = reshape(GGT(8,PPT)',size(PPT));
                
                % Calculate reduced chi2 for assuming the stars are the
                % same. If this reduced chi2 is above some threshold that
                % means the stars are distinguishable.Include some inherent
                % varaibility in the stars.
               % C2M = (ZZM(:,1)-ZZM(:,2)).^2./(DZM(:,2).^2+DZM(:,1).^2+MaestroConfiguration.MAX_SOURCE_VARIABILITY^2*(ZZM(:,1).^2+ZZM(:,2).^2))/2;
               % C2T = (ZZT(:,1)-ZZT(:,2)).^2./(DZT(:,2).^2+DZT(:,1).^2+MaestroConfiguration.MAX_SOURCE_VARIABILITY^2*(ZZT(:,1).^2+ZZT(:,2).^2))/2;
                
                % Remove all entries which violate the condition that the
                % stars are distinguishable.
               % PPM(C2M<MaestroConfiguration.STAR_DISTINGUISHABILITY_REDUCED_CHI2,:) = [];
               % PPT(C2T<MaestroConfiguration.STAR_DISTINGUISHABILITY_REDUCED_CHI2,:) = [];
                
                % Check that not all target of master star combinations
                % have been removed. If all have been removed there is
                % nothing we can reliably do so simply continue on.
               % if isempty(PPM) || isempty(PPT), continue, end
                
                % We now need to reextract all of the master and target
                % star amplitudes for sorting by amplitude.
                ZZM = reshape(GGM(4,PPM)',size(PPM));
                ZZT = reshape(GGT(4,PPT)',size(PPT));
                
                % Obtain the sort order for the master and target
                % permutations.
                [junk,IIM] = sort(ZZM,2); %#ok<ASGLU>
                [junk,IIT] = sort(ZZT,2); %#ok<ASGLU>
                
                % Clean up some of the garbage we wont need anymore.
                clear ZZM ZZT DZT DZM C2M C2T junk
                
            else
                
                % The first thing to do is to extract the x and y positions for
                % each permutation. This will create nxm matricies where n is
                % the index of the permutation and m is the index of the stars
                % within the permutation. The name of the variables is XXM for
                % the x position of the master field etc. Remember that the 2nd
                % and 3rd rows of the GGM and TTM (which contain all of of the
                % information about the stars/sources on the target and master
                % images) store the x and y positions of the stars
                % respectively.
                XXM = reshape(GGM(2,PPM)',size(PPM));
                YYM = reshape(GGM(3,PPM)',size(PPM));
                XXT = reshape(GGT(2,PPT)',size(PPT));
                YYT = reshape(GGT(3,PPT)',size(PPT));                
                
                % For each permutation calculate the mean x and y values and
                % subtract these values from the the x and y values
                % respectively. We have to use REPMAT to make the size of the
                % mean of each permutation equal to the size of each
                % permutation. Sort the resultant permutations (along the
                % direction of the stars). This will return the sorted matrix
                % (which we dont care about) and indicies reflected the order
                % things were sorted by, ie... [1,2,3,4;4,3,1,2;3,2,4,1].
                [junk,IIM] = sort((XXM-repmat(mean(XXM,2),[1,NNP])).^2+(YYM-repmat(mean(YYM,2),[1,NNP])).^2,2); %#ok<ASGLU>
                [junk,IIT] = sort((XXT-repmat(mean(XXT,2),[1,NNP])).^2+(YYT-repmat(mean(YYT,2),[1,NNP])).^2,2); %#ok<ASGLU>
                                
                % We have used some memory to store variables that are no
                % longer needed. The only thing created in this section that is
                % needed later are the sorted permutation matricies. Clear
                % everything else.
                clear XXM YYM XXT YYT junk 
                
            end
            
            % The sort function is not very effective for reordering
            % everything. The sorted matrix cannot simply be evaluated at
            % the returned indicies as they are with respect to each row,
            % not to the whole matrix. We need to convert the indicies for
            % simple reference. The indicies are transposed, essentilly added to a
            % correction matrix, and transposed back. Its sort of a
            % convoluted idea and someone should write a smarter sort
            % function.
            PPM = PPM'; PPM = PPM(IIM'+repmat((0:size(PPM,2)-1)*NNP,[NNP,1]))';
            PPT = PPT'; PPT = PPT(IIT'+repmat((0:size(PPT,2)-1)*NNP,[NNP,1]))';
            % Clean up the indicies used to reference the sort order.
            clear IIM IIT          
                                                
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
            PPM = repmat(PPM,[size(PPT,1),1]);
            PPT = reshape(repmat(PPT',[size(PPM,1)./size(PPT,1),1]),[NNP,size(PPM,1)])';
            completeTargetSolution = PPT;
            completeMasterSolution = PPM;
            possibleTargetSolutions = PPT;
            possibleMasterSolutions = PPM;
            nPossibleSolutions = size(PPT,1);
            
                                        
            %% FIND MATCHES BASED ON BRIGHTNESS
            % Each permutation of target and master stars will be tested to
            % see how consistant the relative brightness of the stars are
            % between the two images. We have to compare relative
            % brightnesses because each image has its own cloud cover,
            % seeing, etc. For example if the master stars have brightness
            % [4,5,6] and the target stars have brightness [8,10,12] this
            % would be a possible match based on brightness with a scale           
            % factor of 2. If a solution does not line up in brightness
            % very well it may be removed. The specific criteria are
            % described below.
                                   
            % First lets extract the brightness of each permutation of
            % stars. Each of these will generate an nxm matrix with each
            % star indexed in the 1st direction and each possible solution
            % (sets of star indicies) in the 2nd dimension. 
            zzPossibleMasterSolutions = reshape(completeMasterGeometry(4,possibleMasterSolutions)',[nPossibleSolutions,nSourcesPerSolution]);
            dzPossibleMasterSolutions = reshape(completeMasterGeometry(8,possibleMasterSolutions)',[nPossibleSolutions,nSourcesPerSolution]);
            zzPossibleTargetSolutions = reshape(completeTargetGeometry(4,possibleTargetSolutions)',[nPossibleSolutions,nSourcesPerSolution]);
            dzPossibleTargetSolutions = reshape(completeTargetGeometry(8,possibleTargetSolutions)',[nPossibleSolutions,nSourcesPerSolution]);        
                                                            
            % The next thing we need to do is to calculate the scale
            % factor between every possible permutation. There are two ways
            % to do this...
            
            % METHOD ONE: Ignore the statistics and simply calculate the
            % ratio of the means. This method is probably good in many
            % cases but does not weight things effectively.
            
            % METHOD TWO: Calculate the brightness ratio using the
            % reciprocal variance as a weight. This is the proper way to do
            % things, only problem is that this is non linear and we have
            % to iterate. This is SLOW and is not practical for a large
            % number of possible sets of matching stars.
            
            % We will use the MAESTRO configuration entry for
            % "CALCULATE_BRIGHTNESS_RATIO_WITH_STATISTICS" to determine
            % which method we will use to do so.          
            % For method two we an initial guess to the brightness ratio.
            % We will perform the calculation for method one and if need
            % be, use this as our starting guess for each brightness ratio
            % and permform method two. Calculate the ratio of the mean
            % value of each set of master stars to the corresponding set of
            % target stars. The result should be an nx1 matrix where n
            % indexes each solution. Call this variablezzX
            % "mmMasterToTargetRatio". I use the letter m to designate it
            % as when solved on paper I used the equation y=mx. Note we
            % take the mean of each set of brightnesses along the second
            % axes (meaning the mean of each set). We also record the error
            % in this ratio. Its just the progotation of error though a
            % mean divided by another. To simplify and speed up things we
            % calculate the mean of both arrays first.
            zzMeanPossibleMasterSolutions = mean(zzPossibleMasterSolutions,2);
            zzMeanPossibleTargetSolutions = mean(zzPossibleTargetSolutions,2);              
            mmPossibleMasterToTargetBrightnessRatios = zzMeanPossibleMasterSolutions(:,1)./zzMeanPossibleTargetSolutions(:,1);
            dmPossibleMasterToTargetBrightnessRatios = mmPossibleMasterToTargetBrightnessRatios.*(sum(dzPossibleMasterSolutions.^2,2)./zzMeanPossibleMasterSolutions.^2+sum(dzPossibleTargetSolutions.^2,2)./zzMeanPossibleTargetSolutions.^2).^(1/2)/nSourcesPerSolution; 
              
            % Check if the config tells us to do this calculation including
            % statistics.
            if MaestroConfiguration.CALCULATE_BRIGHTNESS_RATIO_WITH_STATISTICS
                % Now we need to take care and use the statistics of the
                % stars to calculate the target to master brightness ratio
                % for every set. We will use "mmMasterToTargetRatio" as an
                % initial guess. This calculation is a bit of a pain in the
                % ass to derive, and it has quite a few terms. Lets
                % calculate the terms first and then put them all together.
                % You may find it strange that this is a non linear
                % calculation and this is only the case becuase there is
                % error in both the master and target brightness. In a more
                % typical case one of these would be data points and the
                % other a model with 0 error. Begin a loop to hone in on
                % the best value for "mmMasterToTargetRatio". We will
                % perform this calculation and refine our value for all
                % sets according to the number of iterations specified in
                % the MAESTRO configuration parameter
                % "NUMBER_BRIGHTNESS_RATIO_ITERATIONS".
                for iIteration = 1:MaestroConfiguration.NUMBER_BRIGHTNESS_RATIO_ITERATIONS
                                                            
                    % We are attempting to minimize the residual of
                    % sum((y-mx)^2*w) where y is the master brightness, m is
                    % the parameter we are solving for, and x is the target
                    % brightness. By assuming dw/dm ~ 0 instead of the real
                    % value (2*m*dx^2) we can iterativly solve. The solution
                    % for each iteration is...
                    %   m = (sum y*x*w)/(sum x^2*w)
                    % An important term is the weight, which is just one
                    % divided by the total variance. Calculate this first. We
                    % use the letters ww for weight. Remember that the variance
                    % in the target brightness needs to be multiplied by the
                    % ratio to get the correct weight (hence why its non
                    % linear).
                    wwTotalWeights = 1./(repmat(mmPossibleMasterToTargetBrightnessRatios.^2,[1,nSourcesPerPermutation]).*dzPossibleTargetSolutions.^2+dzPossibleMasterSolutions.^2);
                    mmPossibleMasterToTargetBrightnessRatios = sum(zzPossibleTargetSolutions.*zzPossibleMasterSolutions.*wwTotalWeights,2)./sum(zzPossibleTargetSolutions.^2.*wwTotalWeights,2);                                                            
                    
                end
                
                % <<TODO>>
                % In the future I would like to calculate the resultant
                % error from the non linear process. I really dont feel
                % like figuring this out and its probably quite similar, if
                % not the same as the error calculated above. Please feel
                % free to insert the formula here.
                                            
            end
                       
            % Now that we know the brightness ratio between each possible
            % solution we can test if that brightness ratio agrees with the
            % statistics of the data. Our criteria will be that reduced
            % chi2 between the master and target brightness (corrected by
            % the brightness ratio) is above some value specified by the
            % configuration.
            
            % The first thing to do is to calculate reduced chi2. Reduced
            % chi2 is basically the sum of the R2 with each R2 divided by
            % the variance. Problem with stars on an image is that they are
            % variable. This means there is some intrinsic variability. The
            % intrinsic variability is set by a configuration pararamter
            % "MAX_SOURCE_VARIABILITY". Calculate reduced chi2 for every
            % possible solutions. First calculate the standard error
            % squared for every point including this variability.
            v2TotalVariances = (dzPossibleTargetSolutions.^2+zzPossibleTargetSolutions.^2.*MaestroConfiguration.MAX_SOURCE_VARIABILITY^2.*repmat(mmPossibleMasterToTargetBrightnessRatios.^2,[1,nSourcesPerPermutation])+MaestroConfiguration.MAX_SOURCE_VARIABILITY^2*zzPossibleMasterSolutions.^2);                       
            possibleBrightnessRChi2s = sum((zzPossibleTargetSolutions.*repmat(mmPossibleMasterToTargetBrightnessRatios,[1,nSourcesPerPermutation])-zzPossibleMasterSolutions).^2./v2TotalVariances,2)/(nSourcesPerPermutation-1);            
            
            % If the reduced chi2 value is above some threshold we will
            % consider the solution rotten and remove it. The threshold
            % should be set in a place that gets rid of most of the bad
            % solutions but should not be too strict. This value is stored
            % in the MAESTRO configuration paramter
            % "BRIGHTNESS_MATCH_MAX_REDUCED_CHI2". Obtain logical indicies
            % in reference to which matches are valid.  
            goodSolutionIndicies = possibleBrightnessRChi2s < MaestroConfiguration.BRIGHTNESS_MATCH_MAX_REDUCED_CHI2;
            
            % Get rid of all of the bad solutions by copying only the good
            % ones into the arrays containing the solution information.
            % Also remember to bring along the reduced chi2 values from
            % this brightness test, as well as the possible master to
            % target ratios.                        
            possibleMasterSolutions = possibleMasterSolutions(goodSolutionIndicies,:);
            possibleTargetSolutions = possibleTargetSolutions(goodSolutionIndicies,:);                                                                                             
            possibleBrightnessRChi2s = possibleBrightnessRChi2s(goodSolutionIndicies);     
            mmPossibleMasterToTargetBrightnessRatios = mmPossibleMasterToTargetBrightnessRatios(goodSolutionIndicies);
            dmPossibleMasterToTargetBrightnessRatios = dmPossibleMasterToTargetBrightnessRatios(goodSolutionIndicies);
            
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
            possibleMasterSolutions = repmat(possibleMasterSolutions,[4,1]);
            possibleTargetSolutions = repmat(possibleTargetSolutions,[4,1]);
            possibleBrightnessRChi2s = repmat(possibleBrightnessRChi2s,[4,1]);
            mmPossibleMasterToTargetBrightnessRatios = repmat(mmPossibleMasterToTargetBrightnessRatios,[4,1]);
            dmPossibleMasterToTargetBrightnessRatios = repmat(dmPossibleMasterToTargetBrightnessRatios,[4,1]);            
            nPossibleSolutions = size(possibleMasterSolutions,1);        

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
            possibleRotateSolutions = reshape(repmat(1:4,[nPossibleSolutions/4,1]),[nPossibleSolutions,1]);
            liRotationIndicies1 = possibleRotateSolutions==1; 
            liRotationIndicies2 = possibleRotateSolutions==2; 
            liRotationIndicies3 = possibleRotateSolutions==3; 
            liRotationIndicies4 = possibleRotateSolutions==4;
            
            % <<TODO>>
            % We will also record the angle of rotation given that this
            % field was rotating 2pi per day. We will call this ttTheta.
            % Note we access the julian date of the image here and in the
            % future we may want to put some checks here to make sure the
            % date is translated properly. Otherwise an error with one FITS file
            % will crash this whole function.           
            ttTheta = (FITSList(iFITSObject).JulianDate - MasterFieldArray(iMasterField).JulianDate)*2*pi;         
                                        
            % We are going to be playing a bit with the geometry between
            % the target and the master fields. Extract the X and Y
            % coordinates for all target solutions.              
            xxPossibleTargetSolutions = reshape(completeTargetGeometry(2,possibleTargetSolutions)',[nPossibleSolutions,nSourcesPerSolution]);                        
            dxPossibleTargetSolutions = reshape(completeTargetGeometry(6,possibleTargetSolutions)',[nPossibleSolutions,nSourcesPerSolution]);
            yyPossibleTargetSolutions = reshape(completeTargetGeometry(3,possibleTargetSolutions)',[nPossibleSolutions,nSourcesPerSolution]);
            dyPossibleTargetSolutions = reshape(completeTargetGeometry(7,possibleTargetSolutions)',[nPossibleSolutions,nSourcesPerSolution]);                                             
            
            % The first quarter of solutions does not need to be rotated.
            % These are the solutions which have zero rotation. 
            % Apply flipping to the second quarter. To flip we negate all x
            % and y
            % values. There is no error propogation associated with this
            % process.
            xxPossibleTargetSolutions(liRotationIndicies2,:) = -xxPossibleTargetSolutions(liRotationIndicies1,:);
            yyPossibleTargetSolutions(liRotationIndicies2,:) = -yyPossibleTargetSolutions(liRotationIndicies1,:);
                        
            % Now we just need to flip the rotating fields in position 3
            % and 4. Calculate the sin and cosine of the angle they would
            % be rotated by. 
            ssTheta = sin(ttTheta);
            ccTheta = cos(ttTheta);
            ttRotationAngle = ttTheta;
            
            % Now its time to rotate them. This is just a simple Euleren
            % rotation. We are rotating the 3rd position by theta and the
            % 4th by -theta. We have also messed with the statistics by
            % interchanging power between x and y.  Take care of the
            % statistics too. This is a simple propogation of error
            % problem. It may seem like the error in x and y should be the
            % same but out of focus images and images with elippitical psfs
            % can produce quite a difference between the x and y variance.
            xxPossibleTargetSolutions(liRotationIndicies3,:) = xxPossibleTargetSolutions(liRotationIndicies1,:)*ccTheta+yyPossibleTargetSolutions(liRotationIndicies1,:)*ssTheta;            
            yyPossibleTargetSolutions(liRotationIndicies3,:) = yyPossibleTargetSolutions(liRotationIndicies1,:)*ccTheta-xxPossibleTargetSolutions(liRotationIndicies1,:)*ssTheta;
            xxPossibleTargetSolutions(liRotationIndicies4,:) = xxPossibleTargetSolutions(liRotationIndicies1,:)*ccTheta-yyPossibleTargetSolutions(liRotationIndicies1,:)*ssTheta;            
            yyPossibleTargetSolutions(liRotationIndicies4,:) = xxPossibleTargetSolutions(liRotationIndicies1,:)*ssTheta+yyPossibleTargetSolutions(liRotationIndicies1,:)*ccTheta;                                                                  
            dxPossibleTargetSolutions(liRotationIndicies3,:) = (dxPossibleTargetSolutions(liRotationIndicies1,:).^2*ccTheta^2+dyPossibleTargetSolutions(liRotationIndicies1,:).^2*ssTheta^2).^(1/2);
            dyPossibleTargetSolutions(liRotationIndicies3,:) = (dxPossibleTargetSolutions(liRotationIndicies1,:).^2*ssTheta^2+dyPossibleTargetSolutions(liRotationIndicies1,:).^2*ccTheta^2).^(1/2);
            dxPossibleTargetSolutions(liRotationIndicies4,:) = (dxPossibleTargetSolutions(liRotationIndicies1,:).^2*ccTheta^2+dyPossibleTargetSolutions(liRotationIndicies1,:).^2*ssTheta^2).^(1/2);
            dyPossibleTargetSolutions(liRotationIndicies4,:) = (dxPossibleTargetSolutions(liRotationIndicies1,:).^2*ssTheta^2+dyPossibleTargetSolutions(liRotationIndicies1,:).^2*ccTheta^2).^(1/2);                                                       
            
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
            xxPossibleMasterSolutions = reshape(completeMasterGeometry(2,possibleMasterSolutions)',[nPossibleSolutions,nSourcesPerSolution]);                        
            yyPossibleMasterSolutions = reshape(completeMasterGeometry(3,possibleMasterSolutions)',[nPossibleSolutions,nSourcesPerSolution]);                        
            dxPossibleMasterSolutions = reshape(completeMasterGeometry(6,possibleMasterSolutions)',[nPossibleSolutions,nSourcesPerSolution]);                        
            dyPossibleMasterSolutions = reshape(completeMasterGeometry(7,possibleMasterSolutions)',[nPossibleSolutions,nSourcesPerSolution]);                        
                       
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
            xxPossibleTranslations = mean(xxPossibleMasterSolutions,2)-mean(xxPossibleTargetSolutions,2);
            yyPossibleTranslations = mean(yyPossibleMasterSolutions,2)-mean(yyPossibleTargetSolutions,2);
            dxPossibleTranslations = sum([dxPossibleMasterSolutions,dxPossibleTargetSolutions].^2,2).^(1/2)/nSourcesPerSolution/2;
            dyPossibleTranslations = sum([dyPossibleMasterSolutions,dyPossibleTargetSolutions].^2,2).^(1/2)/nSourcesPerSolution/2;
                        
            % Determine the method we will use to calculate the x and y
            % translation needed to line up each possible set of master and
            % target stars. We will use a switch statement to determine the
            % course of action depending on the configuation entry
            % "TRANSLATION_CALCULATION_METHOD". Each method is decribed
            % below.
            switch MaestroConfiguration.TRANSLATION_CALCULATION_METHOD
                case {'simple','mean','quick'}
                    % If simple, mean, or quick was specified we have
                    % already calculated the translation! We will just use
                    % the mean position of the stars as some central point
                    % and slide the target field so that its center lines
                    % up with the master field. This is what was done for
                    % the initial guess for the other methods so we have
                    % nothing to do here.                    
                otherwise
                    % We have never heard of such a method. Throw an error
                    % describing the problem. 
                    error('MAESTRO:HSPREDUCTION:buildmasterfield:badTranslationCalculationMethod','Unknown configuration entry for "TRANSLATION_CALCULATION_METHOD". Please check that this configuration entry was specified correctly.');                    
            end
            
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
            xxDistance2 = (xxPossibleTargetSolutions-xxPossibleMasterSolutions+repmat(xxPossibleTranslations,[1,nSourcesPerSolution])).^2;
            yyDistance2 = (yyPossibleTargetSolutions-yyPossibleMasterSolutions+repmat(yyPossibleTranslations,[1,nSourcesPerSolution])).^2;            
            possibleTranslationalRChi2s = sum((xxDistance2+yyDistance2).^2./(xxDistance2.*(dxPossibleMasterSolutions.^2+dxPossibleTargetSolutions.^2)+yyDistance2.*(dyPossibleMasterSolutions.^2+dyPossibleTargetSolutions.^2)),2)/(nSourcesPerSolution*2-2);
                                    
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
            goodSolutionIndicies = find(possibleTranslationalRChi2s<MaestroConfiguration.POSITION_MATCH_MAX_REDUCED_CHI2);
                        
            % The order of appearance of the solutions should currently be
            % determined by the reduced chi2 during the scaling phase. If
            % there are only two stars per solution and the rotation angle
            % is either 0 or 180 there will be degenerate solutions. The
            % problem is that with two stars and the possibility of the telescope flipping we cannot tell which is which
            % based on geometry alone. In this case we will want to leave
            % the order of the solutions alone so that the set with the
            % best match to the brightnesses gets the first crack at being
            % accepted as the final solution. 
            
            % Check if we are only using two stars per permutation. If so,
            % we do not want to change the order of appearance of the
            % solutions. If not, we want the order of the solutions to be
            % determined by the best geometric fit. If there are
            % two stars per permutation we will generate an array of
            % indicies that do not change the order of the solution. If
            % there are more than that we will obtain indicies in the order
            % of increaseing translational reduced chi2. We then evaluate
            % the solution at these indicies to change the order (and don't
            % forget the rotation style and other information too). 
            if nSourcesPerSolution > 2, [junk,goodSolutionIndiciesOrder] = sort(possibleTranslationalRChi2s(goodSolutionIndicies)); goodSolutionIndicies = goodSolutionIndicies(goodSolutionIndiciesOrder); end  %#ok<ASGLU>
            possibleMasterSolutions = possibleMasterSolutions(goodSolutionIndicies,:);
            possibleTargetSolutions = possibleTargetSolutions(goodSolutionIndicies,:);
            possibleRotateSolutions = possibleRotateSolutions(goodSolutionIndicies);                   
            possibleBrightnessRChi2s = possibleBrightnessRChi2s(goodSolutionIndicies);     
            mmPossibleMasterToTargetBrightnessRatios = mmPossibleMasterToTargetBrightnessRatios(goodSolutionIndicies);
            dmPossibleMasterToTargetBrightnessRatios = dmPossibleMasterToTargetBrightnessRatios(goodSolutionIndicies);
            possibleTranslationalRChi2s = possibleTranslationalRChi2s(goodSolutionIndicies);
            xxPossibleTranslations = xxPossibleTranslations(goodSolutionIndicies);
            yyPossibleTranslations = yyPossibleTranslations(goodSolutionIndicies);
            dxPossibleTranslations = dxPossibleTranslations(goodSolutionIndicies);
            dyPossibleTranslations = dyPossibleTranslations(goodSolutionIndicies);            
            nPossibleSolutions = size(possibleMasterSolutions,1);
     
            %% BEGIN LOOP OVER POSSIBLE SOLUTIONS                                                
            % At this point most of these solutions are probably valid.
            % However, we will still investigate further to ensure we find
            % a solution that is truely ok. This is especially important if
            % multiple fields have accidentally been mixed up into these
            % images. The loop is indexed by "iSolution" and we will plan
            % to iterate over all of the solutions which matched the
            % brightness and position tests. However, if a possible
            % solution passes some criteria we will not go any further and
            % we will then call this the final solution.
            for iSolution = 1:nPossibleSolutions                              
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
                currentTargetSolution = possibleTargetSolutions(iSolution,:);
                currentMasterSolution = possibleMasterSolutions(iSolution,:);
                matchedTargetGeometry = completeTargetGeometry(:,currentTargetSolution);
                matchedMasterGeometry = completeMasterGeometry(:,currentMasterSolution);
                
                % Make a copy of the total master and target geometry. We
                % will remove the current solution from the geometry so we
                % will name this matrix "leftover". Use the indicies from
                % the current solution to eliminate all matching stars. The
                % leftover  geometry will list all stars that have not been
                % matched. Some of these could be matches but wern't
                % sampled above.                
                leftoverTargetGeometry = completeTargetGeometry;
                leftoverTargetGeometry(:,currentTargetSolution) = [];
                leftoverMasterGeometry = completeMasterGeometry; 
                leftoverMasterGeometry(:,currentMasterSolution) = [];                                     
                
                %% APPLY ROTATION TO BOTH GEOMETRIES
                % We also already know the rotation angle for this solution
                % (the angle to go from the target to master image). We can
                % rotate every leftover target star and master star right
                % now and save some computation later. We will make a copy
                % of the target and master leftover geometry that will be
                % project onto the other geometry. I.e. rotated, scaled and
                % shifted to line up.
                leftoverProjectedTargetGeometry = leftoverTargetGeometry;
                leftoverProjectedMasterGeometry = leftoverMasterGeometry;
                matchedProjectedTargetGeometry = matchedTargetGeometry;
                
                % Check what type of rotation was applied to find a
                % solution. For each type of rotation record the
                % "ttCurrentRotationAngle". This will be used to rotate the
                % data
                
                % We will now check if the rotation is as simple as no
                % rotation or a 180 degree flip. If a flip is the case we
                % can just negate the x and y values. The statistics (the
                % standard deviation of the x and y positions) are not
                % effected by this transformation.
                if any(possibleRotateSolutions(iSolution) == [1,2])
                    
                    % We have determined the rotation style is either no
                    % rotation or a flip. Lets further check if it is a
                    % flip.
                    if possibleRotateSolutions(iSolution) == 2
                    
                        % The rotation style is a flip. To flip 180 degrees
                        % is simply to negate the x and y values. no
                        % attention needs to be paid to the statistics.
                        leftoverProjectedTargetGeometry(2:3,:) = -leftoverProjectedTargetGeometry(2:3,:);        
                        leftoverProjectedMasterGeometry(2:3,:) = -leftoverProjectedMasterGeometry(2:3,:);
                        matchedProjectedTargetGeometry(2:3,:) = -matchedProjectedTargetGeometry(2:3,:);
                        
                    end 
                    
                else
                               try                             
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
                    if possibleRotateSolutions(iSolution) == 3
                        ttActiveRotationAngle = ttRotationAngle;                               
                    else
                        ttActiveRotationAngle = ttRotationAngle;
                    end
                    
                               catch me
                                   me
                                   keyboard
                               end
                    % Now it is time to rotate the target field. We will
                    % perform a simple euleren rotation X' = XC+YS, Y =
                    % -XS+YC. We do the whole calculation in one fell swoop
                    % using the newly calculate "ttActiveRotationAngle".
                    leftoverProjectedTargetGeometry(2:3,:) = [leftoverProjectedTargetGeometry(2,:)*cos(ttActiveRotationAngle)+leftoverProjectedTargetGeometry(3,:)*sin(ttActiveRotationAngle);-leftoverProjectedTargetGeometry(2,:)*sin(ttActiveRotationAngle)+leftoverProjectedTargetGeometry(3,:)*cos(ttActiveRotationAngle)];                                        
                    leftoverProjectedMasterGeometry(2:3,:) = [leftoverProjectedMasterGeometry(2,:)*cos(ttActiveRotationAngle)+leftoverProjectedMasterGeometry(3,:)*sin(ttActiveRotationAngle);-leftoverProjectedMasterGeometry(2,:)*sin(ttActiveRotationAngle)+leftoverProjectedMasterGeometry(3,:)*cos(ttActiveRotationAngle)];                                       
                    matchedProjectedTargetGeometry(2:3,:) = [matchedProjectedTargetGeometry(2,:)*cos(ttActiveRotationAngle)+matchedProjectedTargetGeometry(3,:)*sin(ttActiveRotationAngle);-matchedProjectedTargetGeometry(2,:)*sin(ttActiveRotationAngle)+matchedProjectedTargetGeometry(3,:)*cos(ttActiveRotationAngle)];                                        

                    
                    % We also need to take care of statistics. With the
                    % rotation we shuffle around the errors in the x and y
                    % direction. Although typically the error in a stars
                    % position will be the same in x and y this is not true
                    % when the psf is elliptical. This is a rather simple
                    % propgation of error problem.
                    leftoverProjectedTargetGeometry(6:7,:) = ([leftoverProjectedTargetGeometry(6,:).^2*cos(ttActiveRotationAngle)^2+leftoverProjectedTargetGeometry(7,:).^2*sin(ttActiveRotationAngle)^2;leftoverProjectedTargetGeometry(6,:).^2*sin(ttActiveRotationAngle)^2+leftoverProjectedTargetGeometry(7,:).^2*cos(ttActiveRotationAngle)^2]).^(1/2);                                                                                                         
                    leftoverProjectedMasterGeometry(6:7,:) = ([leftoverProjectedMasterGeometry(6,:).^2*cos(ttActiveRotationAngle)^2+leftoverProjectedMasterGeometry(7,:).^2*sin(ttActiveRotationAngle)^2;leftoverProjectedMasterGeometry(6,:).^2*sin(ttActiveRotationAngle)^2+leftoverProjectedMasterGeometry(7,:).^2*cos(ttActiveRotationAngle)^2]).^(1/2);                                                                 
                    matchedProjectedTargetGeometry(6:7,:) = ([matchedProjectedTargetGeometry(6,:).^2*cos(ttActiveRotationAngle)^2+matchedProjectedTargetGeometry(7,:).^2*sin(ttActiveRotationAngle)^2;matchedProjectedTargetGeometry(6,:).^2*sin(ttActiveRotationAngle)^2+matchedProjectedTargetGeometry(7,:).^2*cos(ttActiveRotationAngle)^2]).^(1/2);                                                                                                         
                    
                end
                
              %% APPLY SCALING AND TRANSLATION
              % We want to project the master and target fields onto
              % eachother. Use the calculated values to apply this
              % translation and scaling to the unmatched stars. This also
              % scales the statistics of the star brightness.
              matchedProjectedTargetGeometry(4,:) = matchedProjectedTargetGeometry(4,:)*mmPossibleMasterToTargetBrightnessRatios(iSolution);
              matchedProjectedTargetGeometry(8,:) = matchedProjectedTargetGeometry(8,:)*mmPossibleMasterToTargetBrightnessRatios(iSolution);
              matchedProjectedTargetGeometry(2,:) = matchedProjectedTargetGeometry(2,:)+xxPossibleTranslations(iSolution);
              matchedProjectedTargetGeometry(3,:) = matchedProjectedTargetGeometry(3,:)+yyPossibleTranslations(iSolution);
              
              leftoverProjectedTargetGeometry(4,:) = leftoverProjectedTargetGeometry(4,:)*mmPossibleMasterToTargetBrightnessRatios(iSolution);
              leftoverProjectedTargetGeometry(8,:) = leftoverProjectedTargetGeometry(8,:)*mmPossibleMasterToTargetBrightnessRatios(iSolution);
              leftoverProjectedMasterGeometry(4,:) = leftoverProjectedMasterGeometry(4,:)/mmPossibleMasterToTargetBrightnessRatios(iSolution);
              leftoverProjectedMasterGeometry(8,:) = leftoverProjectedMasterGeometry(8,:)/mmPossibleMasterToTargetBrightnessRatios(iSolution);
              leftoverProjectedTargetGeometry(2,:) = leftoverProjectedTargetGeometry(2,:)+xxPossibleTranslations(iSolution);
              leftoverProjectedTargetGeometry(3,:) = leftoverProjectedTargetGeometry(3,:)+yyPossibleTranslations(iSolution);
              leftoverProjectedMasterGeometry(2,:) = leftoverProjectedMasterGeometry(2,:)-xxPossibleTranslations(iSolution);
              leftoverProjectedMasterGeometry(3,:) = leftoverProjectedMasterGeometry(3,:)-yyPossibleTranslations(iSolution);
              
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
              dxBetweenTargetAndMaster = repmat(leftoverProjectedTargetGeometry(2,:),[size(leftoverMasterGeometry,2),1])-repmat(leftoverMasterGeometry(2,:)',[1,size(leftoverProjectedTargetGeometry,2)]);                            
              dyBetweenTargetAndMaster = repmat(leftoverProjectedTargetGeometry(3,:),[size(leftoverMasterGeometry,2),1])-repmat(leftoverMasterGeometry(3,:)',[1,size(leftoverProjectedTargetGeometry,2)]);
              
              % Another piece of information we will need to figure out if
              % any of these stars match is the total variance (combined master and target) in both the
              % x and y direction.
              dxTotalVariance = repmat(leftoverProjectedTargetGeometry(6,:).^2,[size(leftoverMasterGeometry,2),1])+repmat(leftoverMasterGeometry(6,:)'.^2,[1,size(leftoverProjectedTargetGeometry,2)]);                                          
              dyTotalVariance = repmat(leftoverProjectedTargetGeometry(7,:).^2,[size(leftoverMasterGeometry,2),1])+repmat(leftoverMasterGeometry(7,:)'.^2,[1,size(leftoverProjectedTargetGeometry,2)]);                                          
              
              % Now calculate the value of reduced chi squared for every
              % combination of leftover target and master stars. This is
              % essentially the goodness of fit between the master and
              % target leftover stars given our solution. The degrees of
              % freedom is 2 because we have two stars and the fit parameters
              % were not found from these variables. If you object to this
              % let me know. 
              possibleNewMatchesRChi2s = (dxBetweenTargetAndMaster.^2+dyBetweenTargetAndMaster.^2).^2./(dxTotalVariance.*dxBetweenTargetAndMaster.^2+dyTotalVariance.*dyBetweenTargetAndMaster.^2);
              
              % Obtain the absolute indicies of the target and master stars
              % that matched. Each of these should be nx1 arrays of
              % indicies relative to the leftover stars in the master and
              % target geometry respectively.
              [aiIndirectMasterMatches,aiIndirectTargetMatches] = ind2sub(size(dxBetweenTargetAndMaster),find(possibleNewMatchesRChi2s<4 | (dxBetweenTargetAndMaster.^2+dyBetweenTargetAndMaster.^2).^(1/2)<1));                
              
              
              % Remove the stars that matched. These stars were most likely
              % not matched earlier due to computational limitations. We
              % will just remove them from the leftover and projected
              % geometry.               
              leftoverTargetGeometry(:,aiIndirectTargetMatches) = [];
              leftoverProjectedTargetGeometry(:,aiIndirectTargetMatches) = [];
              leftoverMasterGeometry(:,aiIndirectMasterMatches) =[];
              leftoverProjectedMasterGeometry(:,aiIndirectMasterMatches) = [];                            
              
          
                                                                             
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
              leftoverConsistencyType = zeros(size(leftoverProjectedMasterGeometry,2),1);
              
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
              for iStar = 1:size(leftoverProjectedMasterGeometry,2)
                  
                  % Check image size. If the position of the supposed
                  % star is off image we can get no information about
                  % whether this solution appears correct or whether this
                  % is really a master star. The value for this star in
                  % "unmatchedType" is already zero so we can just
                  % continue on.
                  if leftoverProjectedMasterGeometry(2,iStar) < 1 || leftoverProjectedMasterGeometry(2,iStar) > xImageSize || leftoverProjectedMasterGeometry(3,iStar) < 1 || leftoverProjectedMasterGeometry(3,iStar) > yImageSize, continue, end
                  
                  % Calculate chi2 for this star. A value of 9 for chi
                  % means that the amplitude on image is within 3 sigma
                  % of the master value.
                  statisticalDifference = (leftoverProjectedMasterGeometry(4,iStar)-signalImage(round(leftoverProjectedMasterGeometry(3,iStar)),round(leftoverProjectedMasterGeometry(2,iStar)))).^2/(noiseImage(round(leftoverProjectedMasterGeometry(3,iStar)),round(leftoverProjectedMasterGeometry(2,iStar))).^2+leftoverProjectedMasterGeometry(8,iStar)^2+MaestroConfiguration.MAX_SOURCE_VARIABILITY^2*(leftoverProjectedMasterGeometry(4,iStar)^2+signalImage(round(leftoverProjectedMasterGeometry(3,iStar)),round(leftoverProjectedMasterGeometry(2,iStar)))));
                  
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
              totalGoodStaritude = sum(completeMasterGeometry(10,[currentMasterSolution,aiIndirectMasterMatches']));
             
                  
                            
              % Add together the staritude of all unmatched master stars
              % which were statistically inconsistant with the target
              % image (the entries in unmatchedType with index 2)
              totalBadStaritude = sum(leftoverProjectedMasterGeometry(10,leftoverConsistencyType==2));
              
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
              XXW1 = 1./(matchedProjectedTargetGeometry(6,:).^2+dxPossibleTranslations(iSolution)^2);
              XXW2 = 1./(matchedMasterGeometry(6,:).^2);
              YYW1 = 1./(matchedProjectedTargetGeometry(7,:).^2+dyPossibleTranslations(iSolution)^2);
              YYW2 = 1./(matchedMasterGeometry(7,:).^2);
              ZZW1 = 1./(matchedProjectedTargetGeometry(8,:).^2+dmPossibleMasterToTargetBrightnessRatios(iSolution)^2);
              ZZW2 = 1./(matchedMasterGeometry(8,:).^2);
              
              MasterFieldArray(iMasterField).Geometry(2,currentMasterSolution) = (matchedProjectedTargetGeometry(2,:).*XXW1+matchedMasterGeometry(2,:).*XXW2)./(XXW1+XXW2);
              MasterFieldArray(iMasterField).Geometry(3,currentMasterSolution) = (matchedProjectedTargetGeometry(3,:).*YYW1+matchedMasterGeometry(3,:).*YYW2)./(YYW1+YYW2);
              
              % Now take care of the errors. The square error in the master
              % positions is just 1 over the sum of the weights.
          %    MasterFieldArray(iMasterField).Geometry(6,currentMasterSolution) = 1./(XXW1+XXW2).^(1/2);
          %    MasterFieldArray(iMasterField).Geometry(7,currentMasterSolution) = 1./(YYW1+YYW2).^(1/2);
              
              % Now we need to update the brightness of the stars by
              % merging the two images. This is pretty much the same
              % calculation as above except with a scaling factor instead
              % of an offset.
              MasterFieldArray(iMasterField).Geometry(4,currentMasterSolution) = (matchedProjectedTargetGeometry(4,:).*ZZW1+matchedMasterGeometry(4,:).*ZZW2)./(ZZW1+ZZW2);
           %   MasterFieldArray(iMasterField).Geometry(8,currentMasterSolution) = 1./(ZZW1+ZZW2).^(1/2);
           
            %% UPDATE STARITUDE
              % The master stars that directly matched stars on the
              % target field deserve some love. We will add one to their
              % staritude. This will give them more weight in the future
              % when checking if a solution is valid. Its sort of saying
              % I now believe that there is really a star in this
              % position a little more than before.
              MasterFieldArray(iMasterField).Geometry(10,currentMasterSolution) = MasterFieldArray(iMasterField).Geometry(10,currentMasterSolution)+MaestroConfiguration.STARITUDE_DIRECT_MATCH_BONUS;
              
              % Stars that were matched after the fact, i.e. were not
              % included in the initial solution but still were matched
              % will also get a bonus to their staritude.
              % Here something funny!
              MasterFieldArray(iMasterField).Geometry(10,aiIndirectMasterMatches) = MasterFieldArray(iMasterField).Geometry(10,aiIndirectMasterMatches)+MaestroConfiguration.STARITUDE_INDIRECT_MATCH_BONUS;
              
              % Stars that were off of the image get what should be a small
              % penalty. We really can't say anything about whether or not
              % they are there. If they show up several times this penalty
              % shouldn't be bad enough to kill them off.                            
              MasterFieldArray(iMasterField).Geometry(10,leftoverMasterGeometry(1,leftoverConsistencyType==0)) = MasterFieldArray(iMasterField).Geometry(10,leftoverMasterGeometry(1,leftoverConsistencyType==0)) - MaestroConfiguration.STARITUDE_OFF_IMAGE_PENALTY;
              
              % The stars which were in agreement with the image but were
              % not detected as stars. Their staritude will slowly decay as
              % other stars are matched. The decay rate is controlled by
              % the config. The real purpose of this is in case one bad
              % match occurs. In this case thse stars would slowly fade
              % away even if they are off image. It also gets rid of some
              % really faint stars that aren't worth caring about. Think
              % about this as saying "We are punishing these stars for not
              % showing up enough."
              MasterFieldArray(iMasterField).Geometry(10,leftoverMasterGeometry(1,leftoverConsistencyType==1)) = MasterFieldArray(iMasterField).Geometry(10,leftoverMasterGeometry(1,leftoverConsistencyType==1)) - MaestroConfiguration.STARITUDE_CONSISTANCY_PENALTY;
              
              % The stars that were not in agreement with the image get
              % punished severely.
              MasterFieldArray(iMasterField).Geometry(10,leftoverMasterGeometry(1,leftoverConsistencyType==2)) = MasterFieldArray(iMasterField).Geometry(10,leftoverMasterGeometry(1,leftoverConsistencyType==2)) - MaestroConfiguration.STARITUDE_DISAGREEMENT_PENALTY;
              
              % Remove stars that have a negative staritude.
              MasterFieldArray(iMasterField).Geometry(:,MasterFieldArray(iMasterField).Geometry(10,:)<0) = [];
                            
              %% RECORD THE SOLUTION
              % Now that we know the solution is valid we can record it
              % in the field solutions array. This array will hold all
              % relavant information we can think of. For more
              % information on what each of these fields mean see the
              % HSPREDUCTION class property "FieldSolutions". This
              % structure "FieldSolutions" will be copied back into the
              % object when we are finished.
              FieldSolutions(iFITSObject).WasFound = true;
              FieldSolutions(iFITSObject).FieldIndex = iMasterField;
              FieldSolutions(iFITSObject).xxTranslation = xxPossibleTranslations(iSolution);
              FieldSolutions(iFITSObject).dxTranslation = dxPossibleTranslations(iSolution);
              FieldSolutions(iFITSObject).yyTranslation = yyPossibleTranslations(iSolution);
              FieldSolutions(iFITSObject).dyTranslation = dyPossibleTranslations(iSolution);
              FieldSolutions(iFITSObject).mmRatio = mmPossibleMasterToTargetBrightnessRatios(iSolution);
              FieldSolutions(iFITSObject).dmRatio = dmPossibleMasterToTargetBrightnessRatios(iSolution);
              FieldSolutions(iFITSObject).nHashSources = nSourcesPerPermutation;
              FieldSolutions(iFITSObject).nTotalMatches = length(aiIndirectTargetMatches)+nSourcesPerPermutation;
              FieldSolutions(iFITSObject).RotationStyle = possibleRotateSolutions(iSolution);
              FieldSolutions(iFITSObject).GoodStaritude = totalGoodStaritude;
              FieldSolutions(iFITSObject).BadStaritude = totalBadStaritude;
              FieldSolutions(iFITSObject).TranslationalRC2 = possibleTranslationalRChi2s(iSolution);
              FieldSolutions(iFITSObject).ScalingAC2 = possibleBrightnessRChi2s(iSolution);
              FieldSolutions(iFITSObject).GaussianSTD = median(matchedTargetGeometry(5,:));
                                                        
              %% ADD NEW MASTER STARS
              % The unmatched target stars will all be added to the
              % master field with zero staritude.
              
              MasterFieldArray(iMasterField).Geometry = [MasterFieldArray(iMasterField).Geometry,[leftoverProjectedTargetGeometry;zeros(1,size(leftoverProjectedTargetGeometry,2))]];
              MasterFieldArray(iMasterField).Geometry(1,:) = 1:size(MasterFieldArray(iMasterField).Geometry,2);
              FieldSolutions(iFITSObject).WasFound = true;
               catch ME
                  keyboard
              end
              
              
              
              break
              
              
              
                
        end
            
            if FieldSolutions(iFITSObject).WasFound == true, break, end
            
        end
        
        if FieldSolutions(iFITSObject).WasFound == true, break, end
        
    end
    %% * RECORD A NEW MASTER FIELD (IF NECESSARY) *
    % We can end up here two different ways. Either there was no master
    % field to loop over and no solution was recorded or despite a master
    % field existing no matches were found. Either way a master field will
    % be recorded if no solution was found and this part of the code was
    % reached.
    
    % Check if a solution was found. If no solution was found this
    % is a new field.
    
    if ~FieldSolutions(iFITSObject).WasFound && size(completeTargetGeometry,2) > 1
        MasterFieldArray(length(MasterFieldArray)+1).Geometry = [completeTargetGeometry;zeros(1,size(completeTargetGeometry,2))];
        MasterFieldArray(length(MasterFieldArray)).JulianDate = FITSList(iFITSObject).JulianDate;
        MasterFieldArray(length(MasterFieldArray)).FieldName = datestr(now,'yyyymmdd_HHMMSS_FFF');
        MasterFieldArray(length(MasterFieldArray)).Labels = {};
      
           FieldSolutions(iFITSObject).WasFound = true;
              FieldSolutions(iFITSObject).FieldIndex = length(MasterFieldArray);
              FieldSolutions(iFITSObject).xxTranslation = 0;
              FieldSolutions(iFITSObject).dxTranslation = 0;
              FieldSolutions(iFITSObject).yyTranslation = 0;
              FieldSolutions(iFITSObject).dyTranslation = 0;
              FieldSolutions(iFITSObject).mmRatio = 0;
              FieldSolutions(iFITSObject).dmRatio = 0;
              FieldSolutions(iFITSObject).nHashSources = size(completeTargetGeometry,2);
              FieldSolutions(iFITSObject).RotationStyle = 1;
              FieldSolutions(iFITSObject).GoodStaritude = 0;
              FieldSolutions(iFITSObject).BadStaritude = 0;
              FieldSolutions(iFITSObject).TranslationalRC2 = 0;
              FieldSolutions(iFITSObject).ScalingAC2 = 0;
	      FieldSolutions(iFITSObject).GaussianSTD = median(completeTargetGeometry(5,:));
        % Insert the new field into the cell array of master fields. Obtain
        % the index of which we will record the master field to. This index
        % will be the current number of master fields plus one.
        % masterFieldCellArray{length(masterFieldCellArray)+1} = NewField; %#ok<AGROW>
        
        % Record the julian day of the master field for rotation purposes.
        % Note that because we already added the STARFIELD to the master
        % field that the index here does not need a "plus one".
        %masterFieldJulianDate(length(masterFieldCellArray)) = HSPReduction.; %#ok<AGROW>
        
        % Record the solution. The default values for the solution are fine
        % for this. We only need to change that the solution was found and
        % what the master field index is. nStarsPerHash=0 will indicate
        % that this is a master image.
 
    end
    
    %% UPDATE THE PROCESS
    % Update the process.We update the process after each image is
    % analysed.
    mprocessupdate(pid,iFITSObject/length(FITSList));    
    FITSList(iFITSObject).clear;
 
end
mprocessfinish(pid,1);

try
% Erase bad stars
for iMasterField = 1:length(MasterFieldArray)
	MasterFieldArray(iMasterField).Geometry = MasterFieldArray(iMasterField).Geometry(:,MasterFieldArray(iMasterField).Geometry(10,:)>10); 

end
catch ME
ME
keyboard
end

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
HSPReduction.MasterFieldArray = MasterFieldArray;
HSPReduction.FieldSolutions = FieldSolutions;



%% DETERMINE ROTATION STYLE OF EACH MASTER FIELD

MasterFieldArray = HSPReduction.MasterFieldArray;
FieldSolutions = HSPReduction.FieldSolutions;


for iMasterField = 1:length(MasterFieldArray)  
    
    MasterFieldArray(iMasterField).Labels = cell(size(MasterFieldArray(iMasterField).Geometry,2),1);
    for iStar = 1:size(MasterFieldArray(iMasterField).Geometry,2)
        MasterFieldArray(iMasterField).Labels{iStar} = ['Unknown',num2str(iStar)];        
    end
    
    currentSolutions = FieldSolutions([FieldSolutions.FieldIndex]==iMasterField);
    currentIndicies = find([FieldSolutions.FieldIndex]==iMasterField);
    
  %  MasterFieldArray(iMasterField).FieldName = 'unknown';
    rotationStyles = [currentSolutions.RotationStyle];            
    fixedFieldPoints = length(nonzeros(rotationStyles==1));
    flippedFieldPoints = length(nonzeros(rotationStyles==2));
    rotatingCWPoints = length(nonzeros(rotationStyles==3));
    rotatingCCWPoints = length(nonzeros(rotationStyles==4));
    
    
    
    if fixedFieldPoints+flippedFieldPoints < rotatingCWPoints 
        %Deal with rotating
        MasterFieldArray(iMasterField).RotationStyle = 4;
    elseif fixedFieldPoints+flippedFieldPoints <rotatingCCWPoints
        MasterFieldArray(iMasterField).RotationStyle = 3;
    else
                    
       currentSolutions = currentSolutions(rotationStyles==1 | rotationStyles==2);
       rotationStyles = rotationStyles(rotationStyles == 1 | rotationStyles==2);
       currentIndicies = currentIndicies(rotationStyles==1 | rotationStyles==2);                     
               
       bestModelFitR2 = length(nonzeros(rotationStyles==2));
       isInverted = false;                     
       flipIndex = [];       
       
       for iFlipIndex = 1:length(currentSolutions)
           
           model = [ones(iFlipIndex,1);ones(length(currentSolutions)-iFlipIndex,1)*2]';
          
           currentR2 = sum(model~=rotationStyles);
           currentFlippedR2 = sum(~model~=rotationStyles);
           if currentR2 < bestModelFitR2
               bestModelFitR2 = currentR2;
               flipIndex = iFlipIndex+1;
               isInverted = false;
           end
                                 
           if currentFlippedR2 < bestModelFitR2
               bestModelFitR2 = currentFlippedR2;
               flipIndex = iFlipIndex+1;
               isInverted = true;               
           end
           
       end
       
       
       if isempty(flipIndex)
           MasterFieldArray(iMasterField).RotationStyle = 1;           
       else
           MasterFieldArray(iMasterField).RotationStyle = 2;
           MasterFieldArray(iMasterField).RotationFlipIndex = currentIndicies(flipIndex);
           MasterFieldArray(iMasterField).RotationIsFlipInverted = isInverted;
       end
                                        
    end        
    
end

HSPReduction.MasterFieldArray = MasterFieldArray;

