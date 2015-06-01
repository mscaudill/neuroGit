function popEvokedRatesHist(runState, popNames, varargin )
%popEvokedRatesHist constructs a histogram of the evoked firing rates for a
%mulitple populations cells given a running condition and plots each
%population to a histogram
% INPUTS:                       : runState, 0, 1, or 2 to determine
%                                 whether to calculate evoked rate for...
%                                 non-runinng, running, or both...
%                                 respectively
%                               : popNames a cell array of population names
%                                 to construct histogram from
%           varargin            : save, a logical to determine
%                                 whether to open a save dialog box, 
%                                 defaults to true
%                               : plotType, type of plot to display
%                                 (histogram, scatter) defualts to
%                                 histogram
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
defaultPlotType = 'histogram';
% Define the expected plot statistics
expectedTypes = {'histogram', 'scatter'};

% Add all requried and optional args to the input parser object
addRequired(inputParseStruct,'runState',@isnumeric);
addRequired(inputParseStruct, 'popNames', @iscellstr);
addParamValue(inputParseStruct,'save',defaultSave,@islogical);
addParamValue(inputParseStruct,'plotType', defaultPlotType, @(x) ...
                any(validatestring(x,expectedTypes))) ;

% call the parser
parse(inputParseStruct,runState, popNames, varargin{:})
plotType = inputParseStruct.Results.plotType;
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
        %%%%%%%%%% CALL FIRINGRATEMAP FUNC TO CONSTRUCT MAP OBJ %%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % we will now call the function firingRateMap which constructs a
        % map object of firing rates 'keyed' on stimulus angles. Running
        % state is passed to this function to return a map that meets the
        % user definded running state condition ( see inputs above)
        [firingMap, meanSpontaneous] = firingRateMap(runState,...
            'Orientation', subExp.behavior, subExp.spikeIndices,...
            subExp.stimulus, subExp.fileInfo);
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%% CALL FULLMAP FUNCTION TO ENSURE WE HAVE A POPULATED MAP %%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        firingMap = fullMap(subExp.stimulus, 'Orientation', firingMap, 1); 
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%% OBTAIN EVOKED FIRING RATES FROM MAP %%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % For this exp (cell) we will first obtain the firing rates and
        % store them to a a cell array
        FiringRates = firingMap.values;
        % now we compute the evoked firing rate by using cellfun to
        % calculate the max of each array in the cell array (arranged by
        % angles 1 to 12) then subtract the mean and take the max again
        % over all angles
        evokedFiringRates{pop,file} = max(cellfun(@(f) ...
                                        mean(f)-meanSpontaneous,...
                                        FiringRates));
        [~,idx] = max(cellfun(@(f) mean(f)-meanSpontaneous, FiringRates));
        if ~isempty(FiringRates(idx))
            numTrials{pop,file} = numel(FiringRates{idx});
        else numTrials{pop,file} = NaN;
        end
    end
