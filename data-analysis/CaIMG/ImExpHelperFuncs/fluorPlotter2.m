function fluorPlotter2(fluorMap, stimVariable,stimulus, fileInfo, hfig)
% fluorPlotter plots a time series of of fluroescence signals.
% INPUTS                    : fluorMap a map object of percentage
%                             fluorescent signals
%                           : stimVariable of interest to plot over
%                           : imExp experiment struct passed from
%                             imExpAnalyzer
%                           : haxes, an axes handle we will plot to
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
%%%%%%%%%%%%%%%%%%%%%% GET STIMULUS TIMING INFORMATION %%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% For plotting the signals stored in the map we will need timing
% information and the frame rate at which the data was collected.

% use the first stimulus to get the timing
stimTiming = stimulus(1,1).Timing;
% use the first file Info to get the frame rate
frameRate = fileInfo(1,1).imageFrameRate;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%% EXTRACT LED AND NONLED SIGNALS %%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The incoming fluorMap is a 2-el cell array. The first element contains a
% fluorMap for non led trials and the second element contains a fluormap
% for led trials. We need to get the keys of each map and then extract the
% signals from each map (if two maps are present)

% First get the keys of the nonLedMap. The first index indicates
% nonLedTrials, the second index is the roi number. This plotter plots only
% one roi at a time so only the first element is occupied.
assignin('base','fluorMap',fluorMap)
 nonLedKeys = fluorMap{1}{1}.keys;

% now get the signals of the nonLed signals.  The values from the map are
% the df/f signals. Ex. for two files with 12 trigs and 30 frames/trigg
% gives a cell array with 12 elements and each of these cells contains a 2
% 30x1 double arrays. {{[30x1], [30x1]},{[30x1],[30x1]},...}
 nonLedSigs = fluorMap{1}{1}.values;
 
 % now obtain the ledKeys and the ledSignals if an Led is shown
 if ~isempty(fluorMap{2}{1})
     % obtain keys and signals
     ledKeys = fluorMap{2}{1}.keys;
     ledSigs = fluorMap{2}{1}.values;
 end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%% RESHAPE SIGNALS INTO A MATRIX FOR PLOTTING %%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% To convert our cell array of signals to a matrix, we collect the signals
% for a given condition then concatentate these along the column dimension.
% This returns a matrix for each condition of the stimulus organized by
% numSignalPoints x numTrials
nonLedSignalMatrices = cellfun(@(trial) cat(2,trial{1:end}), ...
                        cellfun(@(cond) cond, nonLedSigs,...
                        'UniformOut', 0), 'UniformOut',0);
                    
% Be sure to remove any empty cells present
emptyCells = cellfun(@isempty,nonLedSignalMatrices);
nonLedSignalMatrices(emptyCells) = [];

% Do the same for the led signals if present
if ~isempty(fluorMap{2}{1})
    % make ledSignalMatrices
    ledSignalMatrices = cellfun(@(trial) cat(2,trial{1:end}), ...
                        cellfun(@(cond) cond, ledSigs,...
                        'UniformOut', 0), 'UniformOut',0);
    % Be sure to remove any empty cells present
    emptyCells = cellfun(@isempty,ledSignalMatrices);
    ledSignalMatrices(emptyCells) = [];  
end              
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%% COMPUTE THE MEAN SIGNALS %%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% For each condition we can now compute the mean of the signals in the
% signal matrices be averaging across trials (i.e. along columns) use
% cellfun to accomplish
meanNonLedSigs = cellfun(@(cond) mean(cond,2), nonLedSignalMatrices,...
                        'UniformOut',0);
if ~isempty(fluorMap{2}{1})
    meanLedSigs = cellfun(@(cond) mean(cond,2), ledSignalMatrices,...
                        'UniformOut',0);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%% CAT NANs FOR SIGNAL DEAD TIME %%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% During an exp the signals are collected for a time that is shorter than
% the visual stimulation (so the next trigger can be detected). The
% differernce between the recording time and the stimulation time is
% referred to as dead time. We will compute how long the dead time is in
% frames and then add this to each of the signals.

% get the number of visual stimulation frames 
numStimFrames = sum(stimTiming)*frameRate;

% get the number of acquired frames. This should always be the same but in
% case not we will take the mode of the numel of meanSignals. Also here we
% make the assumption that the dead time is the same for both led and non
% led trials, this assumption if relaxed requires a code change here.
numAcquiredFrames = mode(cellfun(@(x) numel(x), meanNonLedSigs));

%calculate the dead time in frames
frameDiff = floor(numStimFrames-numAcquiredFrames);

% since the frame difference is likely not a whole number we need to
% calculate the remainder of the frames and use this to shift the plots
% appropriately
frameRem = rem(numStimFrames-numAcquiredFrames, frameDiff);
% This is the array of times used to correctly shift the plots. We use it
% when we actually plot times series of signals below
timeShiftArray = [0:numel(nonLedKeys)-1]*frameRem/frameRate;

% construct our deadTime signal
deadTimeSig = NaN*ones(frameDiff,1);

