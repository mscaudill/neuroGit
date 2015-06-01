function [imagesMap, signalMaps, runningInfo] =...
                            fluorMap(imExp, stimVariable,roiSets,...
                                     currentRoi, chNumber, runState,...
                                     neuropilMultiplier) 
% fluorMap constructs a map object called imagesMap which is  a map ( see
% containers class Matlab builtin) of all the images in the imExp keyed on
% the stimVariable. Secondly, fluorMap constructs a cell array of map
% objects (one for each roi) organized the same as roiSets. Each map object
% is a set of dFByF values for that specific roi accessed by the usual call 
% signalMaps{roiSet}{roi}. These dFByF values account for the neuropil. It
% can also account for missing triggers although on the two-photon rig this
% has never happened. Triggers inputted from imExp as NaNs in the imExp
% Structure. It will change the NaNs to []. In addition it will set non
% conforming running trials and blanks to [] in the maps as well. This is
% different from my previous map programs where I simply removed these
% trials all together.
%
% INPUTS                    : imExp, an array of structures containing all
%                             stimulus info, imageStacks, and running
%                             information for a given imaging experiment.
%                           : stimVariable, parameter being varied in the
%                             imExp.
%                           : roiSets all the rois present in the imExp
%                             being analyzed organized by {roiSets}{roi}
%                           : currentRoi, the current roi that the user
%                             would like the df/f signal for if [] then
%                             fluormap will calculate df/f for all rois in
%                             roiSets
%                           : chNum, the channel being analyzed
%                           : runState, a user defined value (0,1,2)
%                             indicating whether to include non-running 
%                             trials, running trials or both in the map 
%                             object
%                           : neuropilMultiplier, % to multiply neuropil by
%                             prior to subtracting from soma signal
%
% OUTPUTS                   : imagesMap, a map object keyed on the
%                             centerAngles containing image stacks as 
%                             values
%                           : signalsMap, a map object keyed on the
%                             stimVariable contating the fluorescent signal
%                             from the roi or all rois
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
    [runLogical, runningInfo] = evalRunState(runState,...
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
assignin('base','imagesCell',imagesCell)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% TESTING 08112014 This is where we can drop or average any frames
% for cel = 1:numel(imagesCell)
%     imagesCell{cel}(:,:,3) = (imagesCell{cel}(:,:,2)+imagesCell{cel}(:,:,end))/2;
% end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%% REMOVE BLANK TRIALS %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Blank trials are indexed with a stimVal of NaN. We therefore will remove
% the blanks from runLogical, stimVals, and imagesCell. We will manually
% add these to the map objects later

% Locate the indices of the NaN (blanks)
blankIndices = find(isnan(stimVals));

if ~isempty(blankIndices)
    % Now obtain the blank image stacks
    blankStacks = {imagesCell{blankIndices}};
    
    % Now remove the blanks from the stimVals, runLogical and the
    % imagesCell Before removal create a black run logical. Because the
    % user may want to only keep blank trials in which running occurred
    if exist('runLogical','var')
        blankRunLogical = runLogical(blankIndices);
        
        % Now remove the blank trials from runLogical
        runLogical(blankIndices) = [];
    end
    % Now remove the blank trials from stimVals, runLogical and the
    % imagesCell
    stimVals(blankIndices) = [];
    imagesCell(blankIndices) = [];
end
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
% unique stimVals. Note returns stimVals in sorted order
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
%%%%%%%%%%%%%%%% CREATE ROI LOGICAL IMAGES FOR ALL ROIS %%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We are going to create a logical image for each roi that matches the
% width and height of each of our collected data frames so first get the
% width and height of images in the imExp
imageDim = ...
        size(imExp.correctedStacks(1,1).(['Ch',num2str(chNumber)]));

% Now retrieve all the rois from the user input
% a cell of all rois
allRois = [roiSets{:}];

% convert each roi into a logical image
allRoiImages = cellfun(@(r) poly2mask(r(:,1), r(:,2), imageDim(1),...
                        imageDim(2)), allRois, 'UniformOut',0);
                    
% create a combined roi logical image. This combined image contains all
% the rois in a single logical. We are going to use this to exclude
% neuropild regions that overlap with rois in this image
comboRoiImage = logical(sum(cat(3,allRoiImages{:}),3));
%assignin('base','comboRoiLogicalImage', comboRoiLogicalImage)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%% CREATE NEUROPIL ANNULAR REGIONS FOR ALL ROIS %%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We now will create a neuropil region for each roi. To do this we will get
% the center and max radius of each roi and construct an annulus from two
% circles. The inner circle will match the max radius of the roi and the
% outer circle will be 20 um greater in diameter.

% determine the center and the radius for each of the rois
% simply take the mean of all the xs (stored in first col of each cell in
% allrois
centers = cellfun(@(g) [mean(g(:,1)), mean(g(:,2))], allRois,...
                   'UniformOut', 0);
               
% compute the radii for each roi stored in allRois
% compute as r = max(sqrt((x-x0)^2+(y-y0)^2)) where x0,y0 is the center of 
% roi
roiRadii = cellfun(@(roi,c) max(sqrt((roi(:,1)-c(1)).^2 +...
                    (roi(:,2)-c(2)).^2)), allRois, centers,'UniformOut',0);
            
% now create inner and outer circles to create an annular region
radians = linspace(0, 2*pi, 100);

innerCircles = cellfun(@(center,radius)...
    [center(1)+radius*cos(radians);center(2)+radius*sin(radians)]',...
    centers, roiRadii, 'UniformOut',0);

% create the outerCircles to be 10 pixels larger than radius (in the future
% change the additional pixels to be a faction of the roi radius itself say
% 20%.
outerCircles = cellfun(@(center,radius)...
    [center(1)+(radius+10)*cos(radians);...
    center(2) + (radius+10)*sin(radians)]',centers, roiRadii,...
    'UniformOut',0);

% finally create the neuropil annular regions by creating logical images
% for both inner and outer circles and then subtracting the inner from the
% outer to create an annulus
neuropilLogicalImages = cellfun(@(outer,inner)...
    logical(poly2mask(outer(:,1),outer(:,2),imageDim(1),...
    imageDim(2)) - poly2mask(inner(:,1),inner(:,2),imageDim(1),...
    imageDim(2))), outerCircles, innerCircles, 'UniformOut',0);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%% CALCULATE CELLULAR OVERLAP WITH NEUROPIL REGIONS %%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% calculate for each neuropil region a summed image with the
% comboRoiLogical image (contains a sum of all rois) and find the row and
% col indices of overlap (i.e. where matrix values are > 1).
% For these indices set the neuropil region to 0 
 
for region = 1:numel(neuropilLogicalImages)
    [row,col] =...
        find(neuropilLogicalImages{region}+comboRoiImage > 1);
    % set the rows and cols of overlap to 0
    neuropilLogicalImages{region}(row,col) = 0;
    % convert back to logical type
    neuropilLogicalImages{region} = logical(neuropilLogicalImages{region});
end
%assignin('base','npLogicalImages', neuropilLogicalImages)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%% CREATE COMBINED ROI AND NEUROPIL LOGICAL STACKS %%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We now have all the roiLogicals and all the neuropil logicals. The
% algortihm for computing the mean of the values in the rois-neuropil is as
% follows. First, we will create  a combination image of all the rois and
% convert it to a 3-D stack. We will then create a combination image of the
% neuropil regions and make them into a 3-D stack. Next we carry out fast
% matrix multiplication for both the comoRoiStacks and the
% neuropilComboStack with all the recorded data stacks stored in the
% imagesMap. Lastly for each roi region and neuropil region we will extract
% the values from the above product. This method limits the number of
% computations to two major multiplication steps helping the computation
% time

% create a combined neuropil logical image. This combined image contains
% all the annular neuropil regions with other cells excluded.
comboNeuropilImage = logical(sum(cat(3,neuropilLogicalImages{:}),3));

% We are now going to convert these combined images into 3-D stacks to
% multiply with each of the image stacks collected for each trigger, but
% first we need to convert them to the same class as the image stacks.
% Currently they are logicals

% obtain the image class we need to convert to (most likely uint16) for
% matrix multiplication
imageClass =...
        class(imExp.correctedStacks(1,1).(['Ch',num2str(chNumber)]));

% convert each of the roiLogicals to uint16 class matching the images
comboRoiImage = cast(comboRoiImage,imageClass);

% also convert each of the neuropil logicals
comboNeuropilImage = cast(comboNeuropilImage,imageClass);

% We will now convert the combined images into stacks for matrix
% multiplication with each stack in the imagesMap
comboRoiStack = repmat(comboRoiImage,[1,1, imageDim(3)]);
comboNeuropilStack = repmat(comboNeuropilImage, [1,1,imageDim(3)]);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MATRIX MULTI OF ROISTACKS & NEUROPIL STACKS W/ ALL IMAGES IN IMAGES MAP %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We are now ready to perform matrix multiplication of the comboRoiStack
% and comboNeuropilStack with all the images in the images map. 

% get all the images from the images map. This map contains the images for
% each trial ordered by angle. EX. 12 orienttaions and 1 blank with 8
% trials is a 13 element cell of {1x8} cells. 
allImages = imagesMap.values;

% obtain the number of conditions, in our example this is 13 angles
numConditions = numel(allImages);

% also obtain the number of trials in our example this is 8
numTrials = size(allImages{1},2);

% we now need to 'unroll' all the images into a single cell. In our above
% example we will unroll to a 8x13 cell array (trials x stimulus
% conditions)
unrolledImages = cat(1,allImages{:})';


% Now carry out the multiplications (use for loops over cellfun for speed
% boost) 
for stack = 1:numel(unrolledImages)
    roiImageStacks{stack} = comboRoiStack.*unrolledImages{stack};
    neuroImageStacks{stack} = comboNeuropilStack.*unrolledImages{stack};
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%assignin('base','roiImageStacks',roiImageStacks)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%% CALCULATE NEUROPIL SUBTRACTED SIGNAL %%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We have created roiImageStacks and neuroImageStacks. These stacks contain
% the product of the combined roiLogical and neuropil logicals with all the
% images in the imExp. Essentially we have a filtered set of images where 
% only the pixels in the rois and neuropils are non zero. We will now
% obtain the row and col indices for each roi and neuropil region and
% extract these values from each of the image stacks using fast logical
% indexing. Then we will calculate the difference between the roi and
% neuropil values and calculate dFByF.
tic
if isempty(currentRoi)
    % start by looping through each roi (same as size of allRoiImages)
    for roi = 1:numel(allRois)
        
        % create a 3-D Logical logical for each roi
        logicalRoiMat = repmat(allRoiImages{roi},[1,1,imageDim(3)]);
        logicalNeuroMat = repmat(neuropilLogicalImages{roi},...
                                [1,1,imageDim(3)]);
                            
        % now loop over the image stacks for this roi and extract the
        % submatrices 
        for imageStack = 1:numel(roiImageStacks)
            
            % use logical indexing to extract the substack corresponding to
            % this roi
            roiSubmatrix = roiImageStacks{imageStack}(logicalRoiMat);
            neuroSubmatrix = neuroImageStacks{imageStack}(logicalNeuroMat);
            
            % now above line converts to a single array. We will cou
            % reshape to a 2d matrix where each column contains all the
            % pixel values in the roi and there are imageDim(3) (numframe)
            % cols)
            roiSubmatrix = reshape(roiSubmatrix,[],imageDim(3));
            neuroSubmatrix = reshape(neuroSubmatrix,[],imageDim(3));

            fluorVals = (mean(roiSubmatrix,1))';
            
            %now take mean along rows (i.e. the mean of all the pixel
            %values for that frame in the roi) and subtract neuropil to get
            %corrected fluorVals
            corrFluorVals = (mean(roiSubmatrix,1)-...
                                neuropilMultiplier*mean(neuroSubmatrix,1))';
                            
            % Call deltaFbyF function to calculate percentage change in
            % fluorescence during visual stimulation
            dFByF{roi}{imageStack} = deltaFbyF(fluorVals,corrFluorVals,...
                imExp.stimulus(1,1).Timing,...
                imExp.fileInfo(1,1).imageFrameRate);
        end
    end
else %%%%%%%%%%%%%%%%%%%%%%%%%%% SINGLE ROI INPUT %%%%%%%%%%%%%%%%%%%%%%%%%
    % if the user has inputted a specific roi then we only need to
    % calculate the dFByF for this roi. 
    % First we need to determine the roiImage number in allRoiImages that
    % is the current roi
     roiImageNumber = find(cellfun(@(x) isequal(x,currentRoi), allRois));
 
     % locate the row,col indices for this roi
     %[roiRow,roiCol] = find(allRoiImages{roiImageNumber});
     % locate the row, col indices of the neuropil for this roi
     %[neuroRow,neuroCol] = find(neuropilLogicalImages{roiImageNumber});
     
     logicalRoiMat = repmat(allRoiImages{roiImageNumber},...
                            [1,1,imageDim(3)]);
     logicalNeuroMat = repmat(neuropilLogicalImages{roiImageNumber},...
                              [1,1,imageDim(3)]);
     
    % now loop through all the imageStacks ex. 10 trials x 8 angles x
    % 5conds = 400 images
    for imageStack = 1:numel(roiImageStacks)
        
        % extract the submstack corresponding to this roi
            roiSubmatrix = roiImageStacks{imageStack}(logicalRoiMat);
            neuroSubmatrix = neuroImageStacks{imageStack}(logicalNeuroMat);
            
            % now above line converts to a single array take mean of every
            % numFrames elements using reshape. frames will be along
            % columns. Each column will caontain all the luminance values
            % in that frame
            roiSubmatrix = reshape(roiSubmatrix,[],imageDim(3));
            neuroSubmatrix = reshape(neuroSubmatrix,[],imageDim(3));
            
            fluorVals = (mean(roiSubmatrix,1))';
            
            %now take mean along rows and subtract neuropil to get
            %corrected fluorVals
            corrFluorVals = (mean(roiSubmatrix,1)-...
                               neuropilMultiplier*mean(neuroSubmatrix,1))';
        
            % Call deltaFbyF function to calculate percentage change in
            % fluorescence during visual stimulation
            dFByF{1}{imageStack} = deltaFbyF(fluorVals, corrFluorVals,...
                imExp.stimulus(1,1).Timing,...
                imExp.fileInfo(1,1).imageFrameRate);
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%% REORGANIZE THE DFBYF CELL ARRAY %%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Our dFByF cell array is 1xnum(rois) where each roi contains ( for our
% example of 8 trials, 13 angles) a 104 element cell array containging
% doubles [1 x numFrames]. We want to reorganize the 104 element cell array
% into an 8 x 13 cell array containing [1 x numFrame] doubles

% reshape for each roi
dFByF = cellfun(@(x) reshape(x,numTrials,numConditions), dFByF,...
                'UniformOut',0);
            
%assignin('base','dFByF',dFByF)            
% now for each roi reshape the num trials x num conds cell into a
% 1 x numConds cell containing 1xnumTrials. We do this because our map to
% be created will be keyed on numConds; in our example we are changing our
% 8trials x 13 conds for each roi into a 1 x 13 condtions cell containing 
% 1x8 trials

for roi = 1:numel(dFByF)
    for cond = 1:numConditions
        fluorCell{roi}{cond} = [dFByF{roi}(:,cond)];
    end
end
%assignin('base','fluorCell', fluorCell)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%% CONSTRUCT FLUOR MAPS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We now have a cell for each roi containing 1x13 cell array where each
% element is a cell of 1x8 trials for that condition

% We will loop over the rois and create a map keyed on conditions (keys)
% containing all the trials.

% obtain all the stimulus conditions from imagesMap
keys  = cell2mat([imagesMap.keys]);

for roi = 1:numel(fluorCell)
    % initialize a map with a double key type and any value type
    fMap = containers.Map('KeyType','double','ValueType','any');
    
    % initialize the map keys as the unique stimulus conditions and the
    % values as empty cells
    for keyIndex = 1:numel(keys)
        fMap(keys(keyIndex)) = {};
    end

    % add the fluorCell to this roi fluorescence map
    for condIndex = 1:numel(fluorCell{roi})
        fMap(keys(condIndex)) = [fMap(keys(condIndex)),...
                                        fluorCell{roi}{condIndex}];
    end
    
    % lastly assign this map to the set of all fluorMaps
    fluorMaps{roi} = fMap;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
%assignin('base','fluorMaps',fluorMaps)    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%% CONSTRUCT SIGNAL MAPS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We now want to restructure the fluorMaps from a 1 x #Rois cell to a cell
% of cells matching the size and shape of roiSets. This will allow us to
% access an individual cells fMap by the usual roiSetNumber and roiNumber
% saved during the imExp construction. To do this we will loop through the
% roiSets and place the maps in the appropriate poistion of signalMaps cell
% array.

if isempty(currentRoi)
    % Create an roiCounter to keep track of how many rois we have 
    % reorganized
    roiCount = 0;
    
    for set = 1:numel(roiSets)
        for roi = 1:numel(roiSets{set})
            % make sure the set is not empty
            if ~isempty(roiSets{set})
                roiCount = roiCount + 1;
                signalMaps{set}{roi} = fluorMaps{roiCount};
            else
                signalMaps{set} = [];
            end
        end
    end
else % if the user has selected to see only the current roi then the signal
     % maps will only contain this map
    signalMaps{1} = fluorMaps{1};
end
