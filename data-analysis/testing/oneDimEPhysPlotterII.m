function oneDimEPhysPlotterII(varargin)
% oneDimEPhysPlotterII plots single parameter data present in the dataMap
% of an Exp. This function will direct the user to load the experiment.
% INPUTS:           VARARGIN: 
%                          removeSpikes:   0 or 1 logical
%                          runState:       a numeric 0, 1 or 2. Zero is
%                                          non-running trials, 1 is running
%                                          trials and 2 is all trials to be
%                                          plotted
%                          led:            a numeric 0, 1 or 2. Zero means
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
loadedExpCell = multiEexpLoader('raw',{'data','stimulus','behavior',...
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
ledPresence = isfield(stimulus,'Led_Condition');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%% CALL EPHYSDATAMAP TO CONSTRUCT MAP OBJ(s) %%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We now call ePhysDataMap to create our map objects. If the user selected
% to plot only led trials or to plot only non-Led trials we make a single
% map called dataMap. If the user selected to plot both control and led
% trials then we make two maps; dataMap for control trials and ledMap for
% led trials.
if ledPresence && ledToPlot ~= 2
    dataMap = ePhysDataMap(Exp.data,Exp.stimulus,stimVariable,...
                                               Exp.behavior,...
                                               Exp.fileInfo,...
                                               Exp.spikeIndices,...
                                               runState,'ledCondition',...
                                               ledToPlot,'dataOffset',...
                                               dataOffset,...
                                               'removeSpikes',...
                                               removeSpikes);
elseif ledToPlot == 2
    cntrlMap = ePhysDataMap(Exp.data,Exp.stimulus,stimVariable,...
                                               Exp.behavior,...
                                               Exp.fileInfo,...
                                               Exp.spikeIndices,...
                                               runState,'ledCondition',...
                                               0,'dataOffset',...
                                               dataOffset,...
                                               'removeSpikes',...
                                               removeSpikes);
                                           
    ledMap = ePhysDataMap(Exp.data,Exp.stimulus,stimVariable,...
                                               Exp.behavior,...
                                               Exp.fileInfo,...
                                               Exp.spikeIndices,...
                                               runState,'ledCondition',...
                                               1,'dataOffset',...
                                               dataOffset,...
                                               'removeSpikes',...
                                               removeSpikes);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end

