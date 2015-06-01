function runningAnalyzer( dc_offset, threshold, percentage)
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
% runningAnalyzer opens an imExp and returns running information to the
% user. It is intended to provide the user with running information about
% the imExp before analysis begins.
% INPUTS:          dc_offset     

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%% LOAD DIR INFORMATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We load the ImExpDirInformation file to identify where to load imExps
% from and where to save them to once this function returns
ImExpDirInformation;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%% LOAD IMEXP %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% call uigetfile to obtain the imExpName and its filePath
[imExpName, PathName] = uigetfile(dirInfo.imExpRawFileLoc,...
                                            'MultiSelect','off');
                                        
% We will now load an imExp. Since this can take some time (some imExps
% exceed on 1GB of data) we will display a wait message during the loading
loadMsg = msgbox('LOADING SELECTED IMEXP: Please Wait...');
                                        
% now load the imExp using full-file to construct path\fileName. We will
% exclude the correctedStacks and the stackExtremas from the loading since
% they are large (>1GB) and are already saved in the imExp_Roi
imExp = load(fullfile(PathName,imExpName),'fileInfo','stimulus',...
                        'behavior', 'encoderOptions');

close(loadMsg)

% Rotate the stimulusStruct since the values will be read along rows first
% (i.e. keep the triggers in order)
stimulus = imExp.stimulus';
stimType = stimulus(1,1).Stimulus_Type;

switch stimType
    case 'Simple Center-surround Grating'
        % Obtain the matrices of angles surrConditions and run boolean
        % values stored in the imExp as an array of structures
        anglesMat = cell2mat(arrayfun(@(x)...
            num2cell(x.Center_Orientation), imExp.stimulus));
        surrCondsMat = cell2mat(arrayfun(@(x)...
            num2cell(x.Surround_Condition), imExp.stimulus));
        runMat = cell2mat(arrayfun(@(x)...
            num2cell(x.Running), imExp.behavior));
        
        % obtain all the unique angles and surroundConds
        angles = unique(anglesMat);
        surroundConds = unique(surrCondsMat);
        
        % Now we need to loop through all possible angle and surround
        % conditions and determine the indexes of a particular angle
        % surround combo (e.g. theta=270 surroundCond = 2 occurrs at index
        % 3 79 81 etc...)
        counts = [];
        for ang = 1:numel(angles)
            for surrCond = 1:numel(surroundConds)
                % get all the indices corresponding to this angle
                angIndxs = [find(anglesMat == angles(ang))];
                % get all the surrounds corresponding to this surround cond
                surrIndxs = [find(surrCondsMat == surroundConds(surrCond))];
                % now we have the indexs for a a specific angle and
                % surrConds so all we need to do is find the overlap in the
                % indices (i.e. the indices with a specific angle and
                % surrCond)
                idxs = angIndxs(ismember(angIndxs,surrIndxs));
                % and finally we retrieve the runMatrix values for these
                % indices and sum to get the counts (remember runMatrix
                % contains 1 if running and 0 otherwise)
                
                counts(sub2ind([numel(angles),...
                    numel(surroundConds)],ang,surrCond)) =...
                                                        sum(runMat(idxs));
            end
        end
        
        % Plot the counts
        bar(counts)

end

