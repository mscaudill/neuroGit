function ePhysCSsignalAnalyzer(varargin)
% ePhysCSsignalAnalyzer directs the user to whole-cell data and constructs
% dataMaps of the data across stimulus conditions. It then computes metrics
% about the data and saves them to the exp structure.
% INPUTS:
%               VARARGIN: 
%                          removeSpikes:   0 or 1 logical (default 1)
%                          runState:       a numeric 0, 1 or 2. Zero is
%                                          non-running trials, 1 is running
%                                          trials and 2 is all trials
%                                          (default 2)
%                           dataOffSet:    offset in mV (applied to Ic
%                                          data) in case of offset error
%                                          during collection (default 0)
%                           raPulse:       time at which a pulse arrives
%                                          for testing access resistance.
%                                          Set to empty if no pulse.
%                                          defaults to 100 ms
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
% We start by building an input parser object for the varargin  supplied to
% this function defining default values in case they are empty 
% construct a parser object (builtin matlab class)
p = inputParser;


% REMOVE SPIKES 
defRemoveSpikes = true;
% add the removeSpikes and the default value to the input parse obj. and
% validate it is a logical
addParamValue(p, 'removeSpikes',defRemoveSpikes, @islogical);

% RUN STATE
defRunState = 2;
% add the runState and the default value to the input parse obj. and
% validate that it is a 0,1,2 using anonymous function
addParamValue(p, 'runState', defRunState, @(x) ismember(x, [0,1,2]));

% DATA OFFSET
defOffset = 0;
% add the dataOffset and default value to the parse obj.
addParamValue(p, 'dataOffset', defOffset, @isnumeric);

% RA PULSE TIME
defRaTime = 0.1; % in secs
addParamValue(p, 'raPulse', defRaTime,@isnumeric);

% call the input parser method parse
parse(p,varargin{:})
% finally retrieve the variable arguments from the parsed inputs
removeSpikes = p.Results.removeSpikes;
runState = p.Results.runState;
dataOffset = p.Results.dataOffset;
raPulse = p.Results.raPulse;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%% CALL EXP LOADER %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We will now load the substructures from a Whole-cell Exp. Note we are
% using the multiExpLoader which can load multiple exps but we only take
% the first one selected since this function operates on one at a time.
% This is implicit and should be fixed by supplying MultiExpLoader with a
% variable argument that should say whether it is loading one or multiple
% exps.
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
% use the first stimulus to get the timing
stimTiming = Exp.stimulus(1,1).Timing;

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
% We now call ePhysDataMap to create our map objects. If there is an led
% present we will make two maps one for led trials and one for cntrl
% trials

% Initialize maps to be empty mapNs;
cntrlMap = MapN();
ledMap = MapN();

if ledPresence
    % create a cntrl map for non-led trials
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
    
    % create a map of data corresponding to the led trials
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

elseif ~ledPresence
    % create only a cntrlMap
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
end

% Lastly combine the maps into a single cell array
allMaps = {cntrlMap,ledMap};
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
    avgSignals{map} = cellfun(@(cond) mean(cond,2), signalMatrices{map},...
                        'UniformOut',0); 
    % now we zeroMean the data (the offset would be leak current I think)
    % we will take the signal from 0 to 95 ms as the baseline since a Ra
    % pulse arrives at 100 ms
    if ~isempty(raPulse)
        meanSignals{map} = cellfun(@(x) zeroMean(x, 'samplingFreq',...
                                samplingFreq, 'zeroingTime',...
                                [1/samplingFreq, raPulse]),...
                                avgSignals{map}, 'UniformOut',0);
    else 
        meanSignals{map} = cellfun(@(x) zeroMean(x), avgSignals{map},...
                                   'UniformOut',0);
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

assignin('base','meanSignals',meanSignals)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%% STORE EACH MAP TO THE EXP %%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Add the cntrl map
Exp.dataMaps.cntrlMap = cntrlMap;

% If an led was shown add the led map
if ledPresence
    Exp.dataMaps.ledMap = ledMap;
end

% Add the meanSignals as well (recall pos 1 wil be cntrl data and pos 2
% will be led data if present
Exp.meanSignals = meanSignals;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%% COMPUTE EPHYSIOLOGY METRICS %%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Here I need to call csNormed_PeakCurrent, csNormed_charge and 
% csNormed_F1Amp. Use switch with expType

%%%%%%%%%%%%%%%%%%%%%%%% NORMALIZED PEAK CURRENTS %%%%%%%%%%%%%%%%%%%%%%%%%
[normedCntrlCurrents,normedLedCurrents] = csNormed_peakCurrent(...
                                            Exp.meanSignals, stimTiming,...
                                            samplingFreq);
% Add this physiol metric to the exp
Exp.metrics.csNormedPeakCurrents = {normedCntrlCurrents, normedLedCurrents};

%%%%%%%%%%%%%%%%%%%%%%%%%%%% NORMALIZED CHARGES %%%%%%%%%%%%%%%%%%%%%%%%%%%
Exp.metrics.csNormedCharges = csNormedCharge(Exp.meanSignals, stimTiming,...
                                             samplingFreq);
                                         
%%%%%%%%%%%%%%%%%%%%%%%%%%% NORMALIZED F1 AMPLITUDES %%%%%%%%%%%%%%%%%%%%%%
[Exp.metrics.csNormedF1Amplitudes, Exp.metrics.csF1Fits] = ...
    csNormedF1Amplitude(Exp.meanSignals,stimTiming, ...
                        Exp.stimlus(1,1).Center_Temporal_Frequency,...
                        samplingFreq);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%% SAVE EXP_ANALYZED %%%%%%%%%%%%%%%%%%%%%%%%%%%
assignin('base','Exp_analyzed',Exp)
%expSaverFunc('',ExpName{1},Exp,'whole-cell','analyzed','Vclamp')

end

