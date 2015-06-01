function [fitParams, xFit, dataFit] = fitData(fitFunction, xpts, ypts,...
                                              varargin)
%fitData fits a set of data points given in array with a function specified
%by fitFunction. It uses either polyfit or nlinfir regression fitting from
%matlabs curve fitting toolbox.
% INPUTS:
%                               : fitFunction a function from the list
%                                 (gaussian, doubleGaussian,
%                                   relaxedDoubleGaussian, 
%                                   differnceOfGaussians)
%                               : xpts n-element sequence of x vals over
%                                 which ypts was measured
%                               : ypts, n-element sequence of data points
%                               to be fitted
%               VARARGIN 
%                               : initGuess, an array of init values,
%                                 length of array depends on fitFunction
%                                 selected
%                               : numPoints for fit data i.e. the number of 
%                                 points to plot for fit (defaults to 1000)
% OUTPUTS:
%                               : dataFit, array (numel defaults to 1000)
%                                 of fitted data points
%                               : params, array of final fit parameters
%                               (length depends on fitFunction chosen)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%copyright (c) 2012  Matthew Caudill
%
%this program is free software: you can redistribute it and/or modify
%it under the terms of the gnu general public license as published by
%the free software foundation, either version 3 of the license, or
%at your option) any later version.
%
%this program is distributed in the hope that it will be useful,
%but without any warranty; without even the implied warranty of
%merchantability or fitness for a particular purpose.  see the
%gnu general public license for more details.
%
%you should have received a copy of the gnu general public license
%along with this program.  if not, see <http://www.gnu.org/licenses/>.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Check that we have data points to fit, otherwise we return an NaN for all
% output args
if ~isempty(ypts)
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%% PARSE INPUTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    inputParseStruct = inputParser;
    
    % set the default options for the varargin
    if strcmp(fitFunction, 'gaussian')
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%% FIND PEAKS IN DATA %%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Fitting a function to data requires an initial guess of the
        % fitting parameters. Depending on the fit type this inital guess
        % may determine how well the fit we make converges to the actual
        % data points. So we need to be smart about the initial guess we
        % make. For a single gaussian fit we will help the nonlinear
        % fitting algorithm (matlab built-in) by selecting an initial guess
        % of fit parameters. We need to find the peak amplitude, peak
        % location and tuning width
        % use findpeaks (matlab builtin) to locate the peaks and peak
        % indices and sort them
        [pks, indices] = findpeaks(ypts, 'SORTSTR', 'descend');
        % Handle the case where multiple peaks are located
       
        % Take only the largest one since we are using a Gauss fit
        pk = pks(1);
        % find the xpts corresponding to the peak indices
        xloc = xpts(indices(1));
        
        % We set the initial width to be 50 ( the HWHM is sqrt(2ln(2))
        % times this value) This is a pretty reasonable angluar width
        sigma = 50;
        
        % baseline will be set to 0. This is the DC shift
        baseline = 3;
        
        defaultInitGuess = [pk sigma baseline];
    end
        
    % set default values for the options under varargin
    if strcmp(fitFunction, 'doubleGaussian')
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%% FIND PEAKS IN DATA %%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Fitting a function to data requires an initial guess of the
        % fitting parameters. Depending on the fit type this inital guess
        % may determine how well the fit we make converges to the actual
        % data points. So we need to be smart about the initial guess we
        % make. For a double Gaussian fit we will help the nonlinear
        % fitting algorithm by giving it good initial values for the peaks,
        % the peak locations and the tuning width (sqrt variance)
        
        % use findpeaks (matlab builtin) to locate the peaks and peak
        % indices and sort them
        [pks, indices] = findpeaks(ypts, 'SORTSTR', 'descend');
        
        % Take only the largest two since we are using double Gauss fit
        pks = pks(1:2);
        % find the xpts corresponding to the peak indices
        xloc = xpts(indices(1:2));
        
        % place pks and xloc into a matrix (1st col = sorted xlocs and 2nd
        % col is peak amp at that loc) and sort them by location
        peakMatrix = sort([xloc', pks'], 1);
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%% CONTRUCT INITIAL GUESS TO BE PASSED TO NLINFIT %%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % for a double gaussin the free parameters are amplitudes of each
        % peak, the width (assigned to be equal for each peak), amplitude
        % one location
        amplitudeOne = peakMatrix(1,2);
        amplitudeTwo = peakMatrix(2,2);
        % We set the initial width to be 50 ( the HWHM is sqrt(2ln(2))
        % times this value) This is a pretty reasonable angluar width
        sigma = 30;
        ampOneLoc = peakMatrix(1,1);
        meanFiring = 5;
        defaultInitGuess = [amplitudeOne ampOneLoc sigma amplitudeTwo...
                            meanFiring];
    end
    %######################################################################
    % set default values for the options under varargin
    if strcmp(fitFunction, 'relaxedDoubleGaussian')
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%% FIND PEAKS IN DATA %%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % The reslaxed Double Gaussian fit frees the second amplitude loc
        
        % use findpeaks (matlab builtin) to locate the peaks and peak
        % indices and sort them
        [pks, indices] = findpeaks(ypts, 'SORTSTR', 'descend');
        
        % Take only the largest two since we are using double Gauss fit
        pks = pks(1:2);
        % find the xpts corresponding to the peak indices
        xloc = xpts(indices(1:2));
        
        % place pks and xloc into a matrix (1st col = sorted xlocs and 2nd
        % col is peak amp at that loc) and sort them by location
        peakMatrix = sort([xloc', pks'], 1);
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%% CONTRUCT INITIAL GUESS TO BE PASSED TO NLINFIT %%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % for a double gaussin the free parameters are amplitudes of each
        % peak, the width (assigned to be equal for each peak), amplitude
        % one location
        amplitudeOne = peakMatrix(1,2);
        amplitudeTwo = peakMatrix(2,2);
        % We set the initial width to be 50 ( the HWHM is sqrt(2ln(2))
        % times this value) This is a pretty reasonable angluar width
        sigma1 = 28;
        
        
        ampOneLoc = peakMatrix(1,1);
        ampTwoLoc = peakMatrix(2,1);
        meanFiring = 5;
        defaultInitGuess = [amplitudeOne, ampOneLoc, sigma1,...
                            amplitudeTwo, ampTwoLoc, meanFiring];
    end
    
    %######################################################################
    if strcmp(fitFunction, 'differenceOfGaussians')
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%% FIND MAX IN DATA %%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % use findpeaks (matlab builtin) to locate the peaks and peak
        % indices and sort them
        [pks, indices] = findpeaks(ypts, 'SORTSTR', 'descend');
        % find the x location of the maximum
        xLoc = xpts(indices(1));
    
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%% CONTRUCT INITIAL GUESS TO BE PASSED TO NLINFIT %%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % For a difference of gaussian fit we have 5 free parameters: the
        % excitatory amplitude of first gauss, the inhibitory amplitude of
        % 2nd gauss, the width of the first gauss and the width of the
        % second gauss and the baseline firing rate (dc shift).
        
        % The amplitudes of the two gaussians at the center should sum to
        % the height of the fitted data
        excAmp = pks/2;
        inhAmp = pks/2;

        % The exc_variance is will be initialized to be 50 becasue this
        % number is close to double the rf sizes expected in v1
        excVar = 50;
        % The inhibitor variance will be initialized to 50 as well
        inhVar = 50;
        % the dc shift in firing will be 5 hz
        meanFiring = 5;
        % Construct default guess
        defaultInitGuess = [excAmp, inhAmp, excVar, inhVar, meanFiring];
    end
    
    defaultNumFitPoints = 1000;
    
    % Add all requried and optional args to the input parser object
    addRequired(inputParseStruct,'fitFunction',@ischar);
    addRequired(inputParseStruct,'xpts',@isvector);
    addRequired(inputParseStruct,'ypts',@isvector);
    addParamValue(inputParseStruct,'initGuess',defaultInitGuess,@isvector);
    addParamValue(inputParseStruct,'numFitPoints',defaultNumFitPoints,...
        @isscalar);
    
    % call the parser
    parse(inputParseStruct, fitFunction, xpts, ypts, varargin{:})
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    initGuess = inputParseStruct.Results.initGuess;
    numFitPoints = inputParseStruct.Results.numFitPoints;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%% SWITCH FIT FUNCTION %%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    switch fitFunction
        case 'gaussian'
            % create a function handle to gaussian
            hGaussian = @(initGuess, x) initGuess(1)* ...
                exp(-(x-135).^2/(2*initGuess(2)^2))+initGuess(3);
            
            % Call nlinfit and the function with the input arrays and
            % initial guess and return back the parameters of the fit
            fitParams = nlinfit(xpts, ypts, hGaussian, initGuess);
            
            % create the fit from the fit params
            xFit = linspace(xpts(1),xpts(end),numFitPoints);
            dataFit = hGaussian(fitParams, xFit);
            
        case 'doubleGaussian'
            % create a function handle to  doubleGaussian
            hDoubleGaussian = @(initGuess, x) initGuess(1)*...
                exp(-(x-initGuess(2)).^2/...
                (2*initGuess(3)^2)) + initGuess(4)*...
                exp(-(x-mod(initGuess(2)+180,360)).^2/...
                (2*initGuess(3)^2)) + initGuess(5);
            % Call nlinfit and the function with the input arrays and
            % initial guess and return back the parameters of the fit
            fitParams = nlinfit(xpts, ypts, hDoubleGaussian, initGuess);
            
            % create the fit from the fit params
            xFit = linspace(xpts(1),xpts(end),numFitPoints);
            dataFit = hDoubleGaussian(fitParams, xFit);
            
            
        case 'relaxedDoubleGaussian'
            % create a function handle to  doubleGaussian
            hrelaxedDoubleGaussian = @(initGuess, x) initGuess(1)*...
                exp(-(x-initGuess(2)).^2/...
                (2*initGuess(3)^2)) + initGuess(4)*...
                exp(-(x-initGuess(5)).^2/...
                (2*initGuess(3)^2)) + initGuess(6);
            % Call nlinfit and the function with the input arrays and
            % initial guess and return back the parameters of the fit
            fitParams = nlinfit(xpts, ypts, hrelaxedDoubleGaussian,...
                                initGuess);
            
            % create the fit from the fit params
            xFit = linspace(xpts(1),xpts(end),numFitPoints);
            dataFit = hrelaxedDoubleGaussian(fitParams, xFit);
            %assignin('base', 'fp', fitParams)
            
        case 'differenceOfGaussians'
            % creat function handle
            hDiffOfGauss = @(p,x) p(1)*p(3)*sqrt(pi)/2*erf(x/p(3))-...
                                  p(2)*p(4)*sqrt(pi)/2*erf(x/p(4))+p(5);
                        
            % Call nlinfit and the function with the input arrays and
            % initial guess and return back the parameters of the fit
            fitParams = nlinfit(xpts, ypts, hDiffOfGauss, initGuess);
            
            %assignin('base', 'fp', fitParams)
            
            % create the fit from the fit params
            xFit = linspace(xpts(1),xpts(end),numFitPoints);
            dataFit = hDiffOfGauss(fitParams, xFit);
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%% PERFORM BASIC FIT PARAM CHECK %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% switch fitFunction
%     case 'doubleGaussian'
%         if fitParams(1) < 0 || fitParams(2) < 0 || abs(fitParams(3))...
%                 >120 || fitParams(4) < -2 
%             warning(['The quality of the fit to some data is suspect:'... 
%                 char(10), 'Setting fit parameters for this data to NaN']);
%         fitParams = NaN;
%         end
% end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

else 
    % if there is no data to fit return an NaN for all outputs
    fitParams = NaN;
    xFit = NaN;
    dataFit = NaN;
    
end

