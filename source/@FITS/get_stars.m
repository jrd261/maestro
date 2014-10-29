function get_stars(obj)

    % Retrieve the signal and noise images.
    sImage = obj.get_signal_image;
    nImage = obj.get_noise_image;
    

                %% Extract Relavant Configuration
                % See the default reduction style configuration for what these parameters represent.
                
                LOCALE = mconfig;
                
                noiseThreshold = LOCALE.STAR_FINDING_NOISE_THRESHOLD;
                maxPercentagePossibleStars = LOCALE.STAR_FINDING_MAX_PERCENT_POSSIBLE_STARS;
                sigmaEstimated = LOCALE.STAR_FINDING_SIGMA_ESTIMATED;
                searchBoxSize = ceil(LOCALE.STAR_FINDING_SEARCH_BOX_SIZE*sigmaEstimated);
                maxLinear = LOCALE.MAX_LINEAR;
                crCutoff = LOCALE.STAR_FINDING_COSMIC_RAY_CUTOFF;
                galaxyCutoff = LOCALE.STAR_FINDING_GALAXY_CUTOFF;
                fitInitialLambda = LOCALE.STAR_CENTERING_PRELIMINARY_FIT_LAMBDA;
                fitTolerance = LOCALE.STAR_CENTERING_PRELIMINARY_FIT_TOLERANCE;
                fitIterations = LOCALE.STAR_CENTERING_PRELIMINARY_FIT_ITERATIONS;
                lambdaMultiplier = LOCALE.STAR_CENTERING_PRELIMINARY_FIT_LAMBDA_MULTIPLIER;
                minConvergence = LOCALE.STAR_CENTERING_PRELIMINARY_FIT_MIN_CONVERGENCE;
                
                
                % Extract the sky removed image.
                skyRemovedImage = obj.SkyRemovedPrimaryImage;
                
                % Extract the noise image.
                noiseImage = obj.NoisePrimaryImage;
                
                % Extract the x and y image sizes.
                xImageSize = size(skyRemovedImage,2);
                yImageSize = size(skyRemovedImage,1);
                
                % Create the x and y grids.
                [xGrid,yGrid] = meshgrid(1:xImageSize,1:yImageSize);
                
                % Obtain pixels which are above the noise threshold.
                aboveThresholdIndicies = skyRemovedImage > noiseImage*noiseThreshold;
                
                % Obtain a list of x and y values above this threshold.
                xValues = xGrid(aboveThresholdIndicies);
                yValues = yGrid(aboveThresholdIndicies);
                zValues = skyRemovedImage(aboveThresholdIndicies);
                sValues = zeros(length(xValues),1);
                
                % Obtain indicies for stars too close to the edge of the image.
                badIndicies = (xValues<=searchBoxSize+1 | xValues >= xImageSize-searchBoxSize-1 | yValues<=searchBoxSize+1 | yValues >= yImageSize-searchBoxSize-1);
                
                % Obtain indicies for stars with too large of an amplitude.
                badIndicies = badIndicies | zValues > maxLinear;
                
                % Remove all values near the edge of the image.
                xValues(badIndicies) = [];
                yValues(badIndicies) = [];
                zValues(badIndicies) = [];
                sValues(badIndicies) = [];
                
                % Sort the values by amplitude.
                [junk,sortOrder] = sort(zValues,'descend'); %#ok<ASGLU>
                
                % Check we have not exceeded the max allowed possible stars.
                if(length(xValues)/(xImageSize*yImageSize) > maxPercentagePossibleStars)
                    
                    % Calculate the desired length.
                    desiredLength = round(maxPercentagePossibleStars*(xImageSize*yImageSize));
                    
                    % Rewrite the sort order.
                    sortOrder = sortOrder(1:desiredLength);
                    
                end
                
                % Rewrite the values.
                xValues = xValues(sortOrder);
                yValues = yValues(sortOrder);
                zValues = zValues(sortOrder);
                sValues = sValues(sortOrder);
                dxValues = zeros(size(zValues));
                dyValues = zeros(size(zValues));
                dzValues = zeros(size(zValues));
                dsValues = zeros(size(zValues));
                
                % Create an index to record the stars.
                goodStarIndex = false(length(xValues),1);
                
                % Initialize number of stars found.
                numStarsFound = 0;
                
            
                % Start loop over all possible stars.
                for iStar = 1:length(xValues)
                   
                    try
                    
                    % Obtain a little image around that pixel.
                    partialImage = skyRemovedImage(yValues(iStar)-searchBoxSize:yValues(iStar)+searchBoxSize,xValues(iStar)-searchBoxSize:xValues(iStar)+searchBoxSize);
                    % Check if any pixels in the box are larger than the current pixel.
                    if length(nonzeros(partialImage(:) >= partialImage(searchBoxSize+1,searchBoxSize+1))) > 1, continue, end
                    
                    % We are fitting a gaussian of the functional form f=A*exp(-(x-x0)^2/2/s^2-(y-y0)^2/2/s^2)
                    
                    % Record an estimate for fitting parameters.
                    A = zValues(iStar);
                    X0 = xValues(iStar);
                    Y0 = yValues(iStar);
                    S = sigmaEstimated;
                    
                    % Rip a piece of the grid and image for evaluation.
                    X = xGrid(Y0-searchBoxSize:Y0+searchBoxSize,X0-searchBoxSize:X0+searchBoxSize);
                    Y = yGrid(Y0-searchBoxSize:Y0+searchBoxSize,X0-searchBoxSize:X0+searchBoxSize);
                    Z = skyRemovedImage(Y0-searchBoxSize:Y0+searchBoxSize,X0-searchBoxSize:X0+searchBoxSize);                                
                    W = real(1./noiseImage(Y0-searchBoxSize:Y0+searchBoxSize,X0-searchBoxSize:X0+searchBoxSize).^2);
                    % Obtain indicies which lie within the appropriate radius.
                    activeIndicies = (X(:)-X0).^2+(Y(:)-Y0).^2 <= searchBoxSize^2;
                    
                    % Obtain grid and image.
                    X = X(activeIndicies);
                    Y = Y(activeIndicies);
                    Z = Z(activeIndicies);
                    W = diag(W(activeIndicies));
                    
                    % Jacobian stored here.
                    J = zeros(length(Z),4);
                    
                    % Nllsqr M-L Lambda
                    L = fitInitialLambda;
                    
                    % Reset the continuation paramter.
                    goOn = true;
                    
                    % Begin loop to iterate solution.
                    for iIteration=1:fitIterations
                        if abs(imag(A))>0, keyboard, end
                        % Obtain the residual.
                        preResidual = sum((A*exp(-(X-X0).^2/2/S^2-(Y-Y0).^2/2/S^2)-Z).^2);
                        
                        
                        % Obtain the jacobian.
                        J(:,1) = 1./exp((X - X0).^2/(2*S^2) + (Y - Y0).^2/(2*S^2));
                        J(:,2) = (A*(2*X - 2*X0))./(2*S^2*exp((X - X0).^2/(2*S^2) + (Y - Y0).^2/(2*S^2)));
                        J(:,3) = (A*(2*Y - 2*Y0))./(2*S^2*exp((X - X0).^2/(2*S^2) + (Y - Y0).^2/(2*S^2)));
                        J(:,4) = (A*((X - X0).^2/S^3 + (Y - Y0).^2/S^3))./exp((X - X0).^2/(2*S^2) + (Y - Y0).^2/(2*S^2));
                        
                        % Perform a fitting iteration.
                        %dPar = (J'*J + L*eye(size(J,2)))^(-1)*J'*(Z-A*exp(-(X-X0).^2/2/S^2-(Y-Y0).^2/2/S^2));
                                               
                        dPar = (J'*W*J + L*eye(size(J,2)))^(-1)*J'*W*(Z-A*exp(-(X-X0).^2/2/S^2-(Y-Y0).^2/2/S^2));
                        %dPar = (J'*W*J + L*eye(size(J,2)))\(J'*W*(Z-A*exp(-(X-X0).^2/2/S^2-(Y-Y0).^2/2/S^2)));

                        
                        % Update the parameters.
                        A = A + dPar(1);
                        X0 = X0 + dPar(2);
                        Y0 = Y0 + dPar(3);
                        S = S + dPar(4);
                        S = abs(S);
                        
                        % Obtain the residual.
                        postResidual = sum((A*exp(-(X-X0).^2/2/S^2-(Y-Y0).^2/2/S^2)-Z).^2);
                        
                        % Check the the star is within the search box.
                        if abs(X0-xValues(iStar)) > searchBoxSize || abs(Y0-yValues(iStar)) > searchBoxSize, goOn = false; break, end
                        
                        % Check that the standard deviation is not too small.
                        if S<crCutoff, goOn = false; break, end
                        
                        % Check that the standard deviation is not too large.
                        if S>galaxyCutoff, goOn = false; break, end
                        
                        % Check if we have gotten to the tolerance desired.
                        if(abs(postResidual/preResidual - 1) < fitTolerance)
                            break;
                        elseif(postResidual/preResidual > minConvergence)
                            L = L/lambdaMultiplier;
                        else
                            L = L*lambdaMultiplier;
                        end
                        
                        
                    end
                    
                    catch ME
                        goOn = false;
                    end
                    
                    
                    % Check if we should continue with this star.
                    if(~goOn)
                        continue
                    end
                    
                    
          
                    
                   M = (J'*W*J)^-1;
                                        
                %    M = (J'*J)^-1*postResidual/(length(X(:))-4);

                    if A<0 || M(2,2)^.5 > searchBoxSize || M(3,3)^.5 > searchBoxSize, continue, end
                    % Mark this star as good.
                    goodStarIndex(iStar) = true;
                    
                    % Copy over x,y, and z values.
                    xValues(iStar) = X0;
                    yValues(iStar) = Y0;
                    zValues(iStar) = A;
                    sValues(iStar) = S;
                    dzValues(iStar) = M(1,1).^.5;
                    dxValues(iStar) = M(2,2).^.5;
                    dyValues(iStar) = M(3,3).^.5;
                    dsValues(iStar) = M(4,4).^.5;
                    
                    % Indicate that we found another star.
                    numStarsFound = numStarsFound+1;
                    
                    if numStarsFound > LOCALE.STAR_FINDING_MAX_STARS, break, end
                end
		

		if length(nonzeros(goodStarIndex))>LOCALE.STAR_FINDING_MAX_STARS
			goodStarIndex = find(goodStarIndex);
			goodStarIndex = goodStarIndex(1:LOCALE.STAR_FINDING_MAX_STARS);
        end
        

                xValues = xValues(goodStarIndex);
                yValues = yValues(goodStarIndex);
                zValues = zValues(goodStarIndex);
                sValues = sValues(goodStarIndex);
                dxValues = dxValues(goodStarIndex);
                dyValues = dyValues(goodStarIndex);
                dzValues = dzValues(goodStarIndex);
                dsValues = dsValues(goodStarIndex);
                nValues = (1:length(xValues))';
                                    
                
             
                obj.S_LocatedStarsDev = [nValues,xValues,yValues,zValues,sValues,dxValues,dyValues,dzValues,dsValues]';
                
              
            
           stars = obj.S_LocatedStarsDev;
            


end