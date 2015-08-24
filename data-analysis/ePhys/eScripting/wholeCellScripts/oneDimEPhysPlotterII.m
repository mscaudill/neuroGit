function oneDimEPhysPlotterII(varargin)
% oneDimEPhysPlotterII plots single parameter data present in the dataMap
% of an Exp. This function will direct the user to load the experiment.
% INPUTS:           VARARGIN: 
%                          removeSpikes:   0 or 1 logical
%                          runState:       a numeric 0, 1 or 2. Zero is
%                                          non-running trials, 1 is running
%                                          trials and 2 is all trials to be
%                                          plotted
%                          ledTpPlot:      a numeric 0, 1 or 2. Zero means
%                                          plot only control trials. One
%                                          means plot only Led trials. Two
%                                          means plot both types (default)
%                           dataOffSet:    offset in mV (applied to Ic
%                                          data) in case of offset error
%                                          during collection
%                           horzSpace:     the horizontal spacing between
%                                          the plots in seconds (Default =
%                                          1)
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
%%%%%%%%%%%%%%%%%%%%%%%%% BUILD AN INPUT PARSER %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% construct a parser object (builtin matlab class)
p = inputParser;

% define the default remove spikes setting
defRemoveSpikes = true;
% add the removeSpikes and the default value to the input parse obj. and
% validate it is a logical
addParamValue(p, 'removeSpikes',defRemoveSpikes, @islogical);

% define the default run states to plot 0=non-running trials only, 1 =
% running trials only, 2 = show all trials
defRunState = 2;
% add the runState and the default value to the input parse obj. and
% validate that it is a 0,1,2 using anonymous function
addParamValue(p, 'runState', defRunState, @(x) ismember(x, [0,1,2]));

% define the default LED setting. 0= only control trials, 1 = led only
% trials, 2 = plot both led and control trials togehter
defLedToPlot = 2;
% add the led condition and the default value to the input parse obj. and
% validate that it is a 0,1,2 using anonymous function
addParamValue(p, 'ledToPlot', defLedToPlot, @(x) ismember(x,[0,1,2]));

% define the default dataOffset to be 0;
defOffset = 0;
% add the dataOffset and default value to the parse obj.
addParamValue(p, 'dataOffset', defOffset, @isnumeric);

% define the default horizontal spacing between the plots in seconds.
defHorzSpace = 1;
% add the horz space to the parser and validate that it is numeric type
addParamValue(p, 'horzSpace', defHorzSpace, @isnumeric);

% call the input parser method parse
parse(p,varargin{:})
% finally retrieve the variable arguments from the parsed inputs
removeSpikes = p.Results.removeSpikes;
runState = p.Results.runState;
ledToPlot = p.Results.ledToPlot;
dataOffset = p.Results.dataOffset;
horzSpace = p.Results.horzSpace;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%% CALL EXP LOADER %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load pertinent substructures from a raw experiment and extract from cell
% array.
[loadedExpCell, ExpName] = multiEexpLoader('wholeCell',...
                                        {'data','stimulus','behavior',...
                                        'fileInfo','spikeIndices'});

Exp = loadedExpCell{1};
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%% DETERMINE THE STIMULUS VARIABLE %%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Call the function autoLocateStimVariables to load all the stimulus
% variable for this experiment
stimVariable = autoLocateStimVariables(Exp.stimulus);
% Confirm only one stimulus variable is present
if numel(stimVariable)>1
    errordlg(['This experiment has more than one stimulus variable',...
            char(10),'This function supports only single parameter data']);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%% GET STIMULUS TIMING INFORMATION %%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% For plotting the signals stored in the map we will need timing
% information and the frame rate at which the data was collected.

% use the first stimulus to get the timing
stimTiming = Exp.stimulus(1,1).Timing;

% The spacing between the plots (i.e. wait time = stimTiming(3)) will now
% be overridden by the horizontal spacing the user has chosen or the
% default value of 1 sec
stimTiming(3) = horzSpace;

%use the first file in fileInfo to obtain the sampling rate
samplingFreq = Exp.fileInfo(1,1).samplingFreq;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%% DETERMINE IF LED WAS SHOWN %%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  We now determine whether the led was shown by looking for the Led field
%  created when the user selects interleave.
ledPresence = isfield(Exp.stimulus,'Led');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%% CALL EPHYSDATAMAP TO CONSTRUCT MAP OBJ(s) %%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We now call ePhysDataMap to create our map objects. If the user selected
% to plot only led trials or to plot only non-Led trials we make a single
% map called dataMap. If the user selected to plot both control and led
% trials then we make two maps; dataMap for control trials and ledMap for
% led trials.

