function spikePSTH(runState, stimVariable, varargin)
% spikePSTH generates an average peristimulus time histogram of spikes from
% a single exp
% INPUTS                    : runstate, integer to seperate trials based on
%                             running behavior (1 = yes, 0 = No, 
%                             2= Keep ALL)
%                           : stimVariable, stimulus variable to construct
%                             rasters from (e.g. 'Orientation')
%
%               varargin:
%                           : numCols, number of columns to subplot
%                           : binSize, defaults to 250 msec
%                           : save figure dialog (defaults to true)
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
inputParse = inputParser;
% set default values for the options under varargin
defaultNumCols = 4;
defaultBinSize = .250; % 250 msecs 
defaultSave = true;

% Add all requried and optional args to the input parser object
addRequired(inputParse,'runState',@isnumeric);
addRequired(inputParse,'stimVariable', @ischar);
addParamValue(inputParse,'numCols', defaultNumCols, @isinteger)
addParamValue(inputParse, 'binSize', defaultBinSize, @isnumeric)
addParamValue(inputParse,'save',defaultSave,@islogical);

% call the parser
parse(inputParse, runState, stimVariable, varargin{:})

% rename the the results from the parser
runState = inputParse.Results.runState;
stimVariable = inputParse.Results.stimVariable;
numCols = inputParse.Results.numCols;
binSize = inputParse.Results.binSize;
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
%%%%%%%%%%%%%% CALL SPIKETIMES MAP FUNC TO CONSTRUCT MAP OBJ %%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% we will now call the function spikeTimesMap which constructs a map
% object of spikeTimes 'keyed' on stimulus Variable. Running state is
% passed to this function to return a map that meets the user definded
% running state condition ( see inputs above)
[spikeMap] = spikeTimesMap(runState,...
                            stimVariable, subExp.behavior,...
                            subExp.spikeIndices, subExp.stimulus,...
                            subExp.fileInfo);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% CALCULATE PSTH %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get all the stimulus keys from the spikeMap and store to array
stimValues = cell2mat(spikeMap.keys);

% Get the total time of the recording
recTime = subExp.fileInfo(1,1).samplesPerTrigg/...
                               subExp.fileInfo(1,1).samplingFreq;

% construct bins for calculating the average firing rate during
bins = 0:binSize:recTime;

% spikeMap.Values returns a cell of cells each containing arrays for that
% key. We use a nested cellfun call to index to each array and calculate
% the histogram of each and return back a cell of cells of histograms
allHists = cellfun(@(t) cellfun(@(y) histc(y,bins), t,...
                'UniformOutput',0), spikeMap.values, 'UniformOutput',0);
            
% now average each cell in the cell array to make an average histogram for
% each key. Note we must transpose each cell so that the mean calculates an
% average hist vector. We also divide by the binSize to get a firng rate
% avg histogram
avgHists = cellfun(@(t) mean(cell2mat(t'))/binSize, allHists,...
                    'UniformOutput',0);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%% PREP TO PLOT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%% GET STIMULUS INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We obtain stimulus information for plotting the stimulus epochs
% Get stimulus information and time steps
stimTimes = subExp.stimulus(1,1).Timing;
dt = 1/subExp.fileInfo(1,1).samplingFreq;
% constuct a vector of stimulus times to plot a shaded region
stimTimesVec = stimTimes(1):dt:stimTimes(1)+stimTimes(2);
% get all the stimulus keys from the spikeMap and store to array
stimValues = cell2mat(spikeMap.keys);

%%%%%%%%%%%%%%%%%%%%%%%%%% GET SUBPLOT INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calculate the number of subplots to be shown
numSubplots = numel(avgHists);
% calculate the number of rows based on the num of columns user inputed or
% defaulted to
numRows = ceil(numSubplots/numCols);

% We want the ylimits of each subplot to be equal so they can easily be
% compared by eye. So we set the ylimit to be the maximum of all the
% histograms
maxHistVal = max(cellfun(@(t) max(t), avgHists));

% Create a new figure to plot to
figure;

for array = 1:numel(avgHists)
    % Plot avg his to each subplot
    hSub = subplot(numRows, numCols, array);
    plot(bins, avgHists{array},'Color',[0 204/255 1],'LineWidth', 1)
    ylim([0 ceil(maxHistVal)])
    hold on
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%% CONSTRUCT STIMULUS BACKGROUND %%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % To construct the stimulus epoch as a gray background we need the
    % ylimits of each plot and the xlimits over whcih to draw the gray area
    
    % Get the 'y' limits of the current axis
    yLimits = get(hSub, 'ylim');
    
    % Next, we need to create an array of y values the sames size as the
    % x-values we will plot the stimulus over
    
    % Creat a 'y' array that will form the upper horiz boundary of our
    % shaded region
    ylimVector = yLimits(2)*ones(numel(stimTimesVec),1);
    % Now we call the area function to plot our x-values, y-values
    ha = area(stimTimesVec, ylimVector, yLimits(1));
    
    %%%%%%%%%%%%%%%%%%%%%%%%% SET AREA PROPERTIES %%%%%%%%%%%%%%%%%%%%%%%%%
    set(ha   , 'FaceColor'   , [.85 .85 .85])
    set(ha   , 'LineStyle'   ,        'none')
    set(gca   , 'box'         ,         'off')
    hold off;
    xlim([0, round(recTime)]);
    % We now want to reorder the data plot & the area we just made so that
    % the signal always appears on top we do this by accessing all lines
    % ('children') and flip them
    set(gca,'children',flipud(get(gca,'children')))
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %%%%%%%%%%%%%%%%% CREATE A SUBPLOT TITLE WITH STIMINFO %%%%%%%%%%%%%%%%
    hSubTitle = title(num2str(stimValues(array)));

    %%%%%%%%%%%%%%%%%%%%%%%% SET AXIS PROPERTIES %%%%%%%%%%%%%%%%%%%%%%%%%%
    set(hSub, ...
        'Box'         , 'off'     , ...
        'TickDir'     , 'out'     , ...
        'TickLength'  , [.02 .02] , ...
        'XMinorTick'  , 'on'      , ...
        'YMinorTick'  , 'off'     , ...
        'YGrid'       , 'off'     , ...
        'YTick'       , [0 ceil(maxHistVal)],...
        'XColor'      , [0 0 0]   , ...
        'YColor'      , [0 0 0]   , ...
        'LineWidth'   , 1             );
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%% CONSTRUCT PLOT SUPER TITLE %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
            num2str(runState)]; 
        
% Use uicontrol to place title on subplot figure
hTitle = annotation('textbox', [0 0.9 1 0.1], ...
    'String', expTitle, ...
    'EdgeColor', 'none', ...
    'HorizontalAlignment', 'center');

set(hTitle                , 'FontName'   , 'Helvetica' );
set(hTitle                , 'FontSize'   , 12        ,...
                            'FontWeight' , 'bold'      );
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%                        
%%%%%%%%%%%%%%%%%%%%%%%% SET FIGURE POSITION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
set(gcf,'position',[550 320 800 600])

end

