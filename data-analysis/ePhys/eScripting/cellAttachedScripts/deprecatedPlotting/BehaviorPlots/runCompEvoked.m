function runCompEvoked( popName, varargin )
%runCompEvoked compares the evoked firing rate of a population of neurons
%in both the running and non-running conditions
% INPUTS:                      
%                               : popName a string designating the
%                                 population of neurons being compared
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
addRequired(inputParseStruct, 'popName', @ischar);
addParamValue(inputParseStruct,'save',defaultSave,@islogical);
addParamValue(inputParseStruct,'plotType', defaultPlotType, @(x) ...
                any(validatestring(x,expectedTypes))) ;

% call the parser
parse(inputParseStruct, popName, varargin{:})
plotType = inputParseStruct.Results.plotType;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
runState = [0 1];
for state = 1:numel(runState)
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
        [firingMap, meanSpontaneous] = firingRateMap(runState(state),...
            'Orientation', subExp.behavior, subExp.spikeIndices,...
            subExp.stimulus, subExp.fileInfo);
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%% CALL FULLMAP FUNCTION TO ENSURE WE HAVE A POPULATED MAP %%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        firingMap = fullMap(subExp.stimulus, 'Orientation', firingMap, 2); 
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%% OBTAIN EVOKED FIRING RATES FROM MAP %%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % For this exp (cell) we will first obtain the firing rates and
        % store them to a a cell array
        FiringRates = firingMap.values;
        % now we compute the evoked firing rate by using cellfun to
        % calculate mean of each cell (returns NaN if firingMap is empty)
        % and then take the max of the mean vaules (the preferred stimulus)
        evokedFiringRates{state,file} = max(cellfun(@(f) ...
                                            mean(f)-meanSpontaneous,...
                                            FiringRates));
    end
end
assignin('base','evokedFiringRates',evokedFiringRates)
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
        popTitle = [popName, ' visually evoked rate'];
        hTitle  = title (popTitle);
        hXLabel = xlabel('Firing rate (Hz)'            );
        hYLabel = ylabel('counts'                      );
        
        %%%%%%%%%%%%%%%%%%%%%%%% ADD LEGEND %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if numel(evokedFiringRates,2) == 2
            % if there are two cols then we know that there are cells with
            % both running and no-running conditions else we will leave the
            % legend blank
            legend('Non-Running','Running');
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%% COLORMAP %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        colormap('gray')
        
        
        %%%%%%%%%%%%%%%%%%%%%%%% SET TITLE AND LABEL FONTS %%%%%%%%%%%%%%%%
        set( gca                            , 'FontName'   , 'Arial' );
        set([hTitle, hXLabel, hYLabel]      , 'FontName'   , 'Arial' );
        set([hXLabel, hYLabel]              , 'FontSize'   , 10          );
        set( hTitle                         , 'FontSize'   , 12       , ...
            'FontWeight' , 'bold'      );
 %%%%%     
        case'scatter'  
            % For the scatter case we will take the evoked firing rates
            % cell (2xnumRecCells) and convert it to a 1 x recCells count 
            %cell array where each
            % element is a twoel array of [notRun,run] evoked rates using
            % array fun {[notRunEvoked, runEvoked], [], [],...}
            evokedFiring = arrayfun(@(idx) [evokedFiringRates{:,idx}],...
                1:size(evokedFiringRates,2), 'UniformOutput',0);
            %The above cell array may contain NaNs if the evokedRate could
            %not be determined due to lack of trials meeting the criterion
            %number of minTrials so we must remove cols of the cell array
            %where the double array contains an NaN
            colsToRemove = logical(cellfun(@(t) sum(isnan(t)),...
                                    evokedFiring));
            evokedFiring(colsToRemove) = [];
           % now we convert the cell to a matrix where the first col
           % contains firing rates in the non-running condition and the
           % second col contains the firing rates in the running condition
           evokedFiring = cell2mat(evokedFiring');
           for cell = 1:size(evokedFiring,1)
                hP = plot(runState,(evokedFiring(cell,:)));
                set(hP, 'Marker', '^','MarkerFaceColor','auto')
                hold all
           end
           
           % now we compute the mean and standard deviation of the
           % evokedFiring matrix for the non run and run states
           meanEvoked = mean(evokedFiring);
           stdEvoked = std(evokedFiring);
           
           % and plot these to the plot as well
           hE = errorbar(runState+2, meanEvoked, stdEvoked);
           
           %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
           %%%%%%%%%%%%%%%%%%%%%% SET PLOT PROPERTIES %%%%%%%%%%%%%%%%%%%%%
           %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
           
           set(hP, 'Marker', '^')
           xlim([-1 4])
           set(hE                            , ...
            'LineStyle'       , 'none'      , ...
            'Marker'          , '^'         , ...
            'MarkerFaceColor' , [0 0 0]     , ...
            'Color'           , [0 0 0]     );
           
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
        popTitle = [popName ' Visually evoked rate'];
        hTitle  = title (popTitle);
        hXLabel = xlabel(''                                             );
        hYLabel = ylabel('Evoked rate (Hz)'                       );
        
        %%%%%%%%%%%%%%%%%%%%%%%% SET TITLE AND LABEL FONTS %%%%%%%%%%%%%%%%
        set( gca                            , 'FontName'   , 'Arial' );
        set([hTitle, hXLabel, hYLabel]      , 'FontName'   , 'Arial' );
        set([hXLabel, hYLabel]              , 'FontSize'   , 10          );
        set( hTitle                         , 'FontSize'   , 12       , ...
            'FontWeight' , 'bold'      );
        set(gca, 'XtickLabel' , '')
    end
end