% Initialize maps to be empty mapNs;
dataMap = MapN();
cntrlMap = MapN();
ledMap = MapN();

if ledPresence && ledToPlot ~= 2 || ~ledPresence
    % create a map for the single led condition ( may be led or no led
    % trials)
    dataMap = ePhysDataMap(Exp.data,Exp.stimulus,stimVariable,...
                                               Exp.behavior,...
                                               Exp.fileInfo,...
                                               Exp.spikeIndices,...
                                               'runState',...
                                               runState,'ledCond',...
                                               ledToPlot,'dataOffset',...
                                               dataOffset,...
                                               'removeSpikes',...
                                               removeSpikes);

elseif ledPresence && ledToPlot == 2
    % create two maps, one for cntrl trials and the other holding ledTrials
    cntrlMap = ePhysDataMap(Exp.data,Exp.stimulus,stimVariable,...
                                               Exp.behavior,...
                                               Exp.fileInfo,...
                                               Exp.spikeIndices,...
                                               'runState',...
                                               runState,'ledCond',...
                                               0,'dataOffset',...
                                               dataOffset,...
                                               'removeSpikes',...
                                               removeSpikes);
                                           
    ledMap = ePhysDataMap(Exp.data,Exp.stimulus,stimVariable,...
                                               Exp.behavior,...
                                               Exp.fileInfo,...
                                               Exp.spikeIndices,...
                                               'runState',...
                                               runState,'ledCond',...
                                               1,'dataOffset',...
                                               dataOffset,...
                                               'removeSpikes',...
                                               removeSpikes);
end

% Lastly combine all the maps into a single cell array
allMaps = {dataMap,cntrlMap,ledMap};
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%% EXTRACT SIGNALS FROM THE MAP(S) %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We obtain the keys and signals present in the map(s). Note we are using
% the methods of the MapN class written by D Young on the file exchange.
% since we have combined all maps to a cell array we use cellfun
keySets = cellfun(@(map) keys(map), allMaps, 'UniformOut',0);
%collapse to single cell
allKeys = [keySets{:}];
%convert cells to unique array
keys = unique(cell2mat([allKeys{:}]));
% Also get the number of keys
numKeys = numel(keys);

% Obtain signals for each map using the method values of the mapN class
signalSets = cellfun(@(map) values(map), allMaps,'UniformOut',0);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%% RESHAPE THE SIGNALS INTO A MATRIX FOR PLOTTING %%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Signal sets contains the signals for each map ordered by stimulus
%condition. For each signalSet we will collect the signals for a given
%condition and concatenate along the column dimension. This will return a
%matrix for each stimulus condition that is numSignalPoints x numTrials. We
%use a nested cell function to accomplish.
for map = 1:numel(signalSets)
    if ~isempty(signalSets{map})
        signalMatrices{map} = cellfun(@(trial) cat(2,trial{1:end}),...
                        cellfun(@(cond) cond, signalSets{map},...
                        'UniformOut',0), 'UniformOut',0);
    else signalMatrices{map} = {};
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%% COMPUTE THE MEAN SIGNALS FOR EACH COND FOR EACH MAP %%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for map = 1:numel(signalMatrices)
    meanSignals{map} = cellfun(@(cond) mean(cond,2), signalMatrices{map},...
                        'UniformOut',0); 
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
assignin('base','meanSignals',meanSignals)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%% CREATE HORIZONTAL SPACING BETWEEN STIM CONDS %%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% During an exp the signals are collected for a time that is shorter than
% the visual stimulation (so the next trigger can be detected). The
% differernce between the recording time and the stimulation time is
% referred to as dead time. We will compute how long the dead time is in
% signalPoints and then add this to each of the signals.

% get the number of visual stimulation points 
numStimPoints = sum(stimTiming)*samplingFreq;

% get the number of acquired points. collapsing over all maps and using
% mode
numAcquiredPoints = mode(cellfun(@(x) numel(x), [meanSignals{:}]));

%calculate the dead time in points use floor to round  to next lowest point
deadTime = floor(numStimPoints-numAcquiredPoints);

% construct our deadTime signal
deadTimeSig = NaN*ones(deadTime,1);

% add the deadTimeSig to the meanSignals and zeroMean the signals
for map = 1:numel(meanSignals)
    if ~isempty(meanSignals{map})
        meanSignals{map} = cellfun(@(x) [x;deadTimeSig],...
                                   meanSignals{map},'UniformOut',0);
        meanSignals{map} = cellfun(@(x) zeroMean(x,'samplingFreq',...
                                    samplingFreq,...
                                   'zeroingTime',[1/samplingFreq, .100]),...
                                    meanSignals{map},'UniformOut',0);
    end
