function [imagesMap, fluorescenceMap, runningInfo] =...
                            fluorMapV2(imExp, stimVariable, chNumber,...
                                       roi, runState)
% fluorMap constructs 2 map objects keyed on stimVariable. The first map
% object is an images map containing the images ordered by stimVariable
% taken during an imaging experiment. The second map object contains a map
% of fluorescent signals measured in the user supplied roi. These maps are
% filtered to contain images or signals that conform to the runState
% constraint.
%
% INPUTS                    : imExp, an array of structures containing all
%                             stimulus info, imageStacks, and running
%                             information for a given imaging experiment.
%                             It is the returned struct from imExpMaker
%                           : stimVariable, variable used as the key for
%                             the map object
%                           : roi, a user defined region of interest passed
%                             from the state structure of imExpAnalyzer
%                           : runState, a user defined value (0,1,2)
%                             indicating whether to include non-running 
%                             trials, running trials or both in the map 
%                             object
%
% OUTPUTS                   : imagesMap, a map object keyed on the
%                             stimVariable containing image stacks as 
%                             values
%                           : fluorescenceMap, a map object keyed on the
%                             stimvariable contating the fluorescent signal
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

% 1. if imExp contains behavior as a field then call evalRunState to obtain
%    running array
% 2. use the stimVariable to obtain the stimValues array
% 3. open the images struct to obtain a cell of all the image stacks
% 4. remove the blank trials from the run array, stimvals array and
%    imageStacks and save them
% 5. remove trials based on user defined running state
% 6. create images map
% 7. add blank images to map(inf)
% 8. check whether the roi exist
% 9.  if so construct masked images and masked blanks
% 10. call the fluorCalc to calculate fluor signals and save to map

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
% We now determine the stimulus values array by getting all the stimulus
% values present in the imExp.stimulus struct. Note if the user has asked
% for the keyword position as a stimulus variable we will make the stimulus
% variable form x,y coordinates using a linear index

% Rotate the stimulusStruct since the values will be read along rows first
% (i.e. keep the triggers in order)
stimStruct = imExp.stimulus';
% If the user has selecte a stimVariable with the keyWord position, then we
% need to construct our stimVariable from x,y coordinates. Right now the
% only stimulus which has this is the Gridded Grating stimulus
if strcmp(stimVariable,'Position') && ...
        strcmp(stimStruct(1,1).Stimulus_Type,'Gridded Grating')
    % obtain the row and coulumn indices
    rows = [stimStruct(:,:).Rows];
    cols = [stimStruct(:,:).Columns];
    % remove blanks
    rows(isnan(rows))=[];
    cols(isnan(cols)) = [];
    % call sub2ind (Matlab builtin) to obtain linear indices col major
    stimVals = sub2ind([max(rows),max(cols)], cols(:),rows(:));
else % the stimVals can be obtained directly using state.stimVariable
    stimVals = [stimStruct(:,:).(stimVariable)];
end
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%% REMOVE BLANK TRIALS %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Blank trials are indexed with a stimVal of NaN. We therefore will remove
% the blanks from runLogical, stimVals, and imagesCell. We will manually
% add these to the map objects later

% Locate the indices of the NaN (blanks)
blankIndices = find(isnan(stimVals));

% Now obtain the blank image stacks
blankStacks = {imagesCell{blankIndices}};

% Now remove the blanks from the stimVals, runLogical and the imagesCell
% Before removal create a black run logical
if exist('runLogical','var')
    blankRunLogical = runLogical(blankIndices);

    % Now remove the blank trials from runLogical
    runLogical(blankIndices) = [];
end
% Now remove the blank trials from stimVals, runLogical and the imagesCell
stimVals(blankIndices) = [];
imagesCell(blankIndices) = [];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%% REMOVE TRIALS BASED ON USER SELECTED RUNNING STATE %%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Now that the blank trials are removed we impose the running constraint                    
if runState == 1
    %if the user wants only running trials, we remove trials where animal
    %is not running from both the stimVals and images cell array
    imagesCell(~runLogical) = [];
    stimVals(~runLogical) = [];
    blankStacks(~blankRunLogical) = [];
elseif runState == 0;
    % if the user wants only non-running trials we remove running trials
    % form both the angles and images cell array
    imagesCell(runLogical) = [];
    stimVals(runLogical) = [];
    blankStacks(blankRunLogical) = [];
    % note we don't need to do anything if the running state is 2 we
    % hold on to all images and stimVals regardless of running state
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%% SAVE IMAGES TO MAP %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We are now ready to construct a map from the stimVals and images.
% Maps are objects that take a 'key' and return a 'value'. A single key may
% contain an array of values making it useful for storing multiple image
% stacks to a single angle key

