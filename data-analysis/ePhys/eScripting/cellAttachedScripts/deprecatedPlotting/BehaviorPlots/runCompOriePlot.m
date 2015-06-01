function runCompOriePlot(popName, varargin)
%runCompOriePlot constructs from an experiment an orientation tuning plot
%for both the runining and non-running condtion
% The plot also contains running information and the OSI for the cell
% INPUTS    popName             : name of the cell type being examined            
%           varargin            : save, a logical to determine
%                                 whether to open a save dialog box, 
%                                 defaults to true
%                               : normalize, an option to normalize the
%                                 firing rates to the greatest firing rate
%                                 across all angles defaults to false
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
% set default values for the options under varargin (saveOption, normalize)
defaultSave = true;
defaultNormalize = false;

% Add all requried and optional args to the input parser object
addRequired(inputParseStruct,'popName',@ischar);
addParamValue(inputParseStruct,'save',defaultSave,@islogical);
addParamValue(inputParseStruct,'normalize',defaultNormalize,@islogical);

% call the parser
parse(inputParseStruct,popName,varargin{:})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%% LOAD FIELDS FROM EXP TO SUBEXP %%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We call the function dialogLoadExp to load the specific fields from
% the exp structure. This save considerable computation time becasue
% the exp structure can be very large. We need the behavior to evaluate
% running, spikeIndices to get a firing rate, the stimulus to get the
% orientation, and the fileInfo to get sample rate of the data

subExp = dialogLoadExp('behavior', 'spikeIndices', 'stimulus',...
    'fileInfo');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%% LOOP OVER RUNSTATES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
runState = [0,1];
color = {'r', 'g'};
for state = 1:numel(runState)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%% CALL FIRING RATE MAP FUNC TO CONSTRUCT MAP OBJ %%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % we will now call the function firingRateMap which constructs a map
    % object of firing rates 'keyed' on stimulus angles. Running state is
    % passed to this function to return a map that meets the user definded
    % running state condition ( see inputs above)
    [oriMap, meanSpontaneous(state), runningInfo] = ...
        firingRateMap(runState(state), 'Orientation', subExp.behavior,...
        subExp.spikeIndices, subExp.stimulus,...
        subExp.fileInfo);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%% NORMALIZE FIRING RATES IN MAP %%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % if the user has not entered a choice for normalization we will
    % default to the case where we *DO NOT* normalize. So we will just get
    % the values from the orientation map
    FiringRates = oriMap.values
    switch inputParseStruct.Results.normalize
        case false
            % calculate the mean and std of the firing rates across trials
            meanFiringRates = cellfun(@(x) mean(x),FiringRates);
            stdevFiringRates = cellfun(@(y) std(y),FiringRates);
        case true
            % calculate the mean and std of the firing rates as before
            meanFiringRates = cellfun(@(x) mean(x),FiringRates);
            stdevFiringRates = cellfun(@(y) std(y),FiringRates);
            % calculate  max of meanFiringRates and use this to normalize
            % the mean and stdev of the mean arrays
            maxMean = max(meanFiringRates);
            meanFiringRates = meanFiringRates/maxMean;
            stdevFiringRates = stdevFiringRates/maxMean;
    end
    meanRates{state} = meanFiringRates;
    stdevRates{state} = stdevFiringRates;
    angles = cell2mat(oriMap.keys);
    osi(state) = orientationSelectivity(angles, meanFiringRates);
    
    hS{state} = scatter(angles, meanRates{state}, color{state},'filled');
    hold on
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%% CALL FITDATA  TO CONSTRUCT DOUBLE GAUSSIAN FIT %%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    [fitParams{state}, xfit, doubleGaussianFit{state}] =...
                            fitData('doubleGaussian', angles, ...
                            meanRates{state});
                                            
    hfit{state} = plot(xfit, doubleGaussianFit{state},'Color',color{state});
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end
TuningWidths = cellfun(@(t) sqrt(2*log(2))*t(3), fitParams);
meanSpont = mean(meanSpontaneous);
hSpont = plot([0 330], [meanSpont, meanSpont],'Color','k');


%%%%%%%%%%%%%%%%%%%%%%%% SET AXIS PROPERTIES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
set(gca, ...
  'Box'         , 'off'     , ...
  'TickDir'     , 'out'     , ...
  'TickLength'  , [.02 .02] , ...
  'XMinorTick'  , 'off'      , ...
  'YMinorTick'  , 'off'      , ...
  'YGrid'       , 'off'     , ...
  'XColor'      , [0 0 0],    ...
  'YColor'      , [0 0 0],    ...
  'LineWidth'   , 1             );

axis tight

%%%%%%%%%%%%%%%%%%%%%%%%% AXIS LABELS & TITLE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get all the parts of the filename contained in the fileInfo structure of
% the subExp (e.g. 'MSC_2012-08-17_n4orientation_3.daq'
expString = subExp.fileInfo(1,1).dataFileName;
% split this file name on the underscores
allStrings = regexp(expString,'_', 'split');
% the date will be the second element of the cell array
date = allStrings{2};
% the exp type will be the third element
cellNumExpType = allStrings{3};
% construct the title from the date and exp type
expTitle = [date,' ',cellNumExpType,' ','Running Comparison']; 
% set the titles and labels and return handles to each for changing fonts
% etc. later
hTitle  = title (expTitle);
hXLabel = xlabel('Direction (deg)'                     );
hYLabel = ylabel('sp/s (Hz)'                      );

ha = annotation('textbox', [.15, 0.9, .50, 0], 'string',...
                ['Tuning Width Non-Run = ',num2str(TuningWidths(1)),...
                ' Tuning Width Run = ', num2str(TuningWidths(2))]);
            
% remove the default box around the annotation
set(ha, 'LineStyle','none');
end           
            