function orientationPlot(running, varargin)
% orientationPlot constructs from an experiment an orientation tuning plot.
% The plot also contains running information and the OSI for the cell
% INPUTS                
%           running             : integer to seperate trials based on
%                                 running behavior (1 = yes, 0 = No, 
%                                 2= Keep ALL)
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
addRequired(inputParseStruct,'running',@isnumeric);
addParamValue(inputParseStruct,'save',defaultSave,@islogical);
addParamValue(inputParseStruct,'normalize',defaultNormalize,@islogical);

% call the parser
parse(inputParseStruct,running,varargin{:})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%% LOAD FIELDS FROM EXP TO SUBEXP %%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We call the function dialogLoadExp to load the specific fields from the
% exp structure. This save considerable computation time becasue the exp
% structure can be very large.
% We need the behavior to evaluate running, spikeIndices to get a firing
% rate, the stimulus to get the orientation, and the fileInfo to get sample
% rate of the data

subExp = dialogLoadExp('behavior', 'spikeIndices', 'stimulus', 'fileInfo');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%% CALL FIRING RATE MAP FUNC TO CONSTRUCT MAP OBJ %%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% we will now call the function firingRateMap which constructs a map
% object of firing rates 'keyed' on stimulus angles. Running state is
% passed to this function to return a map that meets the user definded
% running state condition ( see inputs above)
[oriMap, meanSpontaneous, runningInfo] = firingRateMap(running,...
                            'Orientation', subExp.behavior,...
                            subExp.spikeIndices, subExp.stimulus,...
                            subExp.fileInfo);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%% NORMALIZE FIRING RATES IN MAP %%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% if the user has not entered a choice for normalization we will default to
% the case where we *DO NOT* normalize. So we will just get the values from
% the orientation map

FiringRates = oriMap.values;
switch inputParseStruct.Results.normalize
    case false
        % calculate the mean and std of the firing rates across trials
        meanFiringRates = cellfun(@(x) mean(x),FiringRates);
        stdevFiringRates = cellfun(@(y) std(y),FiringRates);
    case true
         % calculate the mean and std of the firing rates as before
        meanFiringRates = cellfun(@(x) mean(x),FiringRates);
        stdevFiringRates = cellfun(@(y) std(y),FiringRates);
        % calculate the max of meanFiringRates and use this to normalize
        % the mean and stdev of the mean arrays
        maxMean = max(meanFiringRates);
        meanFiringRates = meanFiringRates/maxMean;
        stdevFiringRates = stdevFiringRates/maxMean;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% CALCULATE OSI %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% we now call the function orientationSelectivity.m and determine the osi
% for this neuron

% Get the angles from oriMap (note oriMap. keys returns a cell doubles so
% we convert to a cell
angles = cell2mat(oriMap.keys);

osi = orientationSelectivity(angles, (meanFiringRates-meanSpontaneous));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%% PLOT ORIENTATION TUNING CURVE %%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
subplot(1,2,1)
% Plot the mean and error and return a handle to the plot
hE = errorbar(angles, meanFiringRates, stdevFiringRates);

% Also plot the meanSpontaneous
hold on

% here we have two cases to deal with. If the user has chosen to normalize
% then we need to normalize the spontaneous rate as well otherwise we
% simply plot the meanSpontaneous
if inputParseStruct.Results.normalize == true
    hSpont = plot([0 330], [meanSpontaneous, meanSpontaneous]/maxMean);
else
    hSpont = plot([0 330], [meanSpontaneous, meanSpontaneous]);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%% CALL FITDATA  TO CONSTRUCT DOUBLE GAUSSIAN FIT %%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[~, xfit, doubleGaussianFit] = fitData('doubleGaussian', angles,...
                                                meanFiringRates);
                                            
hfit = plot(xfit, doubleGaussianFit);

%%%%%%%%%%%%%%%%%%%%% SET ERROR BAR LINE PROPERTIES %%%%%%%%%%%%%%%%%%%%%%%
set(hE                            , ...
  'LineStyle'       , 'none'        , ...
  'Color'           , [0 0 0]        );

set(hE                            , ...
  'LineWidth'       , 1           , ...
  'Marker'          , 'o'         , ...
  'MarkerSize'      , 6           , ...
  'MarkerEdgeColor' , [.2 .2 .2]  , ...
  'MarkerFaceColor' , [.7 .7 .7]     );

set(hSpont                        , ...
    'Color'         , [1 0 0]        );

set(hfit                          , ...
    'Color'         , [0 0 0]        );

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
expTitle = [date,' ',cellNumExpType,' ','Running State is  ',...
            num2str(running)]; 
% set the titles and labels and return handles to each for changing fonts
% etc. later
hTitle  = title (expTitle);
hXLabel = xlabel('Direction (deg)'                     );
hYLabel = ylabel('sp/s (Hz)'                      );

%%%%%%%%%%%%%%%%%%%%%%%% ANNOTATION ABOUT RUNNING INFO %%%%%%%%%%%%%%%%%%%%
% create an annotation box that describes the percentage of trials the
% animal ran for.
if running == 0 || running == 1
    ha = annotation('textbox', [.15, 0.9, .50, 0], 'string',...
                ['animal ran ',...
                num2str(runningInfo.percentRunning),'% of the ',...
                num2str(runningInfo.numTriggers),' triggers' char(10)...
                'OSI = ',num2str(osi)]);
else 
    ha = annotation('textbox', [.15, 0.9, .50, 0], 'string',...
                ['Running State Ignored' char(10) 'OSI = ',num2str(osi)]);
end

% remove the default box around the annotation
set(ha, 'LineStyle','none');

%%%%%%%%%%%%%%%%%%%%%%%% SET TITLE AND LABEL FONTS %%%%%%%%%%%%%%%%%%%%%%%%        
set( gca                            , 'FontName'   , 'Helvetica' );
set([hTitle, hXLabel, hYLabel]      , 'FontName'   , 'Helvetica' );
set([hXLabel, hYLabel]              , 'FontSize'   , 10          );
set( hTitle                         , 'FontSize'   , 12       , ...
                                      'FontWeight' , 'bold'      );
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%% AUTOSAVE FIGURE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% if the user decides to save a figure from the command line call of this
% function then we will construct a default figure name and start the in a
% save directory specified in ExpDirInformation.m
if inputParseStruct.Results.save
    ExpDirInformation
    %From the dirInfo structure in this file we will set the base load
    %location for saving the file. That is, uiputfile will start at this 
    %directory for saving
    RoughFigLoc = dirInfo.RoughFigLoc;
    % construct a default name for the figure
    defaultFigName = [RoughFigLoc,date,'_', cellNumExpType,'_state_',...
                    num2str(running)];


%%%%%%%%%%%%%%%% CONSTRUCT PATH AND FILE NAME %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    [fileName,pathName] = uiputfile(RoughFigLoc,'Save As',defaultFigName);

    file = fullfile(pathName,fileName);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% SAVE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if ischar(fileName) && ischar(pathName) 
        saveas(gcf,file,'fig')
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
subplot(1,2,2)
polarTuningPlot(angles,meanFiringRates)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%% PLACE THE MAP IN THE BASE WORKSPACE SO USER CAN SEE IT %%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
assignin('base','orientationMap', oriMap)
assignin('base','meanFiringRates', meanFiringRates)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
set(gcf,'position',[340 558 1120 420])
end