end

% since the time difference is likely not a whole number we need to
% calculate the remainder of the stimPts and use this to shift the plots
% appropriately
timeRem = rem(numStimPoints-numAcquiredPoints, deadTime);
% This is the array of times used to correctly shift the plots. We use it
% when we actually plot times series of signals below
timeShiftArray = [0:numKeys-1]*timeRem/samplingFreq;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% PLOTTING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Create a new figure by adding to the current number of figures
numFigs = numel(findall(0,'type','figure'));
figure(numFigs+1)
%Create an axes to the figure
signalAxes = axes;

% Get the number of dataPts collapsing over all maps and calculating mode
numDataPts = mode(cellfun(@(x) size(x,1), cat(2,meanSignals{:})));

for map = 1:numel(meanSignals) 
    if ~isempty(meanSignals{map});
        for key = 1:numKeys
            % Each mean array of signals (one for each key) will occupy one
            % column of the plot. key =1 signals at the farthest left and key =
            % end the farthest right column of the plot
            time = ((key-1)*numDataPts+1:key*numDataPts)/...
                (samplingFreq)+timeShiftArray(key);
            
            % set color of map if the map number is 3 then it is an led map
            if map == 3
                color = [0,1,0];
            else
                color = [0,0,0];
            end
            
            %plot the mean
            plot(signalAxes, time, meanSignals{map}{key},'Color',color,...
                'LineWidth',0.5)
            hold on;
        end
        
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
%%%%%%%%%%%%%%%%%%%%%%%% PLOT THE SIGNAL EPOCHS %%%%%%%%%%%%%%%%%%%%%%%%%%%
% To construct the stimulus epochs we will need to make two horizontal and
% two vertical boundaries to create our shaded box.

%Get the start and end times of the stimulus epochs
epochStarts =...
    stimTiming(1):sum(stimTiming):numKeys*sum(stimTiming);

% epoch ends are just epoch starts plus duration
epochEnds = epochStarts + stimTiming(2);

% package the starts and ends into a matrix column1 are starts, col2 is
% ends
stimEpochs = [epochStarts(:), epochEnds(:)]; 

% now pair the start and end epoch times in a cell array
pairedTimes = mat2cell(stimEpochs,[ones(1,size(stimEpochs,1))],[2]);

% now take each 2-el array and make a vector for each. This will be the
% vertical boundaries 
epochVectors = cellfun(@(y) [y(1):1:y(2)], pairedTimes, 'UniformOut',0);

% get the ylims of the current axis. This will be the upper horizontal
% boundary
yLimits = get(gca,'ylim');

% now create the upper horizontal boundary of our area
upperBoundaries = cellfun(@(c) yLimits(2)*ones(numel(c),1),...
    epochVectors,'UniformOut',0);

%loop through the stimEpochs and create our shaded area
for epoch = 1:numel(epochVectors)
    hold on
    % call the area function to make our shaded plot
    ha = area(epochVectors{epoch}, upperBoundaries{epoch}, yLimits(1));
    
    % set the area properties
    set(ha, 'FaceColor', [.85 .85 .85])
    set(ha, 'LineStyle', 'none')
    
    hold off;
end

%%%%%%%%%%%%%%%%% SET FIGURE AND AXIS PROPERTIES %%%%%%%%%%%%%%%%%%%%%%%%%%
% set the box of the axis off
set(gca, 'box','off')

% set the order of the plots to reverse
set(gca,'children',flipud(get(gca,'children')))

%set the figure position and size
set(signalAxes, 'Units', 'normalized', 'Position', [0.055 0.07 .92 .8])

set(gcf,'position',[293 528 1000 420]);

title(ExpName)

%%%%%%%%%%%%%%%%%%%%%%%%%%% SET AXIS LABELS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% set the Y Label
ylabel('Current (pA)','Interpreter','LaTex','FontSize',16);

% Set x labels to be the keys of the map note the keys of the nonLed map
% and the led maps are the same
keyStrs = cellfun(@(s) num2str(s), [allKeys{:}] ,'UniformOut',0);


% Handle blank gracefully since it is set as inf in the map key set
if strcmp(keyStrs{end},'inf')
            keyStrs{end} = 'Blank'; 
end

% set the position of the xtick marks and labels
xVals = stimTiming(1)+stimTiming(2)/2:sum(stimTiming):...
                                            numKeys*sum(stimTiming);
set(gca,'xTick',xVals)
set(gca,'xTickLabel',keyStrs)
end
 
 
 
 

