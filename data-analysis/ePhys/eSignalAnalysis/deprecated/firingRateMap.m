function [firingRateMap, meanSpontaneous, runningInfo ] = firingRateMap(...
                                         runState, stimVariable,...
                                         behavior, spikeIndices,...
                                         stimulus, fileInfo)
%firingRateMap constructs a map obj of firing rates for a single exp using
%the stimVariable as the map keys. (E.g. if orientation is ithe
%stimVariable of interest, a map over angles is created with 'values'
%corresponding to the firing rates of each trial) In addition it returns 
%back the spontanoues rate of fire and the percentage of triggers the 
%animal ran for in the structure runningInfo.
%
% INPUTS                : runState, an integer deterimining whether the
%                         map should include only running trials,
%                         non-running trials or both (1, 0, 2) respectively
%                       : stimVariable, the stimulus variable that will be
%                         used as the maps 'key'
%                       : behavior, substructure imported from Exp across
%                         trigggers and trials describing the running state 
%                       : spikeIndices, substructure imported from Exp
%                         containing all spike indices across triggers and
%                         trials
%                       : stimulus, substructure imported from Exp
%                         containing stimulus info
%                       : fileInfo, substructure imported from Exp
%                         containing info about the data acquistion
% OUTPUTS               : firingRateMap, a map object of firing rates for a
%                         given
%                         exp using angles for keys and values that are the
%                         firing rates for each trial in the Exp
%                       : meanSpont, the mean spontRate measured over the
%                         blank trials in the stimulus
%                       : runningInfo, a structure contating fields
%                         percentRunning and numTriggers
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
%%%%%%%%%%%%%%% CALL EVALRUNSTATE TO DETERMINE RUN STATE %%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[runLogical runningInfo] = evalRunState(runState, behavior );
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%% GET SPIKE INDICES FROM THE EXP STRUCT %%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We now pull all the spike indices from the subExp structure and store
% them to a cell array. (eg) if there are 3 files and 13 triggers the cell
% array will be 1x39 in size. The first 13 elements will be for file one
% the second 13 for file two and so forth. Each element is an array of
% spike indices so 1 x 39 arrays of spike Indices.

% Our spikeIndices struct is files x triggers, rotate it so we can make a
% cell that keeps all the triggers in order
spikeIndicesStruct = spikeIndices';
allSpikeIndices = {spikeIndicesStruct(:,:).Voltage};
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%% CALCULATE FIRING RATES %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We now obtain the firing rates for of each of the arrays in
% allSpikeIndices cell. We need the Time that the stimulus was shown and
% the sampling Rate to convert the spikeIndices to spike times in secs

% Get the array of stimulus times from subExp (wait,duration, delay) 
stimTiming = stimulus(1,1).Timing;

% construct the stimEpoch, a 2-el array, describing the stimulus onset and
% offset. not the 2nd element is the wait+duration
stimEpoch = [stimTiming(1), stimTiming(1) + stimTiming(2)];
         
% obtain the sampling freq form the exp structure. Here **I am assuming the
% sampling rate was constant across files in the particular exp.**
samplingRate = fileInfo.samplingFreq;

% Call the function firingRateFunc in general tools using cell fun to
% operate element wise and return an array
firingRates = cellfun(@(z) firingRateFunc(z,stimEpoch,samplingRate),...
                        allSpikeIndices);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%% GET STIMvARIABLE FROM EXP STRUCT %%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%                    
% Now obtain the stimVals from the stimulus structure in subExp. We again
% rotate the structure first to keep the triggers ordered
stimStruct = stimulus';
stimVals = [stimStruct(:,:).(stimVariable)];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
assignin('base','stimVals', stimVals)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%% REMOVE BLANK TRIALS & OBTAIN SPONT ACTIVITY %%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We now have all the stimVals and the firing rates stored to cells. We are
% ulimately going to make a map, a matlab object with key value pairs. But
% before we add the angles and firing rates to the map, we will need to
% remove the blank trials and then remove trials that don't conform the the
% user selected running condition.

% Find the blank trials in the stimVals array
nans = isnan(stimVals);

% Before removal calculate the mean spontaneous activity from the blanks
meanSpontaneous = mean(firingRates(nans));

% Now we remove the blank trials from the firing rates, angles and
% runLogical arrays
firingRates(nans) = [];
stimVals(nans) =[];
runLogical(nans)=[];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%% REMOVE TRIALS BASED ON USER SELECTED RUNNING STATE %%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Now that the blank trials are removed we impose the running constraint                    
if runState == 1
    %if the user wants only running trials, we remove trials where animal
    %is not running from both the stimVals and firing rates arrays
    firingRates(~runLogical) = [];
    stimVals(~runLogical) = [];
elseif runState == 0;
    % if the user wants only non-running trials we remove running trials
    % form both the angles and firing rates arrays
    firingRates(runLogical) = [];
    stimVals(runLogical) = [];
    % note we don't need to do anything if the running state is true we
    % hold on to all firing rates and stimVals regardless of running state
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%% CONSTRUCT MAP CONTAINER OBJECT %%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We are now ready to construct a map from the stimVals and firing rates.
% Maps are objects that take a 'key' and return a 'value'. A single key may
% contain an array of values making it useful for storing multiple firing
% rates to a single angle key

% First determine all the keys that will be used in the map by finding the
% unique angles. Note returns angles in sorted order
stimKeys = unique(stimVals);

% Initialize our map, our map will have 'double' key types because the
% angles are doubles and value types of any. Note the default key type is
% 'char' but this will not work for use because we want to store multiple
% firing rates (i.e. an array) to each stimVal key (char type does not
% support this.
firingRateMap = containers.Map('KeyType','double', 'ValueType','any');
% initialize all map vals to be an empty array
for key = 1:numel(stimKeys)
    firingRateMap(stimKeys(key)) = [];
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%% ADD FIRING RATES TO MAP OBJECT %%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Now loop through firing rates adding the stimVal 'key' and firing rate
% 'value' pair. Because we can have multiple values for one angle we
% concatenate. Note keys are not replicated vals associated with the same
% stimVal are assigned to the same key. That's why maps are useful

for firingRateIndex = 1:numel(firingRates)
    % get the angle associated with this firing rate index
    key = stimVals(firingRateIndex);
    % now add the firing rate to the map keyed on this angle
    firingRateMap(key) = [firingRateMap(key),...
                            firingRates(firingRateIndex)];
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

end

