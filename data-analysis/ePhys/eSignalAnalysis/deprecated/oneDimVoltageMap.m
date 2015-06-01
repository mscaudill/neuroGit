function [ returnMap ] = oneDimVoltageMap(data, stimulus,...
                                            stimVariable, behavior,...
                                            fileInfo, varargin)
%oneDimVoltageMap constructs a map object keyed on the stimVariable that
%contains all the data sorted by the stimVariable. 
%
% INPUTS                        :data, a substructure of electroExp
%                                containg the voltage traces recorded from
%                                a single channel
%                               :stimulus, a substructure frm electroExp
%                                containg all the stimulus information
%                               :stimVariable, the stimulus variable varied
%                                in the stimulus structure
%                               :behavior, substructure from
%                                electroExp containing animal
%                                running condition (always present in Exp)
%                               :fileInfo, substructure from electroExp
%                                containg fileInfo such as sampleRate
%                               : varagin, variable arguments in include
%                                          1. runState,an integer
%                                             deterimining whether
%                                             the map should include only
%                                             running trials, non-running
%                                             trials or both (1, 0, 2)
%                                             respectively (default 2)
%                                          2. ledCondition, a logical for
%                                             what LED condition (on/off)
%                                             should be present in the map
%                                             defaults to false.
% OUTPUTS                       : returnMap, a map object keyed on stimulus
%                                condition containing the voltages of the
%                                cell for each trial
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
% The input parser will allow the user to construct a one dimensional map
% and pass variable arguments such as behavior and ledCondition. This adds
% flexibility since these arguments do not need to be present in the
% electroExp for constructing a one D map of voltages.

% construct a parser object (builtin matlab class)
p = inputParser;

% add the required variables to the parser object and validate
addRequired(p,'data',@isstruct)
addRequired(p,'stimulus',@isstruct)

% define the expected stimVariables, these are the fieldNames present in
% the stimulus structure so use fieldnames (builtin to retrieve)
expectedStimVariables = fieldnames(stimulus);

% add required stimVariable and validate that it is one of the expected
% stimVariables
addRequired(p, 'stimVariable',...
    @(x) any(validatestring(x,expectedStimVariables)));

% add the required behavior structure
addRequired(p,'behavior',@isstruct)

% complete adding the required arguments
addRequired(p, 'fileInfo', @isstruct)

% Now construct defaults for the variable arguments in

% set the default runState of interest to 2 (meaning we don't consider
% running)
defaultRunState = 2;
%add the runningState to the params
addParamValue(p, 'runState', defaultRunState,@isnumeric)

% now add the LED condition that we want in the map, defaults to no LED
defaultLedCond = false;
addParamValue(p, 'ledCond', defaultLedCond, @islogical)

% call the input parser method parse
parse(p, data, stimulus, stimVariable,behavior, fileInfo,...
         varargin{:})

% finally retrieve the variable arguments from the parsed inputs
ledCond = p.Results.ledCond;
runState = p.Results.runState;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%% OBTAIN THE VOLTAGES FROM DATA STRUCT %%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We now pull all the voltage traces from the structure and store
% them to a cell array. (eg) if there are 3 files and 13 triggers the cell
% array will be 1x39 in size. The first 13 elements will be for file one
% the second 13 for file two and so forth. Each element is an array of
% voltages so 1 x 39 arrays of voltages.

% Our data struct is files x triggers, rotate it so we can make a
% cell that keeps all the triggers in order
dataStruct = data';

% Determine the fileType (here we assume user will enter all the same type)
fileParts = strsplit(fileInfo(1,1).dataFileName,'.');
dataType = fileParts{2};

switch dataType
    case 'daq'
        allData = {dataStruct(:,:).voltage};
    case 'abf'
        allData = {dataStruct(:,:).Electrode};
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%% CREATE A RUNLOGICAL BASED ON BEHAVIOR %%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
behaviorStruct = behavior';
runLogical = logical([behaviorStruct(:,:).Running]);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%% GET STIMVARIABLE FROM STIMULUS STRUCT %%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%                    
% Now obtain the stimVals from the stimulus structure in stimulus. We again
% rotate the structure first to keep the triggers ordered
stimStruct = stimulus';
stimVals = [stimStruct(:,:).(stimVariable)];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%% OBTAIN ALL THE LED CONDITIONS %%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We need to obtain the ledCondtion for each trial. It is located in the
% stimulus struct. We do this only if Led is a field of the stimulus
% structure. If Led_Condition is not a field of the stimulus struct,
% meaning LED was never activated then we set the ledConditions array to
% [].
if isfield(stimulus,'Led_Condition')
    ledConditions = logical([stimStruct(:,:).Led_Condition]);