end
assignin('base','NT', numTrials)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%% SQUARE THE EVOKED RATES CELL ARRAY BY MAKING [] = NAN %%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
emptyIndex = cellfun(@isempty,evokedFiringRates);
evokedFiringRates(emptyIndex) = {NaN};    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%% PLOTTING OF EVOKED FIRING DATA  %%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Depending on the user choice for plot type, we will plot either a
% histogram, scatter plot or both
switch plotType
    
    case 'histogram'
        %%%%%%%%%%%%%%%%%%% HISTOGRAM FOR EACH POPULATION %%%%%%%%%%%%%
        
        % rotate cell array becasue hist plots a histogram for each column
        % which in our
        %case will be each population
        hist(cell2mat(evokedFiringRates)',...
            [min(min(cell2mat(evokedFiringRates)')):2:...
            max(max(cell2mat(evokedFiringRates)'))]);
        
        %%%%%%%%%%%%%%%%%%%%%%%% SET AXIS PROPERTIES %%%%%%%%%%%%%%%%%%%%%%
        set(gca, ...
            'Box'         , 'off'     , ...
            'TickDir'     , 'out'     , ...
            'TickLength'  , [.02 .02] , ...
            'XMinorTick'  , 'on'      , ...
            'YMinorTick'  , 'off'      , ...
            'YGrid'       , 'off'     , ...
            'XColor'      , [0 0 0],    ...
            'YColor'      , [0 0 0],    ...
            'LineWidth'   , 1             );
        
        axis tight

        %%%%%%%%%%%%%%%%%%%%%%%%% AXIS LABELS & TITLE %%%%%%%%%%%%%%%%%%%%%
        popTitle = 'Visually evoked rate';
        hTitle  = title (popTitle);
        hXLabel = xlabel('Firing rate (Hz)'            );
        hYLabel = ylabel('counts'                      );
        
        %%%%%%%%%%%%%%%%%%%%%%%% ADD LEGEND %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        legend(popNames);
        
        %%%%%%%%%%%%%%%%%%%%%%%% COLORMAP %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        colormap(summer)
        
        
        %%%%%%%%%%%%%%%%%%%%%%%% SET TITLE AND LABEL FONTS %%%%%%%%%%%%%%%%
        set( gca                            , 'FontName'   , 'Arial' );
        set([hTitle, hXLabel, hYLabel]      , 'FontName'   , 'Arial' );
        set([hXLabel, hYLabel]              , 'FontSize'   , 10          );
        set( hTitle                         , 'FontSize'   , 12       , ...
            'FontWeight' , 'bold'      );
        
        case'scatter'  
        %%%%%%%%%%%%%%% CREATE ERRORBAR PLOT OF HWHM VALUES %%%%%%%%%%%%%%%
        
        % remove the NaNs from each array, call the func removeNaN in
        % MathTools dir
        nonNaNEvoked = cellfun(@(p) removeNaN(p), evokedFiringRates,...
                            'UniformOutput',0);
                        
        % now create a cell array that is numPops x 1 long where each
        % array contains the evoked rates for cells of that population
        popEvokedCell = arrayfun(@(idx) [nonNaNEvoked{idx,:}],...
                                1:size(nonNaNEvoked,1), 'UniformOutput',0)';
                            
       %calculate the mean of each population (returns an array)
        meanEvoked = cellfun(@(p) mean(p), popEvokedCell);
        % and standard deviation of each population (returns an array)
        stdEvoked = cellfun(@(p) std(p), popEvokedCell);
        
        hE = errorbar(1:numPops, meanEvoked, stdEvoked);
        
        
        set(hE                            , ...
            'LineStyle'       , 'none'      , ...
            'Marker'          , '^'         , ...
            'MarkerFaceColor' , [0 0 0]     , ...
            'Color'           , [0 0 0]     );

        %%%%%%%%%%%%%%%%%%%% ADD SCATTERED DATA POINTS TO PLOT %%%%%%%%%%%%
        hold all
        for pop = 1:size(popEvokedCell,1)
            scatter(pop*ones(1,numel(popEvokedCell{pop}))-.5,...
                            popEvokedCell{pop},'k','Marker' ,'^')
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%% SET AXIS PROPERTIES %%%%%%%%%%%%%%%%%%%%%%
        set(gca, ...
            'Box'         , 'off'     , ...
            'TickDir'     , 'out'     , ...
            'TickLength'  , [.02 .02] , ...
            'XTick'       , [1 2]     , ...
            'XMinorTick'  , 'off'      , ...
            'YMinorTick'  , 'off'      , ...
            'YGrid'       , 'off'     , ...
            'XColor'      , [0 0 0],    ...
            'YColor'      , [0 0 0],    ...
            'LineWidth'   , 1             );
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%% AXIS LABELS & TITLE %%%%%%%%%%%%%%%%%%%%%
        popTitle = ['Visually evoked rate:', ' Running State is  '...
            num2str(runState)];
        hTitle  = title (popTitle);
        hXLabel = xlabel(''                                             );
        hYLabel = ylabel('Evoked rate (Hz)'                       );
        
        %%%%%%%%%%%%%%%%%%%%%%%% SET TITLE AND LABEL FONTS %%%%%%%%%%%%%%%%
        set( gca                            , 'FontName'   , 'Arial' );
        set([hTitle, hXLabel, hYLabel]      , 'FontName'   , 'Arial' );
        set([hXLabel, hYLabel]              , 'FontSize'   , 10          );
        set( hTitle                         , 'FontSize'   , 12       , ...
            'FontWeight' , 'bold'      );
        set(gca                             , 'XtickLabel' , popNames);
    end
end