%Laslty concatenate the dead time signal to the matrix signals and the mean
%signals

% Create a deadTime signal matrix cell array for conactenation onto
% signalMatrices cell array
deadTimeSigMatrix = cellfun(@(r) repmat(deadTimeSig,1,size(r,2)),...
                            nonLedSignalMatrices, 'UniformOut',0);
                        
% concatenate each deadtimeSigMatrix onto each signal matrix in the
% signalMatriices cell array
fullNonLedSignalMatrices = cellfun(@(x,y) vertcat(x,y),...
                                nonLedSignalMatrices ,...
                                deadTimeSigMatrix,'uniformOut',0);
if ~isempty(fluorMap{2}{1})
    fullLedSignalMatrices = cellfun(@(x,y) vertcat(x,y),...
                                ledSignalMatrices ,...
                                deadTimeSigMatrix,'uniformOut',0);
end

% add NaN deadTime signal to means
meanNonLedSigs = cellfun(@(y) [y;deadTimeSig], meanNonLedSigs,...
                        'Uniformout',0);
                    
if ~isempty(fluorMap{2}{1})
    meanLedSigs = cellfun(@(y) [y;deadTimeSig], meanLedSigs,...
                        'Uniformout',0);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% PLOTTING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The plotting will occur in 3 steps: 1) Plot the non-led signals and the
% means 2) plot the led signals and the means. 3) plot the stimulus epochs
% as gray backgrounds
signalAxes = axes;
%%%%%%%%%%%%%%%%%%%%%%%%% PLOT THE NON-LED SIGS %%%%%%%%%%%%%%%%%%%%%%%%%%%
% We will loop through the fullNonLedSignalMatrices. Note these matrices
% are already ordered by the keys of the fluorMap.

% get the numData points (i.e. frames) we take the mode of the size of
% the signalMatrices since perhaps they could be different (remember
% the signal matrices for each condition are numFrames x numTrials)
frames = mode(cellfun(@(r) size(r,1), fullNonLedSignalMatrices));

for key = 1:numel(fullNonLedSignalMatrices)
    % Each matrix of signals (one for each key) will occupy one
    % column of the plot. key =1 signals at the farthest left and key = end
    % the farthest right column of the plot
    
    time = ((key-1)*frames+1:key*frames)/(frameRate)+timeShiftArray(key);

    % now plot the mean of the individual trials
    plot(signalAxes, time,meanNonLedSigs{key},'Color',[0,0,0],'LineWidth',2)
    hold on
    % plot the individual trials for each key
    plot(signalAxes, time,fullNonLedSignalMatrices{key},'Color',[.5,.5,.5])
end

%%%%%%%%%%%%%%%%%%%%%%%% PLOT THE LED SIGNALS %%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~isempty(fluorMap{2}{1})
    for key = 1:numel(fullLedSignalMatrices)
        % Each matrix of signals (one for each key) will occupy one column
        % of the plot. key =1 signals at the farthest left and key = end
        % the farthest right column of the plot
        
        time =...
            ((key-1)*frames+1:key*frames)/(frameRate)+timeShiftArray(key);
        
        % now plot the mean of the individual trials
        plot(signalAxes, time,meanLedSigs{key},'Color',[1,0,0],'LineWidth',2)
        hold on
        % plot the individual trials for each key
        plot(signalAxes, time,fullLedSignalMatrices{key},'Color',[1, 0.4, 0.7])
    end
end

%%%%%%%%%%%%%%%%%%%%%%%% PLOT THE SIGNAL EPOCHS %%%%%%%%%%%%%%%%%%%%%%%%%%%
% To construct the stimulus epochs we will need to make two horizontal and
% two vertical boundaries to create our shaded box.

%Get the start and end times of the stimulus epochs
epochStarts =...
    stimTiming(1):sum(stimTiming):numel(nonLedKeys)*sum(stimTiming);

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
set(signalAxes, 'Units', 'normalized', 'Position', [0.075 0.07 .92 .90])
set(hfig,'Position',[450 260, 1100, 350]);

%%%%%%%%%%%%%%%%%%%%%%%%%%% SET AXIS LABELS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% set the Y Label
ylabel('$\frac{\Delta F}{F}$','Interpreter','LaTex','FontSize',20);

% Set x labels to be the keys of the map note the keys of the nonLed map
% and the led maps are the same
keyStrs = cellfun(@(s) num2str(s), nonLedKeys ,'UniformOut',0);

% Handle blank gracefully since it is set as inf in the map key set
if strcmp(keyStrs{end},'inf')
            keyStrs{end} = 'Blank'; 
end

% Handle the center only case special to center surround stimuli gracefully
if strcmp(stimVariable, 'Surround_Orientation')
        centerOri = num2str(stimulus(1,1).Center_Orientation);
        keyStrs{end} = ['Center Only = ', centerOri];
end

% set the position of the xtick marks and labels
xVals = stimTiming(1)+stimTiming(2)/2:sum(stimTiming):...
                                            numel(nonLedKeys)*sum(stimTiming);
set(gca,'xTick',xVals)
set(gca,'xTickLabel',keyStrs)