else
    ledConditions = [];
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%% FILTER THE VOLTAGES BY RUN/LED %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% we now want to filter the allData cell array so that the resultant
% only includes data that meet our running condition and led
% conditions. The runLogical is a logical of whether the animal ran on a
% give trial, the runState is 0,1,2 for nonrunning, running and both
% respectively. The ledConditions can be 0,1 or empty. We construct a
% filterLogical for each case.

%CASE 1: RUNNING = 0 OR 1 AND LED WAS SHOWN
if runState ~=2 && ~isempty(ledConditions)
    filterLogical = (runLogical == runState & ledConditions == ledCond);

%CASE 2: RUNNING IS KEEP ALL AND LED WAS SHOWN
elseif runState == 2 && ~isempty(ledConditions)
    filterLogical = (ledConditions == ledCond);

% CASE 3: RUNNING = 0 OR 1 AND NO LED WAS SHOWN    
elseif runState ~=2 && isempty(ledConditions)
    filterLogical = (runLogical == runState);

% CASE 4: RUNNING IS KEEP ALL AND NO LED WAS SHOWN    
elseif runState == 2 && isempty(ledConditions)
    filterLogical = true(1,numel(stimulus));

end

% Now filter the spikeTimes and stimValse by filterLogical
filteredStimVals = stimVals(filterLogical);
filteredData = allData(filterLogical);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%% REMOVE BLANK TRIALS %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We now have stimVals and data that are filtered to meet the running
% condition and the led condition imposed by the user. So we are ready to
% remove the blank trials

% find the blank trials denoted by an NaN in the stimVals array
nans = find(isnan(filteredStimVals));

% store these spike times to a cell array to insert into the map later
blankData = filteredData(nans);

% now remove the blanks from both the stimVals and spikeIndices
filteredStimVals(nans) = [];
filteredData(nans) = [];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%% GET THE STIMULUS KEYS %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The map object that we will construct is keyed on the stimulus values. We
% get the original stimValues not the filtered one becasue the map may be
% empty for some stimVals and we want to keep all the keys
stimKeys = unique(stimVals);
% remove NaNs associated with blanks becasue the map class can't have an
% NaN key
stimKeys(isnan(stimKeys)) = [];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%% CONSTRUCT MAP CONTAINER OBJECT %%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We are now ready to construct a map from the stimVals and allData.
% Maps are objects that take a 'key' and return a 'value'. A single key may
% contain a cell of values making it useful for storing multiple times
% arrays to a single angle key. We have already determined the keys above

% Initialize our map, our map will have 'double' key types because the
% stimVals are doubles and value types of any. Note the default key type is
% 'char' but this will not work for use because we want to store multiple
% voltage arrays (i.e. a cell array) to each stimVal key (char type does
% not support this.
returnMap = containers.Map('KeyType','double', 'ValueType','any');
% initialize all map vals to be an empty array
for key = 1:numel(stimKeys)
    returnMap(stimKeys(key)) = {};
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%% ADD DATA TO MAP OBJECT %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Now loop through filteredData adding the stimVal 'key' and
% data 'value' pair. Because we can have multiple values for one
% angle we concatenate. Note keys are not replicated thus vals associated
% with the same stimVal are assigned to the same key. That's why maps are
% useful

for dataIndex = 1:numel(filteredData)
    % get the filteredStimVal associated with this spikeTime index
    key = filteredStimVals(dataIndex);
    % now add the spikeTimes array to the map keyed on this stimVal
    returnMap(key) = [returnMap(key),...
                            filteredData(dataIndex)];
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%% ADD BLANKS TO MAP %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Now we need to add the blank data to the map. Note we have already
% filtered them by running condition above. We set the key to be inf to
% distinguish it from all other parameters in the map.
if ~isempty(nans) 
    returnMap(inf) = blankData;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

end

