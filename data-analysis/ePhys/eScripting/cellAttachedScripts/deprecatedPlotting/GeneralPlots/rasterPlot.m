function rasterPlot(runState, stimVariable, varargin )
% rasterPlot generates a plot of spike times and plots them to an axis
% containing the stimulus times.
% INPUTS                    : runstate, integer to seperate trials based on
%                             running behavior (1 = yes, 0 = No, 
%                             2= Keep ALL)
%                           : stimVariable, stimulus variable to construct
%                             rasters from (e.g. 'Orientation')
%
%               varargin:
%                           : numCols, number of columns to subplot
%                           : tickSpacing, the vertically spacing between
%                             ticks
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
defaultTickSpacing = .5;
defaultSave = true;

% Add all requried and optional args to the input parser object
addRequired(inputParse,'runState',@isnumeric);
addRequired(inputParse,'stimVariable', @ischar);
addParamValue(inputParse,'numCols', defaultNumCols, @isnumeric)
addParamValue(inputParse, 'tickSpacing', defaultTickSpacing, @isnumeric)
addParamValue(inputParse,'save',defaultSave,@islogical);

% call the parser
parse(inputParse, runState, stimVariable, varargin{:})

% rename the the results from the parser
runState = inputParse.Results.runState;
stimVariable = inputParse.Results.stimVariable;
numCols = inputParse.Results.numCols;
tickSpacing = inputParse.Results.tickSpacing;
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%% PREP FOR PLOTTING %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Get stimulus information and time steps
stimTimes = subExp.stimulus(1,1).Timing;
dt = 1/subExp.fileInfo(1,1).samplingFreq;
% constuct a vector of stimulus times to plot a shaded region
stimTimesVec = stimTimes(1):dt:stimTimes(1)+stimTimes(2);

% get all the stimulus keys from the spikeMap and store to array
stimValues = cell2mat(spikeMap.keys);

% get the number of subplots
numSubPlots = numel(stimValues);
numRows = ceil(numSubPlots/numCols);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%% CONSTRUCT PLOTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We will loop through each of the stimulus values (e.g. angles) and then
% loop through the trials at this angle stored in the map and plot to a
% subplot

% Create a new figure to plot to
figure;

for stimValue = 1:numel(stimValues)
    hSub = subplot(numRows,numCols,stimValue);
    hold on
    % get cell-array of all trials here called spike arrays
    spikeArrays = spikeMap(stimValues(stimValue));
    for array = 1:numel(spikeArrays)
        plot([spikeArrays{array}; spikeArrays{array}],...
             [array-1+tickSpacing*ones(size(spikeArrays{array}));...
             array*ones(size(spikeArrays{array}))], 'Color',[0 204/255 1])
            ylim([0 numel(stimValues)])
    end

    %%%%%%%%%%%%%%%%% CREATE A SUBPLOT TITLE WITH STIMINFO %%%%%%%%%%%%%%%%
    hSubTitle = title(num2str(stimValues(stimValue)));

    %%%%%%%%%%%%%%%%%%%%%%%% SET AXIS PROPERTIES %%%%%%%%%%%%%%%%%%%%%%%%%%
    set(hSub, ...
        'Box'         , 'off'     , ...
        'TickDir'     , 'out'     , ...
        'TickLength'  , [.02 .02] , ...
        'XMinorTick'  , 'on'      , ...
        'YMinorTick'  , 'off'     , ...
        'YTick'       , []        , ...
        'YGrid'       , 'off'     , ...
        'XColor'      , [0 0 0]   , ...
        'YColor'      , [1 1 1]   , ...
        'LineWidth'   , 1             );
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %%%%%%%%%%%%%%%%%%%%% CONSTRUCT STIMULUS BACKGROUND %%%%%%%%%%%%%%%%%%%
    % get the 'y' limits of the current axis
    yLimits = get(hSub, 'ylim');
    
    % creat a 'y' vector that will form the upper horiz boundary of our
    % shaded region
    ylimVector = yLimits(2)*ones(numel(stimTimesVec),1);
    % call area to create shaded region
    ha = area(stimTimesVec, ylimVector, yLimits(1));
    
    %%%%%%%%%%%%%%%%%%%%%%%%% SET AREA PROPERTIES %%%%%%%%%%%%%%%%%%%%%%%%%
    set(ha   , 'FaceColor'   , [.85 .85 .85])
    set(ha   , 'LineStyle'   ,        'none')
    %set(gca   , 'box'         ,         'off')
    hold off;
    
    % We now want to reorder the data plot & the area we just made so that
    % the signal always appears on top we do this by accessing all lines
    % ('children') and flip them
    set(gca,'children',flipud(get(gca,'children')))

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

%%%%%%%%%%%%%%%%%%%%%%%% SET FIGURE POSITION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
set(gcf,'position',[550 320 800 600])

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%% AUTOSAVE FIGURE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% if the user decides to save a figure from the command line call of this
% function then we will construct a default figure name and start the in a
% save directory specified in ExpDirInformation.m
if inputParse.Results.save
    ExpDirInformation
    %From the dirInfo structure in this file we will set the base load
    %location for saving the file. That is, uiputfile will start at this 
    %directory for saving
    RoughFigLoc = dirInfo.RoughFigLoc;
    % construct a default name for the figure
    defaultFigName = [RoughFigLoc,date,'_', cellNumExpType,'_state_',...
                    num2str(runState)];


%%%%%%%%%%%%%%%% CONSTRUCT PATH AND FILE NAME %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    [fileName,pathName] = uiputfile(RoughFigLoc,'Save As',defaultFigName);

    file = fullfile(pathName,fileName);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% SAVE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if ischar(fileName) && ischar(pathName) 
        saveas(gcf,file,'eps')
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end

