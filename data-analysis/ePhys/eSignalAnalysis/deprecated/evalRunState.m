function [runLogical runningInfo] = evalRunState(runState, behavior )
%evalRunState examines the behavior strucuture of an experiment and returns
%a logical indicating whther the animal was running or not running on each
%trial within the experiment
% INPUTS                  : runState, an integer deterimining whether the
%                           map should include only running trials,
%                           non-running trials or both (1, 0, 2) 
%                           respectively
%                         : behavior, substructure imported from Exp across
%                           trigggers and trials describing the running 
%                           state
% 
% OUTPUTS                 : runLogical a logical array that is 1 x
%                           numTriggers x numfiles in length
%                         : runningInfo, a structure containing the running
%                           percentage of all trials & the total number of
%                           triggers under the fieldnames 'percentRunning' 
%                           and numTriggers.
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
% running for the orientation plot. If the user selects 0 they are
% reqeuseting only trials in which the animal is not running to be plotted.
% Finally if the user selects 2, they are requesting to ignore running and
% plot all trials in the orientation plot. We handle these three cases here

if runState == 0 || runState ==1;
    % Get the behavior substrucure from Exp structure and transpose it so
    % that triggers are now row-wise. We do this becasue we are going to
    % convert this to a cell array so that the cell will be 1 x numTriggs x
    % by num of files
    runStateStruct = behavior';
    % convert the cell array to an array
    runArray = cell2mat({runStateStruct(:,:).Running});
    % convert into a a logical for testing 
    runLogical = logical(runArray);
elseif runState == 2;
    % else if the user wants to ignore running state the run logical is
    % always true
    runStateStruct = behavior';
    % convert the cell array to an array
    runArray = cell2mat({runStateStruct(:,:).Running});
    runLogical = true(1,numel(runArray));
end

% if the user has selected either running or non running states for
% analysis we return back the percentage of all triggers in which animal
% was running in the runningInfo struct
if runState ~=2
    percentageRunning = sum(runLogical)/numel(runLogical);
    runningInfo.percentRunning = 100*percentageRunning;
    runningInfo.numTriggers = numel(runLogical);
    % otherwise we return back that running is being ignored
elseif runState == 2;
    runningInfo.percentRunning = 'Running Ignored';
    runningInfo.numTriggers = numel(runLogical);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


end