% First determine all the keys that will be used in the map by finding the
% unique angles. Note returns angles in sorted order
stimKeys = unique(stimVals);

% Initialize our map, our map will have 'double' key types because the
% angles are doubles and value types of any. Note the default key type is
% 'char' but this will not work for use because we want to store multiple
% firing rates (i.e. an array) to each stimVal key (char type does not
% support this.
imagesMap = containers.Map('KeyType','double', 'ValueType','any');
% initialize all map vals to be an empty array
for key = 1:numel(stimKeys)
    imagesMap(stimKeys(key)) = [];
end

% Now loop through imagesCell adding the stimVal 'key' and image stack
% 'value' pair. Because we can have multiple values for one angle we
% concatenate. Note keys are not replicated vals associated with the same
% stimVal are assigned to the same key. That's why maps are useful

for imagesIndex = 1:numel(imagesCell)
    % get the angle associated with this firing rate index
    key = stimVals(imagesIndex);
    % now add the image stack to the map keyed on this angle
    imagesMap(key) = [imagesMap(key),...
                            imagesCell(imagesIndex)];
end

% We now need to add back in the blank images. The reason we removed them
% before making the map is because each blank (i.e. NaN) is unique whereas
% we do not distinguish between NaNs they all mean a blank trial to us
% First make sure blanks were taken
if ~isempty(blankIndices)
    imagesMap(inf) = blankStacks;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%% CONSTRUCT MASKED IMAGES FROM THE ROI %%%%%%%%%%%%%%%%%%%%% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We are now ready to construct a map of fluroescent signals if an roi has
% been supplied.
if ~isempty(roi)
    % To construct the mask, we need to determine the image dimensions of
    % the images in the stacks. We assume that all data was collected with
    % the same dimension so we can get the dimensions from the first image
    % alone
    imageDimen =...
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
    
    % now we will take our mask and construct masked images by matrix
    % multiplication (note this is why we needed to convert the type so the
    % multiplication could take place). Call cellfun to accomplish
    maskedImages = cellfun(@(x) mask.*x, imagesCell, 'UniformOutput', 0);
    
    % we must also construct a set of masked blank images
    % First make sure blanks were taken
    if ~isempty(blankIndices)
        maskedBlankImages = cellfun(@(x) mask.*x, blankStacks,...
                                'UniformOutput', 0);
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%% CONSTRUCT FLUORESCENCEMAP %%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % We are now going to construct a map to hold the fluorecent signals
    % across trials keyed on the stimVariable
    
    % call fluorCalc to calculate the percent fluorescent change signal
    % using cellfun
    fluorCell = cellfun(@(r) fluorCalc(r, imExp.stimulus(1,1).Timing,...
                                    imExp.fileInfo(1,1).imageFrameRate),...
                                    maskedImages, 'UniformOutput',0);
    
    % Do the same for the blank images
    % First make sure blanks were taken
    if ~isempty(blankIndices)
        blankFluorCell = cellfun(@(r) fluorCalc(r,...
            imExp.stimulus(1,1).Timing,...
            imExp.fileInfo(1,1).imageFrameRate),...
        maskedBlankImages, 'UniformOutput',0);
    end
    
    % we are now ready to make a map of the fluorescent signals keyed on
    % the stimVariable
    
    % Initialize our map, our map will have 'double' key types because the
    % angles are doubles and value types of any. Note the default key type
    % is 'char' but this will not work for use because we want to store
    % multiple firing rates (i.e. an array) to each stimVal key (char type
    % does not support this.
    fluorescenceMap = containers.Map('KeyType','double', 'ValueType','any');
    % initialize all map vals to be an empty array
    for key = 1:numel(stimKeys)
        fluorescenceMap(stimKeys(key)) = [];
    end
    
    % Now loop through imagesCell adding the stimVal 'key' and image stack
    % 'value' pair. Because we can have multiple values for one angle we
    % concatenate. Note keys are not replicated vals associated with the
    % same stimVal are assigned to the same key. That's why maps are useful
    
    for fluorIndex = 1:numel(fluorCell)
        % get the angle associated with this firing rate index
        key = stimVals(fluorIndex);
        % now add the fluor signal to the map keyed on this angle
        fluorescenceMap(key) = [fluorescenceMap(key),...
            fluorCell(fluorIndex)];
    end
    % We will now add the blanks into the map. Since the keys must be
    % doubles, we will define the blanks as
    % First make sure blanks were taken
    if ~isempty(blankIndices)
        fluorescenceMap(inf) = blankFluorCell;
    end
else %warndlg('No ROI Specified; Setting FluorescenceMap Empty')
    fluorescenceMap = 'No Roi Specified';
end


