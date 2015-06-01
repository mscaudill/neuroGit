function [ fitParams, xFit, dataFit] = sineFit( xpts, ypts, frequency,...
                                                varargin )
% sineFit takes a set of data points and fits a sine function of the form
% constant + amplitude*sin(frequency*xpts). It uses nlinear regression
% fitting provided in matlabs curve fitting toolbox.
% INPUTS: 
%                       : xpts, a n-element sequence of x-vals over which
%                         ypts were measured
%                       : ypts, an n-element sequence of data to be fitted
%                       : Frequency of grating and expected frequency
%                         response of membrane V
%       VARGIN
%                       : initGuess, an array of initial values [constant,
%                         Amplitude, phase]. If blank sineFit will
%                         autodetermine initial guess
%                       : numPoints, number of points to be used to fit
%                         with (defaults to 1000)
% OUTPUTS:          
%
%                       : dataFit, array (numel defaults to 1000) of fitted
%                         data points
%                       : params, array of final fit params
%                        (Const,Amp,phase)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
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

%%%%%%%%%%%%%%%%%%%%% CHECK INCOMING YPTS EXIST %%%%%%%%%%%%%%%%%%%%%%%%%%%
% Check that there are incoming dataPts to fit otherwise we return NaN for
% all output args. This will allow us to call this function on arrays of
% dataPts some of which may be empty.
if isempty(ypts)
    fitParams = NaN;
    xFit = NaN;
    dataFit = NaN;
    % and return control to invoking function
    return
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%% PARSE INPUTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Call the inputParser constructor
inputParseStruct = inputParser;

%%%%%%%%%%%%%%%%%%%%%% Construct an initial guess %%%%%%%%%%%%%%%%%%%%%%%%%
% We will now construct an array of initial guesses for the constant dc
% offset, the amplitude and the frequency of the sine function that we will
% attempt to fit to the incoming ypts

% the constant initial guess will be the mean of the entire ypt sequence
constant = mean(ypts);

% the amplitude guess will be the max(ypts)-mean(ypts). Note this might be
% a bad guess if spikes are not removed from data first because this
% difference may be too large
amplitude = max(ypts)-constant;

% The phase will be assumed to be near 90degs (maximum) at onset response
phase = 90*pi/180;

defaultInitGuess = [constant, amplitude, phase];

% set the number of defaultPoints to fit with
defaultNumFitPoints = 1000;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%% Parse required inputs %%%%%%%%%%%%%%%%%%%%%%%%%%%
addRequired(inputParseStruct,'xpts',@isvector);
addRequired(inputParseStruct,'ypts',@isvector);
addRequired(inputParseStruct, 'phase',@isscalar);
%%%%%%%%%%%%%%%%%%%%%%% Parse variable arg inputs %%%%%%%%%%%%%%%%%%%%%%%%%
addParamValue(inputParseStruct,'initGuess',defaultInitGuess,@isvector);
addParamValue(inputParseStruct,'numFitPoints',defaultNumFitPoints,...
              @isscalar);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% call the parser
parse(inputParseStruct, xpts, ypts, phase, varargin{:})

% and retrieve variable arguments fron the parse structure
initGuess = inputParseStruct.Results.initGuess;
numFitPoints = inputParseStruct.Results.numFitPoints;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%% CREATE A DATAFIT TO YPTS %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%% CREATE A SINE FUNCTION HANDLE %%%%%%%%%%%%%%%%%%%%%%%
hSine = @(initGuess, x) initGuess(1) + ...
                        initGuess(2)*sin(frequency*2*pi*xpts+initGuess(3));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%% CALL NLINFIT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fitParams = nlinfit(xpts,ypts,hSine, initGuess);

%%%%%%%%%%%%%%%%% CREATE THE FIT FROM RETURNED FITPARAMS %%%%%%%%%%%%%%%%%%
xFit = linspace(xpts(1),xpts(end),numFitPoints);
dataFit = hSine(fitParams, xFit);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

end

