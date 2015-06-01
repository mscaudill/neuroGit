function ePhysSignalAnalyzer(varargin)
% ePhysSignalAnalyzer opens an eExp and generates map objects of whole-cell
% data and computes several metrics such as areas, peak Vm/I, and
% modulated Vm. It saves this data back to the eExp
% INPUTS:       varagin
%                    stimVariables cell array of variables in stimulus
% OUTPUTS:      none
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%copyright (c) 2013  Matthew Caudill
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
loadedExpCell = multiEexpLoader('wholeCell',{'data','stimulus','behavior',...
                                        'fileInfo','spikeIndices'});

Exp = loadedExpCell{1};
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%% GET STIMULUS TIMING INFORMATION %%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% For plotting the signals stored in the map we will need timing
% information and the frame rate at which the data was collected.

% use the first stimulus to get the timing
stimTiming = Exp.stimulus(1,1).Timing;

%use the first file in fileInfo to obtain the sampling rate
samplingFreq = Exp.fileInfo(1,1).samplingFreq;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%% PARSE INPUTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Construct input parser object
p = inputParser;

defaultBaseLineTimes = [stimTiming(1)-0.2,stimTiming(1)];
addParamValue(p,'baseLineTimes',defaultBaseLineTimes)

defaultStimVariables = {};
addParamValue(p,'stimVariables',defaultStimVariables);

%call the parse method to parse inputs
parse(p,varargin{:});

baseLineTimes = p.Results.baseLineTimes;
stimVariables = p.Results.stimVariables;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%% DETERMINE PUTATIVE STIMVARIABLES %%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% if the stimulus variables input is empty we attempt to identify the
% stimulus variables using autoLocateStimVariables
if isempty(stimVariables)
    stimVariables = autoLocateStimVariables(Exp.stimulus);
end
    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%% CALL EPHYSDATAMAP TO CONSTRUCT MAP OBJS %%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[dataMap, meanDataMap, dataOffset] = ePhysDataMap(Exp.data,Exp.stimulus,...
                                               stimVariables,...
                                               Exp.behavior,...
                                               Exp.fileInfo,...
                                               Exp.spikeIndices);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
assignin('base','meanDataMap',meanDataMap);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%% CALCULATE AREAS BELOW DATA IN MAP OBJS %%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
keySet = keys(dataMap);

% To calculate the areas below each of the curves in the dataMap we need to
% determine the baseline prior to the stimulus onset. Note the parser
% defaults the time of the baseline as 0.2 secs prior to the visual
% stimulation.
baseLineIndices = round(samplingFreq*baseLineTimes(1):...
                    samplingFreq*baseLineTimes(2));
% We next need the indices of when the visual stimulation was shown                
vStimIndices = round(samplingFreq*stimTiming(1):samplingFreq*...
                                          (stimTiming(1)+stimTiming(2)));
% call the function ePhysAreaCalculator
allAreas = ePhysAreaCalculator(dataMap,baseLineIndices,...
                                vStimIndices,samplingFreq);

% now create a map object of the areas
areaMap = MapN(keySet,allAreas);

assignin('base','allAreas',allAreas)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%% CALCULATE PEAK VM/PA FOR DATA IN MAP OBJS %%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
peakVoltages = peakVmCalculator(dataMap,vStimIndices);
% create a map object of peak voltages
peakVoltageMap = MapN(keySet,peakVoltages);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%% CALCULATE VM MODULATION %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


end

