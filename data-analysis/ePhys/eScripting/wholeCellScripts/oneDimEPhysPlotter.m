function oneDimEPhysPlotter(exp,stimVariable,varargin)
% oneDimEPhysPlotter plots the data in dataMap in a time series
% INPUTS:           exp, can be set to [] if user wants to select from file
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%% CALL EXP LOADER %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isempty(exp)
    [loadedExpCell,ExpName] = multiEexpLoader('raw',{'data','stimulus','behavior',...
                                        'fileInfo','spikeIndices'});

    Exp = loadedExpCell{1};
else
    Exp = exp;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%% GET STIMULUS TIMING INFORMATION %%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% For plotting the signals stored in the map we will need timing
% information and the frame rate at which the data was collected.

% use the first stimulus to get the timing
stimTiming = Exp.stimulus(1,1).Timing;

% If the delay (i.e. stimTiming(3)>2 secs we will set it to be one second)
% this makes the plot easier to see because the delay affects the
% horizontal spacing between the inidvidual stimulus conditions. If the
% user records more than one second following a stimulus then this should
% be updated.
if stimTiming(3)>2
    stimTiming(3) = 1;
end

%use the first file in fileInfo to obtain the sampling rate
samplingFreq = Exp.fileInfo(1,1).samplingFreq;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%% CALL EPHYSDATAMAP TO CONSTRUCT MAP OBJ %%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
dataMap = ePhysDataMap(Exp.data,Exp.stimulus,{stimVariable},...
                                               Exp.behavior,...
                                               Exp.fileInfo,...
                                               Exp.spikeIndices,varargin{:});
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%% EXTRACT SIGNALS FROM THE MAP %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We obtain the keys and signals present in the dataMap. Note we are using
% the methods of the MapN class written by D Young on the file exchange.
keySet = keys(dataMap);
% Signals will be a cell of cells where each inner cell contains a set of
% arrays for that key
signals = values(dataMap);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%% RESHAPE THE SIGNALS INTO A MATRIX FOR PLOTTING %%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% To convert our cell arrays to matrices for each condition, we collect the
% signals for a given condition and concatenate along the column dimension.
% This will return a matrix for each stimulus condition that is
% numSignalPoints x numTrials. We use a nested cell function to accomplish.
signalMatrices = cellfun(@(trial) cat(2,trial{1:end}),...
                        cellfun(@(cond) cond, signals,...
                        'UniformOut',0), 'UniformOut',0);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%% COMPUTE THE MEAN SIGNAL FOR EACH COND %%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We use cell fun over the conditions to compute the mean across columns
meanSignals = cellfun(@(cond) mean(cond,2), signalMatrices,...
                        'UniformOut',0);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%% CAT NANs FOR SIGNAL DEAD TIME %%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% During an exp the signals are collected for a time that is shorter than
% the visual stimulation (so the next trigger can be detected). The
% differernce between the recording time and the stimulation time is
% referred to as dead time. We will compute how long the dead time is in
% signalPoints and then add this to each of the signals.

% get the number of visual stimulation points 
numStimFrames = sum(stimTiming)*samplingFreq;

% get the number of acquired points. This should always be the same but in
% case not we will take the mode of the numel of meanSignals. Also here we
% make the assumption that the dead time is the same for both led and non
% led trials, this assumption if relaxed requires a code change here.
numAcquiredPoints = mode(cellfun(@(x) numel(x), meanSignals));

%calculate the dead time in points
frameDiff = floor(numStimFrames-numAcquiredPoints);

% since the frame difference is likely not a whole number we need to
% calculate the remainder of the frames and use this to shift the plots
% appropriately
frameRem = rem(numStimFrames-numAcquiredPoints, frameDiff);
% This is the array of times used to correctly shift the plots. We use it
% when we actually plot times series of signals below
timeShiftArray = [0:numel(keySet)-1]*frameRem/samplingFreq;

% construct our deadTime signal
deadTimeSig = NaN*ones(frameDiff,1);

% Create a deadTime signal matrix cell array for conactenation onto
% signalMatrices cell array
deadTimeSigMatrix = cellfun(@(r) repmat(deadTimeSig,1,size(r,2)),...
                            signalMatrices, 'UniformOut',0);
                        
% concatenate each deadtimeSigMatrix onto each signal matrix in the
% signalMatriices cell array
fullSignalMatrices = cellfun(@(x,y) vertcat(x,y),...
                                signalMatrices ,...
                                deadTimeSigMatrix,'UniformOut',0);
                            
% add NaN deadTime signal to means
fullMeanSigs = cellfun(@(y) [y;deadTimeSig], meanSignals,...
                        'Uniformout',0);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% PLOTTING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The plotting will occur in two steps: 1) plot the signals 2) plot the
% gray epochs
% Open an axes to plot to
signalAxes = axes;

% get the number of dataPoints from the fullSignalMatirces (remember
% the signal matrices for each condition are numDataPoints x numTrials)
DataPoints = mode(cellfun(@(r) size(r,1), fullSignalMatrices));

for key = 1:numel(fullSignalMatrices)
    % Each matrix of signals (one for each key) will occupy one
    % column of the plot. key =1 signals at the farthest left and key = end
    % the farthest right column of the plot
    
    time = ((key-1)*DataPoints+1:key*DataPoints)/...
            (samplingFreq)+timeShiftArray(key);
    
    % now plot the mean of the individual trials
    plot(signalAxes, time,fullMeanSigs{key},'Color',[0,0,0],'LineWidth',0.5)
    hold on
    % plot the individual trials for each key
    %plot(signalAxes, time,fullSignalMatrices{key},'Color',[.75,.75,.75],...
        %'LineWidth',0.5)
end

%%%%%%%%%%%%%%%%%%%%%%%% PLOT THE SIGNAL EPOCHS %%%%%%%%%%%%%%%%%%%%%%%%%%%
% To construct the stimulus epochs we will need to make two horizontal and
% two vertical boundaries to create our shaded box.

%Get the start and end times of the stimulus epochs
epochStarts =...
    stimTiming(1):sum(stimTiming):numel(keySet)*sum(stimTiming);

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
set(signalAxes, 'Units', 'normalized', 'Position', [0.055 0.07 .92 .80])

set(gcf,'position',[293 528 1000 420]);

%%%%%%%%%%%%%%%%%%%%%%%%%%% SET AXIS LABELS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% set the Y Label
ylabel('Current (pA)','Interpreter','LaTex','FontSize',16);

% Set x labels to be the keys of the map note the keys of the nonLed map
% and the led maps are the same
keyStrs = cellfun(@(s) num2str(s), [keySet{:}] ,'UniformOut',0);

% Handle blank gracefully since it is set as inf in the map key set
if strcmp(keyStrs{end},'inf')
            keyStrs{end} = 'Blank'; 
end

% set the position of the xtick marks and labels
xVals = stimTiming(1)+stimTiming(2)/2:sum(stimTiming):...
                                            numel(keySet)*sum(stimTiming);
set(gca,'xTick',xVals)
set(gca,'xTickLabel',keyStrs)
end




