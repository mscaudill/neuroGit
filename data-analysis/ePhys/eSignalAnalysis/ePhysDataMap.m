function [returnMap, meanReturnMap, dataOffset] = ePhysDataMap(data,...
                                            stimulus,...
                                            stimVariables, behavior,...
                                            fileInfo,spikeIndices,...
                                            varargin)
%ePhysDataMap constructs a map object keyed on one or two stimVariables
%containing all the data specified by data input. NOTE this function
%deprecates oneDimVoltageMapper
%
% INPUTS                        :data, a substructure of electroExp
%                                containg the voltage traces recorded from
%                                a single channel
%                               :stimulus, a substructure frm electroExp
%                                containg all the stimulus information
%                               :stimVariables, cell of stimuli variable 
%                                strings varied in the stimulus structure
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
%                                          3. dataOffset, dc offset for
%                                             data if pipette offset was 
%                                             incorrectly adj. during exp
%                                             Defaults to 0.
%                                          4. removeSpikes,logical to
%                                             specify if to remove spikes
% OUTPUTS                       : returnMap, a map object keyed on the
%                                 first stimulus variable that contains 
%                                 maps keyed on the second variable (EX.
%                                 for gridded gratings the variables are
%                                 position and angle. The return map is a
%                                 map keyed on position where each value is
%                                 itself a map keyed on angle
%                               : meanReturnMap, a map of the mean signals
%                                 averaged across trials for each stimulus
%                                 condition
%                               : dataOffset, dc shift in data applied in
%                                 map
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
% The input parser will allow the user to construct a two dimensional map
% and pass variable arguments such as behavior and ledCondition. This adds
% flexibility since these arguments do not need to be present in the
% electroExp for constructing a two-D map of voltages.

% construct a parser object (builtin matlab class)
p = inputParser;

% add the required variables to the parser object and validate
addRequired(p,'data',@isstruct)
addRequired(p,'stimulus',@isstruct)

% define the expected stimVariables, these are the fieldNames present in
% the stimulus structure so use fieldnames (builtin to retrieve). 
expectedStimVariables = fieldnames(stimulus);

% add required stimVariables and validate that each is one of the expected
% stimVariables
addRequired(p, 'stimVariables',...
        @(x) all(ismember(x,expectedStimVariables)));


% add the required behavior structure
addRequired(p,'behavior',@isstruct)

% complete adding the required arguments
addRequired(p, 'fileInfo', @isstruct)

% add the required spikeIndices
addRequired(p,'spikeIndices',@isstruct)


% Optional arguments (varargins)
% set the default runState of interest to 2 (meaning we don't consider
% running)
defaultRunState = 2;
%add the runningState to the params
addParamValue(p, 'runState', defaultRunState,@isnumeric)

% now add the LED condition that we want in the map, defaults to no LED
defaultLedCond = 0;
addParamValue(p, 'ledCond', defaultLedCond, @(x) ismember(x,[0,1,2]));

% add the parameter dataOffset (default is 0mV/pA)
defaultDataOffset = 0; 
addParamValue(p,'dataOffset',defaultDataOffset,@isnumeric)

%add the parameter remove spikes (default is to remove spikes)
defaultRemoveSpikes = true;
addParamValue(p,'removeSpikes',defaultRemoveSpikes,@islogical)

% call the input parser method parse
parse(p, data, stimulus, stimVariables, behavior, fileInfo,spikeIndices,...
         varargin{:})

% finally retrieve the variable arguments from the parsed inputs
ledCond = p.Results.ledCond;
runState = p.Results.runState;
dataOffset = p.Results.dataOffset;
removeSpikes = p.Results.removeSpikes;
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
%%%%%%%%%%%%%%%%%% REMOVE SPIKES FROM DATA (IF APPLICABLE)%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if removeSpikes
    % if the user has selected to remove the spikes then we will use the
    % spikeIndices structure to remove the spikes from all data rotate the
    % spikeIndices struct so that triggers are along rows (since matlab
    % reads structures as row major)
    spikesStruct = spikeIndices';
    % concatenate each of the spikeIndices arrays for the Electrode channel
    % together into a cell array
    switch dataType
        case 'daq'
            allSpikes = {spikesStruct(:,:).voltage};
        case 'abf'
            allSpikes = {spikesStruct(:,:).Electrode};
    end    
    %call the function spikeRemoveal to remove the spikes in allData
    allData = cellfun(@(x,y) spikeRemoval(x,y,fileInfo(1,1).samplingFreq),...
        allData, allSpikes,'UniformOut',0);
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
% We have multiple stimVariables so for each we get the stimValues and
% store to a cell array
for stimVar = 1: numel(stimVariables)
    stimVals{stimVar} = [stimStruct(:,:).(stimVariables{stimVar})];
end
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

% Now we will filter each of the stimVals arrays and allData
filteredStimVals = cellfun(@(x) x(filterLogical), stimVals, 'UniformOut',0);
filteredData = allData(filterLogical);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%% REMOVE BLANK TRIALS %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We now have stimVals and data that are filtered to meet the running
% condition and the led condition imposed by the user. So we are ready to
% remove the blank trials

% find the blank trials denoted by an NaN in the stimVals array. We can
% take just the first set of stimVals to locate the NANs present in all the
% stimVals
nans = find(isnan(filteredStimVals{1}));

% store these datas to a cell array to insert into the map later
blankData = filteredData(nans);

% now remove the blanks from both the stimVals and data
for valArray = 1:numel(filteredStimVals)
    filteredStimVals{valArray}(nans) = [];
end

filteredData(nans) = [];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%% APPLY DATA OFFSET (IF APPLICABLE)%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
filteredData = cellfun(@(x) x - dataOffset, filteredData,'UniformOut',0);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%% GET THE STIMULUS KEYS %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The map object that we will construct is keyed the stimulus values. This
% will require us to get the keys for each stimVariable
stimKeys = cellfun(@(x) unique(x), filteredStimVals, 'UniformOut',0);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%% COMBINE STIMKEYS IF POSITIONAL %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% For some stimuli (ex gridded grating) the stimvariables will include
% positional variables such as rows and columns. These variables can be
% collapsed into a single positional variable. We will do this using
% Matlabs row major convention
if any(strcmp('Rows',stimVariables)|strcmp('Columns',stimVariables));

    % Create a logical of the stimKeys that contain positions (e. if
    % stimVars is {Orientation, rows, columns} we return [0 1 1]
    LogicalPosVars = ...
        strcmp('Rows',stimVariables)|strcmp('Columns',stimVariables);
    
    % use find to determine the nonzero elements of LogicPosVars. Should be
    % two
    idxs = find(LogicalPosVars);
    
    % combine the row and column indices into a single positional linear
    % index that follows matlabs row major convention
    positions = sub2ind([max(stimKeys{idxs(1)}),max(stimKeys{idxs(1)})],...
                        filteredStimVals{idxs(1)},...
                        filteredStimVals{idxs(2)});
                    
    % now create a new filtered stimVals cell array where the elements are
    % {[positions], [nonPositionStimValues]}
    filteredStimVals = [positions,filteredStimVals(~LogicalPosVars)];
                                
                            
    positionKeys = unique(positions);
    
    % Now combine the nonpositional stimKeys with the new positions keySet.
    % Note we have position alwas superceeding all other stimVariables in
    % order. So maps will always be keyed first on position then other
    % variables
    stimKeys = [positionKeys, stimKeys(~LogicalPosVars)];
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%% CONSTRUCT MAP CONTAINER OBJECTS %%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We are now ready to construct the maps that will hold the voltage data. 
% Maps are objects that take a 'key' and return a 'value'. We will use a
% modified version taht allows for multiple keys. This class pulled off
% the file exchange written by D Young will allow us to store data to
% multidimesional key sets. It is called MapN

% Construct the map object
returnMap = MapN();


switch numel(stimKeys)
    % case 1 there is only one stimulus variable so we create a one
    % dimensional returnMap, ssign it empty cells, then concetenate data in
    % to the map
    case 1
        %initialize the map values to be empty cells
        for key = 1:numel(stimKeys{1})
            returnMap(stimKeys{1}(key)) = {};
        end
        % now pull the data and associated key and store them to the map
        for dataIndex = 1:numel(filteredData)
            % get the key that goes with this data
            key = filteredStimVals{1}(dataIndex);
            %add the key and data to the map
            returnMap(key) = [returnMap(key),...
                                filteredData(dataIndex)];
        end
        
        
    % If there are two keys ( a position key and a non positional key such
    % as position and orientation for a gridded grating) we loop over the
    % positional and non positional keys and intialize the map to be empty
    % then fill the map with filtered data
    case 2
        % initialize our two dimensional map
        for stimIndex = 1:numel(filteredStimVals{1})
            returnMap(filteredStimVals{1}(stimIndex),...
                filteredStimVals{2}(stimIndex)) = {};
        end
        
        % now pull the data and associated stim Values 
        for dataIndex = 1:numel(filteredData)
            % get the two keys associated with this data
            keyPair = [filteredStimVals{1}(dataIndex),...
                    filteredStimVals{2}(dataIndex)];
            % now add the key pair and value of data to the map
            returnMap(keyPair(1),keyPair(2)) = [returnMap(keyPair(1),...
                                                keyPair(2)),...
                                                filteredData(dataIndex)];
         
        end
end
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%% ADD BLANKS TO MAP %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Now we need to add the blank data to the map. Note we have already
% filtered them by running condition above. We set the key to be inf to
% distinguish it from all other parameters in the map. We also subtract the
% dataOffset from each blank trace using cellfun
if ~isempty(nans) 
    switch numel(stimKeys)
        case 1
            returnMap(inf) = cellfun(@(x) x-dataOffset, blankData,...
                                     'UniformOut',0);
        case 2
            returnMap(inf,inf) = cellfun(@(x) x-dataOffset, blankData,...
                                         'UniformOut',0);
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%% CREATE THE MEAN RETURN MAP OBJECT %%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We now want to compute the mean sighnals for each condition present in
% map and return these. We obtain the keys and signals present in the
% dataMap. Note we are using the methods of the MapN class written by D
% Young on the file exchange. Obtain the keys of the map
keySet = keys(returnMap);
% Signals will be a cell of cells where each inner cell contains a set of
% arrays for that key
signals = values(returnMap);

%%%%%%%%%%%%%%%%%%%%%%%% RESHAPE SIGNALS FOR PLOTTING %%%%%%%%%%%%%%%%%%%%%
% Signals is a cell array of cells where each inner cell contains arrays
% corresponding to each trial for that condition. For example if you ran 9
% positions and 8 angles and 18 trials then signals{1} is cell array
% containing 18 arrays. The {1} signifies condition 1. This condition would
% be the first position and the first angle. signals{2} is the first
% position and the second angle (i.e. positions change slowest). We will
% convert the arrays for each condition (i.e. all trials for a particular
% position/orientation pair) and make them into matrices where data points
% are along rows and trials are along columns. We do this using a nested
% cell function
signalMatrices = cellfun(@(trial) cat(2,trial{1:end}),...
                        cellfun(@(cond) cond, signals,...
                        'UniformOut',0), 'UniformOut',0);
                    
%%%%%%%%%%%%%%%% COMPUTE THE MEAN SIGNAL FOR EACH COND %%%%%%%%%%%%%%%%%%%%
% We use cell fun over the conditions to compute the mean across columns
meanSignals = cellfun(@(cond) mean(cond,2), signalMatrices,...
                        'UniformOut',0)';

%%%%%%%%%%%%%%%%%%% FINALLY CREATE A MAP OF MEAN SIGNALS %%%%%%%%%%%%%%%%%%
% Construct the map object by passing the full keylist and the already
% sorted mean signals. Please see MapN class for more details.
meanReturnMap = MapN(keySet,meanSignals);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



end

