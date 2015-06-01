function [spikeTimesMap, runningInfo ] = spikeTimesMap(...
                                          runState, stimVariable,...
                                          behavior, spikeIndices,...
                                          stimulus, fileInfo)
%spikeTimesMap constructs a map obj of spike times for a single exp using
%the stimVariable as the map keys. (E.g. if orientation is ithe
%stimVariable of interest, a map over angles is created with 'values'
%corresponding to arrays of spike times of each trial). Additionally it
%returns back the spontanoues rate of fire and the percentage of triggers
%the animal ran for in the structure runningInfo.
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
% OUTPUTS               : spikeTimesMap, a map object of firing rates for 
%                         a given exp using angles for keys and values that
%                         are the spikeTimes array for each trial in the 
%                         Exp (spike times are in secs)
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
%%%%%%%%%%%%%%%%%%% GET STIMVARIABLE FROM EXP STRUCT %%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%                    
% Now obtain the angles from the stimulus structure in subExp. We again
% rotate the structure first to keep the triggers ordered
stimStruct = stimulus';
stimVals = [stimStruct(:,:).(stimVariable)];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%% REMOVE BLANK TRIALS & OBTAIN SPONT ACTIVITY %%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We now have all the stims and the spikeIndices stored to cells. We are
% ulimately going to make a map, a matlab object with key value pairs. But
% before we add the stimVars and spikeTimes to the map, we will need to
% remove the blank trials and then remove trials that don't conform the the
% user selected running condition.

% Find the blank trials in the stimVals array
nans = isnan(stimVals);


% Now we remove the blank trials from the spikeTimes, stimVals and
% runLogical arrays
allSpikeIndices(nans) = [];
stimVals(nans) =[];
runLogical(nans)=[];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%% REMOVE TRIALS BASED ON USER SELECTED RUNNING STATE %%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Now that the blank trials are removed we impose the running constraint                    
if runState == 1
    %if the user wants only running trials, we remove trials where animal
    %is not running from both the stimVals and spikeTimes arrays
    allSpikeIndices(~runLogical) = [];
    stimVals(~runLogical) = [];
elseif runState == 0;
    % if the user wants only non-running trials we remove running trials
    % form both the stimVals and spikeTimes arrays
    allSpikeIndices(runLogical) = [];
    stimVals(runLogical) = [];
    % note we don't need to do anything if the running state is true we
    % hold on to all spikeTimes and stimVals regardless of running state
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%% CONVERT SPIKE INDICES TO SPIKE TIMES %%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Our spikes are given as an index based on the sampling rate of acquired
% data so we now convert it the spikeIndices to spikeTimes.
% obtain the sampling freq form the exp structure. Here **I am assuming the
% sampling rate was constant across files in the particular exp.**
samplingRate = fileInfo.samplingFreq;

% use cellfun to convert each array of indices to arrays of spikeTimes
spikeTimes = cellfun(@(s) s./samplingRate, allSpikeIndices,...
                    'UniformOutput',0);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%% CONSTRUCT MAP CONTAINER OBJECT %%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We are now ready to construct a map from the stimVals and spikeTimes.
% Maps are objects that take a 'key' and return a 'value'. A single key may
% contain an array of values making it useful for storing multiple 
% spikeTimes arrays to a single angle key

% First determine all the keys that will be used in the map by finding the
% unique angles. Note returns angles in sorted order
stimKeys = unique(stimVals);

% Initialize our map, our map will have 'double' key types because the
% stimVlas are doubles and value types of any. Note the default key type is
% 'char' but this will not work for use because we want to store multiple
% spikeTimes (i.e. arrays) to each stimVal key (char type does not
% support this.
spikeTimesMap = containers.Map('KeyType','double', 'ValueType','any');
% initialize all map vals to be an empty array
for key = 1:numel(stimKeys)
    spikeTimesMap(stimKeys(key)) = [];
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%% ADD FIRING RATES TO MAP OBJECT %%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Now loop through spikeTimes cell adding the stimVal 'key' and spikeTimes
% 'value' pair. Because we can have multiple values for one stimVal we
% concatenate. Note keys are not replicated vals associated with the same
% stimVal are assigned to the same key. That's why maps are useful

for spikeArrayIndex = 1:numel(spikeTimes)
    % get the stimVal associated with this spikeTimes index
    key = stimVals(spikeArrayIndex);
    % now add the spikeTimes to the map keyed on this stimVal
    spikeTimesMap(key) = [spikeTimesMap(key),...
                            spikeTimes(spikeArrayIndex)];
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

end

