function fluorPlotter(fluorMap, stimVariable, stimulus, fileInfo, hfig)
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

stimTiming = stimulus(1,1).Timing;
frameRate = fileInfo(1,1).imageFrameRate;
% Obtain the map keys and values
keys = fluorMap.keys;

% The values from the map are the df/f signals. Ex. for two files with 13
% triggers each and 50 frames per trigger the cell allSigs = {{[50x1]
% [50x1]},{[50x1] [50x1]}...}
allSigs = fluorMap.values;


% call cellfun within cellfun to concatenate the double arrays of signals
% along the column dimension (cell with frames/stack x numstimSets doubles)
% e.g 50 frames x 2 stimulusFiles
signalMatrices = cellfun(@(y) cat(2,y{1:end}), cellfun(@(x) x, allSigs,...
                        'UniformOut', 0), 'UniformOut',0);
                    
% Be sure to remove any empty cells present
emptyCells = cellfun(@isempty,signalMatrices);
signalMatrices(emptyCells) = [];

% Compute the mean of the matrices we just concatenated along the column
% dimension (cell with frames/stack x 1 double array)
meanSignals = cellfun(@(r) mean(r,2), signalMatrices,'uniformout',0);

% test adding nans, the goal here is to take care of the dead time when the
% visual stimulation is running but the acquisition has stopped. We need to
% know the number of frames that would have been collected, set these as
% NaNs and concatenate them onto the end of each of the mean signals.
% Another option is to plot each data trace as a separate plot rather than
% concatenating at all. Think this over as to how you want to display.
% Determine the number of frames in the stimulus
% we will round decimal frames meaning we may incurr a 1-frame error
numStimFrames = round(sum(stimTiming)*frameRate);
% determine the number of acquired frames (we take the mode but scan image
% should always collect the same number of frames. But just in case.
numAcquiredFrames = mode(cellfun(@(y) numel(y), meanSignals));
% The difference will be the number of missing frames
numMissingFrames = round(numStimFrames-numAcquiredFrames);
% construct an array of missing signal substituting NaNs in place
missingSig = NaN*ones(numMissingFrames, 1);
% concatenate this missing signal onto each of the mean signals
meanSignals = cellfun(@(y) [y;missingSig], meanSignals,'uniformout',0);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%% GENERATE SINGLE TRIALS PLOT %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We will need to add the missing signal onto each of the signal matrices.
% Then place all signals from each trigger into a single colum of a matrix
% fro plotting.

% Create the missing signal matrix cell array for conactenation onto
% sigMatrix cell array
missingSigMatrix = cellfun(@(r) repmat(missingSig,1,size(r,2)),...
                            signalMatrices, 'UniformOut',0);

% concatenate each missingSigMatrix onto each signal matrix in the
% signalMatriices cell array
fullSignalMatrices = cellfun(@(x,y) vertcat(x,y), signalMatrices ,...
                                missingSigMatrix,'uniformOut',0);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% PLOTTING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plotting will occur in two stages. In the first stage, we will plot each
% of the individual trials and plot the means of the individual trials. In
% the second stage we will plot the stimulus timing as a gray background.

% We will loop through the cell array of signal matrices. Since these are
% key ordered (from allSigs above) then we just loop through the key number
for key = 1:numel(fullSignalMatrices)
    % calculate the frames for each cell of arrays in the cell array by
    % using the key and length(fullSignals) along the row dim
    frames = (key-1)*(numel(fullSignalMatrices{1}(:,1)))+1:...
                                  key*(numel(fullSignalMatrices{1}(:,1)));
    % convert the frames to a time
    time = frames/frameRate;
    
    % now plot the mean of the individual trials
    plot(time,meanSignals{key},'Color',[0,0,0],'LineWidth',2)
    hold on
    % plot the individual trials for each key
    plot(time,fullSignalMatrices{key},'Color',[.5,.5,1])

end

% The second stage will be plotting the stimulation times as a gray
% background

% Get the start times of each visual presentation
% The visual stimulation starts at stimTiming(1) secs and restarts
% sum(stimTiming) later up to the number of keys*sum(stimTiming)
visStarts = stimTiming(1):sum(stimTiming):(numel(keys)*sum(stimTiming));
% Now calculate the visual endTimes
visEnds = visStarts+stimTiming(2);

% Now we will loop through the visual starts, and construct a gray area to
% draw to the plot
for stim = 1:numel(visStarts)
    % package the stimStarts and ends together
    stimEpoch = [visStarts(stim), visEnds(stim)];

    hold on;
    % create a horizontal vector for the stimulation times
    stimTimesVec = stimEpoch(1):1:stimEpoch(2);
    
    % get the 'y' limits of the current axis
    yLimits = get(gca, 'ylim');
    
    % creat a 'y' vector that will form the upper horizontal boundary of
    % our shaded region
    ylimVector= yLimits(2)*ones(numel(stimTimesVec),1);
    ha = area(stimTimesVec, ylimVector, yLimits(1));
    
    % set the area properties
    set(ha, 'FaceColor', [.85 .85 .85])
    set(ha, 'LineStyle', 'none')
    
    set(gca, 'box','off')
    hold off;
end

% set the labels
ylabel('$\frac{\Delta F}{F}$','Interpreter','LaTex','FontSize',20);

% Set x labels to be the keys of the map
keyStrs = cellfun(@(s) num2str(s), keys ,'UniformOut',0);
switch stimVariable
    case 'Surround_Orientation'
        centerOri = num2str(stimulus(1,1).Center_Orientation);
        keyStrs{end} = ['Center Only = ', centerOri];
    case 'Orientation'
        if strcmp(keyStrs{end},'inf')
            keyStrs{end} = 'Blank'; 
        end
end
xVals = stimTiming(1)+stimTiming(2)/2:sum(stimTiming):...
                                            numel(keys)*sum(stimTiming);
set(gca,'xTick',xVals)
set(gca,'xTickLabel',keyStrs)

% We now want to reorder the data plot and the area we just made so that
% the signal always appears on top we do this by accessing all lines
% ('children') and flip them
set(gca,'children',flipud(get(gca,'children')))

%set(gca, 'Units', 'normalized', 'Position', [0.075 0.07 .92 .90])
%set(gcf,'Position',[450 260, 1100, 350]);


