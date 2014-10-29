function [x,y,par,cov] = mcenterstars(image,x,y,r,method) 
%MCENTERSTARS Calculates the center of star-like objects on an image.
%   [X,Y] = MCENTERSTARS(IMAGE,X,Y,R) fits individual 2d gaussians at each
%   specified location given by the list of coordinates (X,Y) and returns
%   the center of the gaussian (X,Y). R is the distance from the initial
%   guess to include in the fit.
%
%   [X,Y,PAR] = MCENTERSTARS(IMAGE,X,Y,R) returns PAR, an 4xn list of
%   resultant parameters where n is the number of stars and the rows
%   represent the values of A, X0, Y0, S, for the fit
%   A*EXP(-((X-X0)^2-(Y-Y0)^2)/S^2) (a 2d gaussian).
%
%   MCENTERSTARS(IMAGE,X,Y,R,MODEL) uses the model given by "MODEL" to
%   center the stars. The default model is "gaussian". Other possible
%   models are "".
% 
%   [X,Y,PAR,COV] = MCENTERSTARS(...) will also return the covariance
%   matrix from the fit. COV has size n x n where n is the number of
%   parameters and is sparse. Read up on covariance matricies for more
%   information and motivation.
%
%   Copyright (C) 2007-2011 James Dalessio

X0 = x;
Y0 = y;

% If no method is specified make the current method gaussian.
if nargin < 5, method = 'gaussian'; end

% Use a switch statement to determine the fitting method.
switch method
    case {'gaussian'} % A*EXP(-R^2/S^2) 
        
        % Initialize output variables. For a symmetric 2d gaussian + sky we
        % have 5 parameters. X and Y are already initialized as input
        % variables.
        par = zeros(4,length(x));
        cov = sparse(4*length(x),4*length(x));
        
        % Obtain the identity matrix for the M-L fit.            
        E = eye(4);
            
        % Loop over all given star locations.
        for iStar = 1:length(x)                     
            
            try
                        
            % Extract the x, y, and z values within the range that we will
            % use for fitting.
            [xx,yy,zz] = mrip(image,x(iStar),y(iStar),0,r);
                                                       
            % Make some initial guesses for the gaussian amplitude and the
            % standard deviation. We use the maximum pixel value for the
            % amplitude and a function called "MSIGMAESTIMATOR" to estimate
            % the value of sigma. Not sure about the robustness of the
            % sigma estimator.
            a = max(zz);                                 
            s = msigmaestimator(xx,yy,zz); 
                                                                                   
            % Initialize the jacobian. We are writing in ones because the fifth column will be ones anyway.
            J = zeros(length(zz),4);
            
            % Evaluate the initial residual.
            preResidual = sum((a*exp(-((xx-x(iStar)).^2+(yy-y(iStar)).^2)/s^2)-zz).^2);
                        
            % Start lambda at its initial value
            L = 1;            
            
            % Begin loop to iterate solution.
            for iIteration=1:50                                               
                % Obtain the jacobian.
                J(:,1) = 1./exp((xx - x(iStar)).^2/(2*s^2) + (yy - y(iStar)).^2/(2*s^2));
                J(:,2) = (a*(2*xx - 2*x(iStar)))./(2*s^2*exp((xx - x(iStar)).^2/(2*s^2) + (yy - y(iStar)).^2/(2*s^2)));
                J(:,3) = (a*(2*yy - 2*y(iStar)))./(2*s^2*exp((xx - x(iStar)).^2/(2*s^2) + (yy - y(iStar)).^2/(2*s^2)));
                J(:,4) = (a*((xx - x(iStar)).^2/s^3 + (yy - y(iStar)).^2/s^3))./exp((xx - x(iStar)).^2/(2*s^2) + (yy - y(iStar)).^2/(2*s^2));
                
                % Update the fit parameters.
                dPar = real((J'*J + L*E)^(-1)*J'*(zz-a*exp(-(xx-x(iStar)).^2/2/s^2-(yy-y(iStar)).^2/2/s^2)));
                %dPar = real((J'*J + L*E)\(J'*(zz-a*exp(-(xx-x(iStar)).^2/2/s^2-(yy-y(iStar)).^2/2/s^2))));

                a = a + dPar(1);
                x(iStar) = x(iStar) + dPar(2);
                y(iStar) = y(iStar) + dPar(3);
                s = s + dPar(4);             
                
                % Obtain the residual.
                postResidual = sum((a*exp(-(xx-x(iStar)).^2/2/s^2-(yy-y(iStar)).^2/2/s^2)-zz).^2);
                
                % Check if the fit got better.
                if(postResidual<preResidual)
                    
                    % Check if it is getting better fast enough.
                    if((preResidual-postResidual)*2/(preResidual+postResidual) < 1E-10)
                        
                        % Make lambda smaller by a factor of 2 to increase convergence.
                        L = L/2;
                        
                    end
                    
                else
                    
                    % Return parameters to their initial state.
                    a = a - dPar(1);
                    x(iStar) = x(iStar) - dPar(2);
                    y(iStar) = y(iStar) - dPar(3);
                    s = s - dPar(4);                   
                    
                    % Make lambda larger by a factor of 2 to decrease convergence.
                    L = L*2;
                    
                    
                end
                
                
                % Check if we have gotten to the tolerance desired.
                if(abs(postResidual/preResidual - 1) < 1E-10)
                    break;
                elseif(postResidual/preResidual > .5)
                    L = L*10;
                elseif(postResidual/preResidual < .95)
                    L = L/10;
                end
                
                % Write the last residual as the new residual.
                preResidual = postResidual;
                
                
                
            end
            
            par(:,iStar) = [a;x(iStar);y(iStar);s];
            
            catch ME
                par(:,iStar) = [a;X0(iStar);Y0(iStar);s];
            
            end
            
        end
        
        
        
        
end





end

