function popOrientationPlot(runState, popNames, varargin)
% popOrientationPlot creates a normalized poputlation orientation plot for
% each of the popultions given in popNames.  It guides the user to the Exp 
% Location where they can choose a single population at a time. Note the
% tuning curve can be specified to contain median values of firing rates or
% mean values as specified by varargin
% INPUTS                
%           running             : integer to seperate trials based on
%                                 running behavior (1 = yes, 0 = No, 
%                                 2= Keep ALL)
%           varargin            : save, a logical to determine
%                                 whether to open a save dialog box, 
%                                 defaults to true
%                               : plotStatistic, a string determining
%                                 whether the tuning plot should consist of
%                                 median or mean values. If mean values are
%                                 chosen, stds for error bars will appear.
%                                 defaults to mean
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
defaultStatistic = 'mean';
% Define the expected plot statistics
expectedStats = {'mean', 'median'};

% Add all requried and optional args to the input parser object
addRequired(inputParseStruct,'runState',@isnumeric);
addRequired(inputParseStruct, 'popNames', @iscellstr);
addParamValue(inputParseStruct,'save',defaultSave,@islogical);
addParamValue(inputParseStruct,'plotStatistic', defaultStatistic, @(x) ...
                any(validatestring(x,expectedStats))) ;

% call the parser
parse(inputParseStruct,runState, popNames, varargin{:})
plotStatistic = inputParseStruct.Results.plotStatistic;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%% LOOP OVER POPULATIONS AND CALL EXPSELECTOR %%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
numPops = numel(popNames);
for pop = 1:numPops
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%% GET A LIST OF EXPERIMENTS FOR THE POPULATION PLOT %%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % We will now call expSelector to get a cell array of fullfileNames
    % (including paths) to the experiments we wish to include in the plot.
    % This function utilizes uigetfile to obtain filenames
    expFileNames = expSelector;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%% MAIN LOOP OVER EXP FILE NAMES %%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % We will loop over all the expFileNames, load each, construct an
    % orientation tuning curve and repeat storing each to a cell array
    % below
    for file = 1:numel(expFileNames)
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%% LOAD SPECIFIED FIELDS FROM THE EXP %%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % we will need only the specified fields to make our plot
        subExp = loadExp(expFileNames{file}, 'behavior', 'spikeIndices',...
            'stimulus', 'fileInfo');
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%% CALL FIRING RATE MAP FUNC TO CONSTRUCT MAP OBJ %%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % we will now call the function firingRateMap which constructs a
        % map object of firing rates 'keyed' on stimulus angles (since we
        % pass in orientation as the stimulus variable). Running
        % state is passed to this function to return a map that meets the
        % user definded running state condition ( see inputs above)
        [oriMap] = firingRateMap(runState,'Orientation',...
            subExp.behavior, subExp.spikeIndices,...
            subExp.stimulus, subExp.fileInfo);
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%% OBTAIN MEAN FIRING RATES FROM MAP %%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % For this exp (cell) we will first obtain the firing rates and
        % store them to a a cell array
        FiringRates = oriMap.values;
        % now we compute the mean firing rate across trials for this exp
        % and store to a cell in the cell array meanFiringRates
        meanFiringRates{pop,file} = cellfun(@(f) mean(f), FiringRates);
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    end
end

% get the angles from the map
angles = cell2mat(oriMap.keys);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%% SHIFT THE MAXIMUM OF EACH TUNING ARRAY %%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Our mean firing rates cell array contains a row of orientation tuning
% curve arrays for each population we call shift array to shift each of
% them to the 4th index for plotting
shiftedRates = cellfun(@(g) shiftArray(g,'shiftIndex',4),...
                        meanFiringRates, 'UniformOutput',0);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%% NORMALIZE EACH OF THE TUNING CURVES %%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The maximum firing rate of each tuning curve in shiftedRates now appear
