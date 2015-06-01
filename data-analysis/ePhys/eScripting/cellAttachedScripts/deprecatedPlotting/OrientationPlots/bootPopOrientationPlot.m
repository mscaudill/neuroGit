function bootPopOrientationPlot(running, varargin)
% popOrientationPlot creates a population orientation plot from a list of 
% experiments. It plots the median of the mean firing rates across cells
% for each angle and uses computes and places bootstrapped errror bars
% based on a 95% confidence interval
% INPUTS                
%           running             : integer to seperate trials based on
%                                 running behavior (1 = yes, 0 = No, 
%                                 2= Keep ALL)
%           varargin            : save, a logical to determine
%                                 whether to open a save dialog box, 
%                                 defaults to true
%                               : bootstrapSamples, number of times to
%                                 resample data for constructing median
%                                 error bars. defaults to 300
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%% PARSE INPUTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
inputParseStruct = inputParser;
% set default values for the options under varargin (saveOption)
defaultSave = true;
defaultBootstrapSamples = 300;

% Add all requried and optional args to the input parser object
addRequired(inputParseStruct,'running',@isnumeric);
addParamValue(inputParseStruct,'save',defaultSave,@islogical);
addParamValue(inputParseStruct,'bootstrapSamples',...
              defaultBootstrapSamples,@isnumeric);

% call the parser
parse(inputParseStruct,running,varargin{:})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%% GET A LIST OF EXPERIMENTS FOR THE POPULATION PLOT %%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We will now call expSelector to get a cell array of fullfileNames
% (including paths) to the experiments we wish to include in the plot. This
% function utilizes uigetfile to obtain filenames
expFileNames = expSelector;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%% MAIN LOOP OVER EXP FILE NAMES %%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We will loop over all the expFileNames, load each, construct an
% orientation tuning curve and repeat storing each to a cell array below
for file = 1:numel(expFileNames)
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%% LOAD SPECIFIED FIELDS FROM THE EXP %%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % we will need only the specified fields to make our plot
    subExp = loadExp(expFileNames{file}, 'behavior', 'spikeIndices',...
                                         'stimulus', 'fileInfo');
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%% CALL FIRING RATE MAP FUNC TO CONSTRUCT MAP OBJ %%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % we will now call the function orientationMap which constructs a map
    % object of firing rates 'keyed' on stimulus angles. Running state is
    % passed to this function to return a map that meets the user definded
    % running state condition ( see inputs above)
    [oriMap] = firingRateMap(running,'Orientation',...
        subExp.behavior, subExp.spikeIndices,...
        subExp.stimulus, subExp.fileInfo);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%% OBTAIN MEAN FIRING RATES FROM MAP %%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % For this exp (cell) we will first obtain the firing rates and store
    % them to a a cell array
    FiringRates = oriMap.values;
    % now we compute the mean firing rate across trials for this exp and
    % store to a cell in the cell array meanFiringRates
    meanFiringRates{file} = cellfun(@(f) mean(f), FiringRates);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%% SHIFT THE MAXIMUM OF EACH TUNING ARRAY %%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Our mean firing rates cell array contains the orientation tunning
% curve for each cell/Exp. We now need to shift the maximum of the tuning
% curves to the same angle. We call the function shiftArray (found in
% MathTools) to accomplish this
shiftedRates = cellfun(@(g) shiftArray(g,'shiftIndex',4),...
                        meanFiringRates, 'UniformOutput',0);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%% CALC POPULATION MEDIANS FOR EACH ANGLE %%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Now that we have the mean firing rate for each angle for each cell we can
% calculate the median firing rate for each angle *across cells* we use the
% median statistic because it reduces the impact of outliers 
% First convert our meanFiring rates cell into a matrix with exps/cells as
% rows and angles as columns (note we must rotate mean firing rates to get
% the right dimensions
meanRateMatrix = cell2mat(shiftedRates');
% now calculate the median of this matrix (note median treats columns of
% matrix as vectors which is what we have in meanRateMatrix
medianFiringRate = median(meanRateMatrix);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%% BOOTSTRAP MEAN FIRING RATES TO OBTAIN MEDIAN DISTRIBUTION %%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% we have the mean firing rates across cells and angles stored in the mean
% rateMatrix and we have calculated the medians of the mean firing rates
% but  there is a problem. How do I get the error of the median firing
% rate? Our median firing rate is simply a 1 x 12 vector containing the
% median firing rates across all cells. How do we get an error for these
% medians to plot? We will accomplish this by bootstrapping the data. This
% technique will reshuffle the data at a given angle and recompute the
% median again (note there can also be replacement as well as reshuffle).
% This will give me a set of medians that I can then perform statistics on

% we call the function bootstrp to perform the operation using median as
% the function to apply. We perform 1000 resamples
[bootstat,~] = bootstrp(inputParseStruct.Results.bootstrapSamples,...
                        @median, meanRateMatrix);
% bootstat will be a matrix that is bootstrapSamples x numAngles in size
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%% APPLY 95% CONFIDENCE INTERVAL %%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
sErrorMedian = std(bootstat)/...
                sqrt(inputParseStruct.Results.bootstrapSamples);
% using the cumulative noral distribution z-score we find a 95% confidence
% gives a critical value of 1.96
criticalValue = 1.96;
intervalBound = criticalValue*sErrorMedian;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%% PLOT ORIENTATION TUNING CURVE %%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get the angles from oriMap (note oriMap. keys returns a cell doubles so
% we convert to a cell
angles = cell2mat(oriMap.keys);

% Plot the mean and error and return a handle to the plot
hE = errorbar(angles, medianFiringRate, intervalBound);

%%%%%%%%%%%%%%%%%%%%% SET ERROR BAR LINE PROPERTIES %%%%%%%%%%%%%%%%%%%%%%%
set(hE                            , ...
  'LineStyle'       , '--'        , ...
  'Color'           , [0 0 0]        );

set(hE                            , ...
  'LineWidth'       , 1           , ...
  'Marker'          , 'o'         , ...
  'MarkerSize'      , 6           , ...
  'MarkerEdgeColor' , [.2 .2 .2]  , ...
  'MarkerFaceColor' , [.7 .7 .7]     );

%%%%%%%%%%%%%%%%%%%%%%%% SET AXIS PROPERTIES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
set(gca, ...
  'Box'         , 'off'     , ...
  'TickDir'     , 'out'     , ...
  'TickLength'  , [.02 .02] , ...
  'XMinorTick'  , 'on'      , ...
  'YMinorTick'  , 'on'      , ...
  'YGrid'       , 'off'     , ...
  'XColor'      , [0 0 0],    ...
  'YColor'      , [0 0 0],    ...
  'LineWidth'   , 1             );

axis tight

%%%%%%%%%%%%%%%%%%%%%%%%% AXIS LABELS & TITLE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
popTitle = ['Population Medians:', ' Running State is  ' num2str(running)];
hTitle  = title (popTitle);
hXLabel = xlabel('Direction (deg)'                     );
hYLabel = ylabel('sp/s (Hz)'                      );

%%%%%%%%%%%%%%%%%%%%%%%% SET TITLE AND LABEL FONTS %%%%%%%%%%%%%%%%%%%%%%%%        
set( gca                            , 'FontName'   , 'Helvetica' );
set([hTitle, hXLabel, hYLabel]      , 'FontName'   , 'Helvetica' );
set([hXLabel, hYLabel]              , 'FontSize'   , 10          );
set( hTitle                         , 'FontSize'   , 12       , ...
                                      'FontWeight' , 'bold'      );
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%