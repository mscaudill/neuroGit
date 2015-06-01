function popDsiPlot(runState, popNames, plotType)
%popDsiPlot returns a histogram or scatter plot of direction selectivity
%indexes for each population. It guides the user to the Exp Location where
%they can choose a single population at a time. popDsi will then make a
%histogram for each population and return them in a figure
% INPUTS                        : running state, 0, 1, or 2 to determine
%                                 whether to calculate OSI for...
%                                 non-runinng, running, or both...
%                                 respectively
%                               : popNames, cell array of pop names
%                                 will go into the histogram./scatter plot,
%                                 the function
%                                 will use uigetfile to load each pop
%                                 separately
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
%%%%%%%%%%%%%%%%%%%%%%%% SET DEFAULT PLOT TYPE %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin < 3;
    plotType = 'histogram';
end

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
        %%%%%%%%%% CALL ORIENTATION MAP FUNC TO CONSTRUCT MAP OBJ %%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % we will now call the function orientationMap which constructs a
        % map object of firing rates 'keyed' on stimulus angles since we
        % have chosen orientatation as the stimulus parameter. Running
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%% OBTAIN MAP ANGLES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
angles = cell2mat(oriMap.keys);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%% CALL DSI FUNCTION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% use cell fun to calculate dsi for each cell in meanFiringRates cell array
% and return back a num populations X numExps array. If the num of
% exps/cells in each population are different then the matrix will contain
% NaNs assigned by orientationSelectivity
popDsi = cellfun(@(arr) directionSelectivity(angles,arr), meanFiringRates);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
assignin('base', 'popDsi', popDsi)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%% PLOTTING OF DSI DATA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Depending on the user choice for plot type, we will plot either a
% histogram, scatter plot or both
switch plotType
    
    case 'histogram'
        %%%%%%%%%%%%%%%%%%% HISTOGRAM OSI FOR EACH POPULATION %%%%%%%%%%%%%
        
        % rotate popDsi becasue hist plots a histogram for each column
        % which in our
        %case will be each population
        bins=0:.1:1;
        hist(popDsi',bins)
        
        %%%%%%%%%%%%%%%%%%%%%%%% SET AXIS PROPERTIES %%%%%%%%%%%%%%%%%%%%%%
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
        
        %%%%%%%%%%%%%%%%%%%%%%%%% AXIS LABELS & TITLE %%%%%%%%%%%%%%%%%%%%%
        popTitle = ['Direction Selectivity:', ' Running State is  '...
            num2str(runState)                                         ];
        hTitle  = title (popTitle                                     );
        hXLabel = xlabel('(R_{pref}-R_{null})/(R_{pref}+R_{null})'  );
        hYLabel = ylabel('counts'                                     );
        
        %%%%%%%%%%%%%%%%%%%%%%%% ADD LEGEND %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        legend(popNames);
        
        %%%%%%%%%%%%%%%%%%%%%%%% COLORMAP %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        colormap(summer)
        
        
        %%%%%%%%%%%%%%%%%%%%%%%% SET TITLE AND LABEL FONTS %%%%%%%%%%%%%%%%
        set( gca                            , 'FontName'   , 'Helvetica' );
        set([hTitle, hXLabel, hYLabel]      , 'FontName'   , 'Helvetica' );
        set([hXLabel, hYLabel]              , 'FontSize'   , 10          );
        set( hTitle                         , 'FontSize'   , 12       , ...
            'FontWeight' , 'bold'      );
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        case'scatter'
        %%%%%%%%%%%%%%%%%%%% CREATE ERRORBAR PLOT OF OSI VALUES %%%%%%%%%%%
        
        % convert popDsi matrix in a cell array with an array for each
        % population
        popDsiCell = mat2cell(popDsi,[1 1], [size(popDsi,2)]);
        
        % remove the NaNs from each array, call the func removeNaN in
        % MathTools dir
        popDsiCell = cellfun(@(p) removeNaN(p), popDsiCell,...
                            'UniformOutput',0);
        
        %calculate the mean of each population (returns an array)
        meanPopDsi = cellfun(@(p) mean(p), popDsiCell);
        % and standard deviation of each population (returns an array)
        stdPopDsi = cellfun(@(p) std(p), popDsiCell);
        
        hE = errorbar(1:numPops, meanPopDsi, stdPopDsi);
        
        
        set(hE                            , ...
            'LineStyle'       , 'none'      , ...
            'Marker'          , '^'         , ...
            'MarkerFaceColor' , [0 0 0]     , ...
            'Color'           , [0 0 0]     );
        
        %%%%%%%%%%%%%%%%%%%% ADD SCATTERED DATA POINTS TO PLOT %%%%%%%%%%%%
        hold all
        for pop = 1:size(popDsiCell,1)
            scatter(pop*ones(1,numel(popDsiCell{pop}))-.5,...
                            popDsiCell{pop},'k','Marker' ,'^')
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
        popTitle = ['Direction Selectivity:', ' Running State is  '...
            num2str(runState)];
        hTitle  = title (popTitle);
        hXLabel = xlabel(''                                             );
        hYLabel = ylabel('dsi'                       );
        
        %%%%%%%%%%%%%%%%%%%%%%%% SET TITLE AND LABEL FONTS %%%%%%%%%%%%%%%%
        set( gca                            , 'FontName'   , 'Helvetica' );
        set([hTitle, hXLabel, hYLabel]      , 'FontName'   , 'Helvetica' );
        set([hXLabel, hYLabel]              , 'FontSize'   , 10          );
        set( hTitle                         , 'FontSize'   , 12       , ...
            'FontWeight' , 'bold'      );
        set(gca                             , 'XtickLabel' , popNames);
end
end

