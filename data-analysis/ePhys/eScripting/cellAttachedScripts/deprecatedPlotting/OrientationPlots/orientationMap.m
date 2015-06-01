function [oriMap, meanSpontaneous, runningInfo]= orientationMap(running,...
                                        behavior, spikeIndices,...
                                        stimulus, fileInfo )
%orientationMap constructs a map object of firing rates for a single Exp
%using angles as the map keys. It uses the user defined running state to 
%determine which triggers of data should be included in the map. In
%addition it returns back the spontanoues rate of fire and the percentage
%of triggers the animal ran for in the structure runningInfo
%
% INPUTS                : runningState, an integer deterimining whether the
%                         map should include only running trials,
%                         non-running trials or both (1, 0, 2) respectively
%                       : behavior, substructure imported from Exp across
%                         trigggers and trials describing the running state 
%                       : spikeIndices, substructure imported from Exp
%                         containing all spike indices across triggers and
%                         trials
%                       : stimulus, substructure imported from Exp
%                         containing stimulus info
%                       : fileInfo, substructure imported from Exp
%                         containing info about the data acquistion
% OUTPUTS               : oriMap, a map object of firing rates for a given
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
% Further Explanantion
% The layout of this program is to determine for each trial and trigger in
% Exp struct the running state, obtain firing rates from the spikes in Exp,
%obtain angles from Exp struct, remove blanks from trials and calculate
%spont activity during blanks, remove trials based on running state user
%choice and finally add angles and firning rates to the orientation map
%object

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%% DETERMINE RUNNING STATE %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The user can select from three options in the run parameter. If the user 
% selects 1 then they are requesting only trials in which the animal is
% running for the orientation plot. If the user selects 0 they are
% reqeuseting only trials in which the animal is not running to be plotted.
% Finally if the user selects 2, they are requesting to ignore running and
% plot all trials in the orientation plot. We handle these three cases here

if running == 0 || running ==1;
    % Get the behavior substrucure from Exp structure and transpose it so
    % that triggers are now row-wise. We do this becasue we are going to
    % convert this to a cell array so that the cell will be 1 x numTriggs x
    % by num of files
    runningStruct = behavior';
    % convert the cell array to an array
    runArray = cell2mat({runningStruct(:,:).Running});
    % convert into a a logical for testing 
    runLogical = logical(runArray);
elseif running == 2;
    % else if the user wants to ignore running state the run logical is
    % always true
    runningStruct = behavior';
    % convert the cell array to an array
    runArray = cell2mat({runningStruct(:,:).Running});
    runLogical = true(1,numel(runArray));
end

% if the user has selected either running or non running states for
% analysis we return back the percentage of all triggers in which animal
% was running
if running ~=2
    percentageRunning = sum(runLogical)/numel(runLogical);
    runningInfo.percentRunning = 100*percentageRunning;
    runningInfo.numTriggers = numel(runLogical);
    % otherwise we return back that running is being ignored
elseif running == 2;
    runningInfo.percentRunning = 'Running Ignored';
    runningInfo.numTriggers = numel(runLogical);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%% GET SPIKE INDICES FROM THE EXP STRUCT %%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We now pull all the spike indices from the subExp structure and store
% them to a cell array. (eg) if there are 3 files and 13 triggers the cell
% array will be 1x39 in size. The first 13 elements will be for file one
% the second 13 for file two and so forth

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
%%%%%%%%%%%%%%%%%%%%%% GET ANGLES FROM EXP STRUCT %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%                    
% Now obtain the angles from the stimulus structure in subExp. We again
% rotate the structure first to keep the triggers ordered
stimStruct = stimulus';
angles = [stimStruct(:,:).Orientation];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%% REMOVE BLANK TRIALS & OBTAIN SPONT ACTIVITY %%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We now have all the angles and the firing rates stored to cells. We are
% ulimately going to make a map, a matlab object with key value pairs. But
% before we add the angles and firing rates to the map, we will need to
% remove the blank trials and then remove trials that don't conform the the
% user selected running condition.

% Find the blank trials in the angles array
nans = isnan(angles);

% Before removal calculate the mean spontaneous activity from the blanks
meanSpontaneous = mean(firingRates(nans));

% Now we remove the blank trials from the firing rates, angles and
% runLogical arrays
firingRates(nans) = [];
angles(nans) =[];
runLogical(nans)=[];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%% REMOVE TRIALS BASED ON USER SELECTED RUNNING STATE %%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Now that the blank trials are removed we impose the running constraint                    
if running == 1
    %if the user wants only running trials, we remove trials where animal
    %is not running from both the anlges and firing rates arrays
    firingRates(~runLogical) = [];
    angles(~runLogical) = [];
elseif running == 0;
    % if the user wants only non-running trials we remove running trials
    % form both the angles and firing rates arrays
    firingRates(runLogical) = [];
    angles(runLogical) = [];
    % note we don't need to do anything if the running state is true we
    % hold on to all firing rates and angles regardless of running state
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%% CONSTRUCT MAP CONTAINER OBJECT %%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We are now ready to construct a map from the angles and the firing rates.
% Maps are objects that take a 'key' and return a 'value'. A single key may
% contain an array of values making it useful for storing multiple firing
% rates to a single angle key

% First determine all the keys that will be used in the map by finding the
% unique angles. Note returns angles in sorted order
angleKeys = unique(angles);

% Initialize our map, our map will have 'double' key types because the
% angles are doubles and value types of any. Note the default key type is
% 'char' but this will not work for use because we want to store multiple
% firing rates (i.e. an array) to each angle key (char type does not
% support this.
oriMap = containers.Map('KeyType','double', 'ValueType','any');
% initialize all map vals to be an empty array
for key = 1:numel(angleKeys)
    oriMap(angleKeys(key)) = [];
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%% ADD FIRING RATES TO MAP OBJECT %%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Now loop through the firing rates adding the angle 'key' and firing rate
% 'value' pair. Because we can have multiple values for one angle we
% concatenate. Note keys are not replicated vals associated with the same
% anlge are assigned to the same key. That's why maps are useful

for firingRateIndex = 1:numel(firingRates)
    % get the angle associated with this firing rate index
    key = angles(firingRateIndex);
    % now add the firing rate to the map keyed on this angle
    oriMap(key) = [oriMap(key),...
                            firingRates(firingRateIndex)];
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end

