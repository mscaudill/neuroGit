function [ oriDataMap ] = oriDataMap(running, behavior, data, stimulus)
%ORIDATAMAP Summary of this function goes here
%   Detailed explanation goes here
% INPUTS                : runningState, an integer deterimining whether the
%                         map should include only running trials,
%                         non-running trials or both (1, 0, 2) respectively
%                       : behavior, substructure imported from Exp across
%                         trigggers and trials describing the running state 
%                       : data, substructure imported from Exp
%                         containing all coltage across triggers and
%                         trials
%                       : stimulus, substructure imported from Exp
%                         containing stimulus info
%                       : fileInfo, substructure imported from Exp
%                         containing info about the data acquistion
% OUTPUTS               : oriDataMap, a map object of data for a given
%                         exp using angles for keys and values that are the
%                         sets for each trial in the Exp
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
%%%%%%%%%%%%%%%%%%%%%%% DETERMINE RUNNING STATE %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The user can select from three options in the run parameter. If the user 
% selects 1 then they are requesting only trials in which the animal is
% running for the data plot. If the user selects 0 they are
% reqeuseting only trials in which the animal is not running to be plotted.
% Finally if the user selects 2, they are requesting to ignore running and
% plot all trials in the data plot. We handle these three cases here

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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%% OBTAIN DATA TRACES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Now obtain each data trace from the data structure. Note we rotate again
% to keep the triggers aligned
dataStruct = data';
data = {dataStruct(:,:).Voltage};

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
%meanSpontaneous = mean(firingRates(nans));

% Now we remove the blank trials from the data cell array, angles and
% runLogical arrays
data(nans) = [];
angles(nans) =[];
runLogical(nans)=[];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%% REMOVE TRIALS BASED ON USER SELECTED RUNNING STATE %%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Now that the blank trials are removed we impose the running constraint                    
if running == 1
    %if the user wants only running trials, we remove trials where animal
    %is not running from both the anlges and data cell array
    data(~runLogical) = [];
    angles(~runLogical) = [];
elseif running == 0;
    % if the user wants only non-running trials we remove running trials
    % form both the angles and data cell array
    data(runLogical) = [];
    angles(runLogical) = [];
    % note we don't need to do anything if the running state is true we
    % hold on to all data and angles regardless of running state
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
% unique angles. 
angleKeys = unique(angles);

% Initialize our map, our map will have 'double' key types because the
% angles are doubles and value types of any. Note the default key type is
% 'char' but this will not work for use because we want to store multiple
% firing rates (i.e. an array) to each angle key (char type does not
% support this.
oriDataMap = containers.Map('KeyType','double', 'ValueType','any');
% initialize all map vals to be an empty array
for key = 1:numel(angleKeys)
    oriDataMap(angleKeys(key)) = [];
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%% ADD DATA TRACES TO MAP OBJECT %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Now loop through the firing rates adding the angle 'key' and firing rate
% 'value' pair. Because we can have multiple values for one angle we
% concatenate. Note keys are not replicated vals associated with the same
% anlge are assigned to the same key. That's why maps are useful

for dataTraceIndex = 1:numel(data)
    % get the angle associated with this firing rate index
    key = angles(dataTraceIndex);
    % now add the firing rate to the map keyed on this angle
    oriDataMap(key) = [oriDataMap(key),...
                            data(dataTraceIndex)];
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
assignin('base', 'oriDataMap', oriDataMap)
end