% at the same index but they are not normalized. We call cell fun and to
% normalize each cell
normShiftedRates = cellfun(@(t) t./max(t), shiftedRates,...
                           'UniformOutput', 0);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


assignin('base', 'nsfr', normShiftedRates)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%% CALCULATE MEAN OR MEDIAN BASED ON USER CHOICE OR DEFAULT %%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
switch plotStatistic
    case 'mean'
        % if the user has selected to plot the mean firing rate of the
        % population then we errorbar the mean and sem for each population
        for pop=1:numel(popNames)
            
            % Calculate the population mean from the mean firing rates
            % (i.e. each row of normshiftedrates, note we need to transpose
            % since mean is calculated row wise)
            meanTuningCurve{pop}= mean(cell2mat(normShiftedRates(pop,:)'));
            
            % Determine the standard error of the mean (i.e. std/sqrt(n))
            stdErrTuningCurve{pop} = ...
                                std(cell2mat(normShiftedRates(pop,:)'))/...
                                sqrt(numel(meanTuningCurve{pop}));
                            
            % construct and error bar plot over angles and return handle
            hE{pop} = errorbar(angles, meanTuningCurve{pop},...
                               stdErrTuningCurve{pop});
            hold on
            
            % Call fit Data to make a fit to the errorbar data for this
            % population using doubleGaussianFit function
            [fitParams{pop}, xfit, relaxedDoubleGaussianFit{pop}]= ...
                            fitData('relaxedDoubleGaussian',...
                            angles, meanTuningCurve{pop}, 'initGuess',...
                            [1 90 25 .5 270 .6]);
            % construct a plot of the fit and return a handle for each pop
            hfit{pop} = plot(xfit, relaxedDoubleGaussianFit{pop});
        end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%% GET TUNING WIDTH OF EACH POP %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The tuning width is the third element of the fitParams array
% determined by fitData.m above. Use cellfun to create an array of tuning
% widths
popTuningWidths = cellfun(@(t) sqrt(2*log(2))*t(3), fitParams)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%% SET PLOT PROPERTIES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We will set colors for upto 4 populations to be plotted, add more if
% needed
colorScheme = {[0 0 0], [0 204/255 1], [1 0 0], [0 1 0]};

for pop=1:numPops
    %%%%%%%%%%%%%%%%%%%%% SET ERROR BAR LINE PROPERTIES %%%%%%%%%%%%%%%%%%%%%%%
    set(hE{pop}                                 , ...
        'LineStyle'       , 'none'              , ...
        'Color'           , colorScheme{pop}       );
    
    set(hE{pop}                                 , ...
        'LineWidth'       , 1                   , ...
        'Marker'          , 'o'                 , ...
        'MarkerSize'      , 6                   , ...
        'MarkerEdgeColor' , colorScheme{pop}    , ...
        'MarkerFaceColor' , colorScheme{pop}        );
    
    set(hfit{pop}                               , ...
        'Color'         , colorScheme{pop}          );
end

%%%%%%%%%%%%%%%%%%%%%%%% SET AXIS PROPERTIES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% set(gca, ...
%   'Box'         , 'off'     , ...
%   'TickDir'     , 'out'     , ...
%   'TickLength'  , [.02 .02] , ...
%   'XMinorTick'  , 'off'     , ...
%   'YMinorTick'  , 'off'     , ...
%   'YTick'       , []        , ...
%   'YGrid'       , 'off'     , ...
%   'XColor'      , [0 0 0]   , ...
%   'YColor'      , [1 1 1]   , ...
%   'LineWidth'   , 1             );

axis tight

%%%%%%%%%%%%%%%%%%%%%%%%%%%%% ADD LEGEND %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% widthsCell = cellfun(@(t) [' HWHM = ',num2str(t)],...
%                             num2cell(popTuningWidths), 'UniformOutput',0);
% legNames = cellfun(@(t,y) [t,y], popNames, widthsCell,'UniformOutput',0);
hLeg = legend([hE{:}],popNames{:});
set(hLeg, 'Box', 'off')


