 function [imagesMap, fluorescenceMap, runningInfo] =...
                                   csMap( imExp, chNumber, roi, runState)
% csMap constructs two map objects. imagesMap is a map of the imageStacks
% ordered by the center angle each 'value' in the map contains a cell array
% of image stacks that are ordered by the surround condition. Currently,
% the surround condition is designated as a number (1,2,3,4,5) holding the
% place of (centerAlone, cross1, cross2, iso, surroundAlone. The position
% of the stack withing the calues cell array indicates the condition. EX.
% map(225) = {{1x5},{1x5},{1x5}} represents three trials for the center 
% angle 225. In cell one of the array, position 3 would contain an image
% stack corresponding to condition #3 i.e. cross2. FluorescenceMap is
% ordered in the exact same way except that each cell contains a double
% signal array rather then an image stack. NOTE: CSMAP can handle missing
% triggers inputted from imExp as NaNs in the imExp Structure. It will 
% change the NaNs to []. In addition
% it will set non conforming running trials and blanks to [] in the maps
% as well. This is different from my previous map programs where I simply
% removed these trials all together.
%
% INPUTS                    : imExp, an array of structures containing all
%                             stimulus info, imageStacks, and running
%                             information for a given imaging experiment.
%                             It is the returned struct from imExpMaker
%                           : stimVariable, condition variable
%                           : roi, a user defined region of interest passed
%                             from the state structure of imExpAnalyzer
%                           : runState, a user defined value (0,1,2)
%                             indicating whether to include non-running 
%                             trials, running trials or both in the map 
%                             object
%
% OUTPUTS                   : imagesMap, a map object keyed on the
%                             centerAngles containing image stacks as 
%                             values
%                           : fluorescenceMap, a map object keyed on the
%                             centerAngle contating the fluorescent signal
%                             from the roi
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
%%%%%%%%%%%%%%%%%%%%%%%% OBTAIN RUN LOGICAL ARRAY %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We will check whether the behavior field is present in imExp since the
% user may have opted to not save the encoder ch in the imExpMaker. If this
% is the case and runState ~= 2, We need to warn the user that the running
% state is being ignored
if isfield(imExp,'behavior')
    [runLogical runningInfo] = evalRunState(runState,...
                                                imExp.behavior );
elseif ~isfield(imExp,'behavior') && runState ~= 2
    hwarn =...
        warndlg('No Behavior Structure in imExp, Setting Runstate to 2');
    runState = 2;
elseif ~isfield(imExp,'behavior') && runState == 2
    runningInfo = 'Not Available';
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%% OBTAIN STIMULUS VALS ARRAY %%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The stimulus 'values' for a csMap are the strings of conditions 
% {centerAlone, cross1, cross2, iso, and surroundAlone}. We will obtain
% allof these and assign an index to them so that the csMap key will be a
% number representing one of these stimuli. We will use ismember to
% accomplish
% Rotate the stimulusStruct since the values will be read along rows first
% (i.e. keep the triggers in order)
stimStruct = imExp.stimulus';
% obtain all the strings in a cell array

%OLD will be deprecated with new simple center-surround stimulus
% stimValStrs = {stimStruct(:,:).Condition};
% % now assign an index to each of the conditions
% possibleConditions = {'centerAlone', 'cross1', 'cross2', 'iso',...
%                      'surroundAlone'};
%  % The stimVals will be the indices
% [~, stimVals] = ismember(stimValStrs, possibleConditions);

%NEW
stimVals = [stimStruct(:,:).Surround_Condition];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%% OBTAIN IMAGES CELL FROM IMAGESSTRUCT %%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Now obtain the images from the correctedImages structure in Exp. We again
% rotate the structure first to keep the triggers ordered
imagesStruct =  imExp.correctedStacks';
% Use the user inputted chNumber to extract all the images for that ch to a
% cell array
imagesCell = {imagesStruct(:,:).(['Ch',num2str(chNumber)])};

% find missing triggers denoted by an NaN and replace with []
missing = cellfun(@(e) any(isnan(e(:))), imagesCell);
% 
if any(find(missing))
    imagesCell{missing} = [];
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%% REMOVE BLANK TRIALS %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Blank trials are indexed with a stimVal of NaN. If there is a blank Trial
% we will collect those image stacks in to a cell called blankStacks and
% then set the imagesCell to NaNs for those stacks

% Locate the indices of the NaN (blanks)
blankIndices = find(isnan(stimVals));

if ~isempty(blankIndices)
    
    % Now obtain the blank image stacks
    blankStacks = {imagesCell{blankIndices}};
    
    % now set the imagesCell of the blankIndices to []
    [imagesCell{blankIndices}] = deal([]);
    
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%% REMOVE NON CONFORMING RUNNING TRIALS %%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We now want to remove the running trials that do not satisfy the runState
% condition
if runState == 1
    %if the user wants only running trials, we set the trials where the
    %running condition is violated to []
    [imagesCell{~runLogical}] = deal([]);
elseif runState == 0
    % if the user wants only the non running trials then we remove all
    % running trials from the images cell array
    [imagesCell{runLogical}] = deal([]);
end % note if the user has chosen to ignore the run state nothing is to be
    % done here
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%% OBTAIN THE CENTER ANGLES OF THE STRUCTURE %%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
centerAngles = [stimStruct(:,:).Center_Orientation];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%% SORT IMAGES ACCORDING TO ANGLE AND SURROUND COND %%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We now want to sort the images according to two stimulus parameters, the
% center angle and the surround condtion. To accomplish this, we will loop
% through the angles in the experiment and obtain the indices (i.e.
% triggers) the angle was shown on. We will then look up the stimulus
% condition of this index and store to a cell array organized by condition
% numbers
% Find the unique center angles in the imExp
uniqAngles = unique(centerAngles);

% Initialize our map, our map will have 'double' key types because the
% angles are doubles and value types of any. Note the default key type is
% 'char' but this will not work for use because we want to store multiple
% cells (i.e. an array of cells) to each stimVal key (char type does not
% support this.
imagesMap = containers.Map('KeyType','double', 'ValueType','any');

% Begin the loop over the center angles
for angle = 1:numel(uniqAngles)
    % obtain the indices (triggers) this angle was shown for
    angleIndices = find(centerAngles==uniqAngles(angle));
    % now obtain the stimulus values of of these triggers
    angleStimVals = [stimVals(angleIndices)];
    % finally obtain the images from these triggers
    angleImages = {imagesCell{angleIndices}};
    
    % Now we will sort the angleImages by the angleStimVals
    [~,idxs] = sort(angleStimVals);
    angleImages = {angleImages{idxs}};
    
    % Now we will group these based on the number of trials
    numTrials = size(imExp.stimulus,1);
    numConds = numel(angleStimVals)/numTrials;
    
    groupedImages = {};

    for i =1:numConds
        groupedImages = cat(1, groupedImages, angleImages(1:numTrials));
        angleImages(1:numTrials)= [];
    end
    % Rotate to make 1 row cell of cells
    groupedImages = groupedImages';
    
    % add the grouped images to the images map
    imagesMap(uniqAngles(angle)) = groupedImages;
end

%assignin('base','imagesMap',imagesMap)
% IMAGES MAP VALIDATED 04102013

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%% CREATE MASED IMAGES FROM ROI %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We are now ready to construct a map of fluroescent signals if an roi has
% been supplied.
if ~isempty(roi)
    % To construct the mask, we need to determine the image dimensions of
    % the images in the stacks. We assume that all data was collected with
    % the same dimension so we can get the dimensions from the first image
    % alone
    imageDimen = ...
        size(imExp.correctedStacks(1,1).(['Ch',num2str(chNumber)]));
    % We start by constructing a black/white mask from the user inputted
    % roi calling the function poly2mask (matlab builtin image processing
    % toolbox)
    logicMask = poly2mask(roi(:,1), roi(:,2), imageDimen(1),imageDimen(2));
    % Now we need to recast the mask from a type logical to the type of the
    % incoming image data. We query for the class again assuming all the
    % images are of the same class (probably uint16 since this is
    % scanImages format)
    imageClass =...
        class(imExp.correctedStacks(1,1).(['Ch',num2str(chNumber)]));
    mask = cast(logicMask, imageClass);
    % now make mask the same size as the image stack along the third
    % dimension
    mask = repmat(mask,[1,1,imageDimen(3)]);


    % now we will take our mask and apply it to our images pulled from
    % images map. This is just matrix multipliation since the mask is 0
    % everywhere except in the roi region. We just need to be careful if
    % the image is a [] becasue multiplying the mask by a [] is an error
    allImages = imagesMap.values; 
    
    for angle = 1:numel(allImages)
        for stack = 1:numel(allImages{angle})
            if ~isempty(allImages{angle}{stack}) % chk if []
                maskedImages{angle}{stack} = mask.*allImages{angle}{stack};
            else
                maskedImages{angle}{stack} = [];
            end
        end
        maskedImages{angle} =...
            reshape(maskedImages{angle},numTrials,numConds);
    end
    %assignin('base','maskedImages',maskedImages)
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%% CONSTRUCT FLUORESCENCEMAP %%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % We are now going to loop over the cells (i.e. angles) of maskedImages
    % and calucalte for each angle the fluorescence in the roi. We call the
    % function fluorCalc to do this. Also note, that because each angle
    % contains trials for 5 conditions, we will use cellfun.
    for cel = 1:numel(maskedImages)
        fluorCell{cel} = cellfun(@(r) fluorCalc(r, ...
                                    imExp.stimulus(1,1).Timing,...
                                    imExp.fileInfo(1,1).imageFrameRate),...
                                    maskedImages{cel}, 'UniformOutput',0);
                                
        % reshape fluorCell{cel} back into the same shape as
        % maskedImages{cel}
        fluorCell{cel} = reshape(fluorCell{cel},numTrials,numConds);
    end
    
    % Initialize our map, our map will have 'double' key types because the
    % angles are doubles and value types of any. Note the default key type
    % is 'char' but this will not work for use because we want to store
    % multiple cells (i.e. an array of cells) to each stimVal key (char
    % type does not support this.
    fluorescenceMap = containers.Map('KeyType','double','ValueType','any');
    % initialize all map vals to be an empty array
    for key = 1:numel(uniqAngles)
        fluorescenceMap(uniqAngles(key)) = {};
    end
    
    
    for cellIndex = 1:numel(fluorCell)
        % now add the  fluorCell to the map for this angle
        fluorescenceMap(uniqAngles(cellIndex)) = ...
            [fluorescenceMap(uniqAngles(cellIndex)), fluorCell{cellIndex}];
    end
end
% fluorescence map verified 04102013

