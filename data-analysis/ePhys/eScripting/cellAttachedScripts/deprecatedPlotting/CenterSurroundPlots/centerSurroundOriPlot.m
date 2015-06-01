function centerSurroundOriPlot(runState, varargin)
% centerSurroundPlot constructs a plot of of center surround firing rates
% as a function of the difference between the center stimulus angle and the
% surround stimulus angle for a single experiment
% INPUTS
%           runState            : integer to seperate trials based on
%                                 running behavior (1 = yes, 0 = No, 
%                                 2= Keep ALL)
%           varargin            : save, a logical to determine
%                                 whether to open a save dialog box, 
%                                 defaults to false
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
defaultSave = false;

% Add all requried and optional args to the input parser object
addRequired(inputParseStruct,'runState',@isnumeric);
addParamValue(inputParseStruct,'save',defaultSave,@islogical);

% call the parser
parse(inputParseStruct,runState,varargin{:})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%% LOAD FIELDS FROM EXP TO SUBEXP %%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We call the function dialogLoadExp to load the specific fields from the
% exp structure. This save considerable computation time becasue the exp
% structure can be very large.
% We need the behavior to evaluate running, spikeIndices to get a firing
% rate, the stimulus to get the orientationS, and the fileInfo for sample
% rate of the data

subExp = dialogLoadExp('behavior', 'spikeIndices', 'stimulus', 'fileInfo');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%% CALL ORIENTATION MAP FUNC TO CONSTRUCT MAP OBJ %%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% we will now call the function firingRateMap which constructs a map object
% of firing rates 'keyed' on stimulus surround orientations. Running state
% is passed to this function to return a map that meets the user definded
% running state condition ( see inputs above)
[csMap, meanSpont, runStateInfo] = firingRateMap(runState,...
                            'Surround_Orientation', subExp.behavior,...
                            subExp.spikeIndices, subExp.stimulus,...
                            subExp.fileInfo);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

assignin('base','csMap',csMap);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% CALCULATE MEAN + STD OF FIRING RATES ACROSS SURROUND ORIENTATIONS %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
FiringRates = csMap.values;

meanFiringRates = cellfun(@(x) mean(x),FiringRates);
stdevFiringRates = cellfun(@(y) std(y),FiringRates);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

angles = cell2mat(csMap.keys);

hE = errorbar(angles, meanFiringRates, stdevFiringRates);
hold on
hSpont = plot([0 330], [meanSpont, meanSpont]);

% still need to determine the center orientation and align the meanfiring
% rates to this angle before plotting for an easier to read graph
end

