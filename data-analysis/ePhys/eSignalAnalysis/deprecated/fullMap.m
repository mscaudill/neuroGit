function [ returnMap ] = fullMap( stimulus, stimVariable, firingRateMap,...
                                  minNumTrials )
%FULLMAP evaluates the firing rate map object for the number of trials in
%the map at each stimulus condition. In order to ensure that we have a full
%map we must have all the possible stimulus values as keys and meet the
%minimum number of trials that the user is requesting at each key
% INPUTS                        : stimulus, stimulus structure passed from
%                                 the experiment
%                               : stimVariable, the variable that was
%                                 varied (i.e. orientation)
%                               : firingRateMap, a map object constructed
%                                 from stimVariable keys
%                               : minNumTrials, the minimum number of
%                                 trials the user is requesting to be 
%                                 present in the map for each key
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
%%%%%%%%%%%%%%%%%%%%%%% FIND UNIQUE STIMULUS VALUES %%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% rotate the stimulus structure so that trigger order is preserved
stimStruct = stimulus';
% get all the stimulus values that were shown using dynamic field
% referencing
stimVals = {stimStruct(:,:).(stimVariable)};
% use the unique function to collect stimvariables
uniqueStims = unique(cell2mat(stimVals));
% remove NaNs since these never appear in a map
uniqueStims(isnan(uniqueStims))=[];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% GET THE FIRING RATES FROM THE MAP AND EVAL THE NUMBER OF TRIALS %%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get the keys from the map
keys = firingRateMap.keys;
% get the values (firingRates from the map)
firingRates = firingRateMap.values;
% get the numTrials for each firing rate array at each angle using cellfun
numTrialsArray = cellfun(@(t) numel(t), firingRates);

% Determine if any of the numTrials is less than our required minimum or if
% we lack all possible stimulus conditions (keys)
if any((numTrialsArray < minNumTrials)) || numel(keys) < numel(uniqueStims)
    % if true construct an empty return map over all stimulus values
    returnMap = containers.Map('KeyType','double', 'ValueType','any');
    for key = 1:numel(uniqueStims)
        returnMap(uniqueStims(key)) = [];
    end
else
    %else the map has the full complement of trials and is ready to be
    %processed further
    returnMap = firingRateMap;
end



end

