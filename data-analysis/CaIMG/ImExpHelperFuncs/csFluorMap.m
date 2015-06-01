function [imagesMap, signalMaps, runningInfo] = csFluorMap(imExp,...
                                            roiSets,currentRoi, chNum,...
                                            runState, neuropilRatio)
% csFluroMap constructs two map objects. The first is a map of all the 
% images present in the imExp keyed on center angles. The values for each 
% map angle is a numTrials x numSurroundConds cell array. The surround 
% conds (columns) are ordered as (center alone, cross 1 cross2 iso 
% surround alone). The second map is a map of fluorescent signals. These 
% signals are ordered in the same manner as the imagesMap. The signals can
% be neuropil subtracted depending on the ratio input. The function can
% also compute the fluorescent map for a single roi or all rois in the
% imExp depending on whether the current roi is empty.
% NOTE: CSMAP can handle missing
% triggers inputted from imExp as NaNs in the imExp Structure. It will 
% change the NaNs to []. In addition
% it will set non conforming running trials and blanks to [] in the maps
% as well. This is different from my previous map programs where I simply
% removed these trials all together.
%
% INPUTS                    : imExp, an array of structures containing all
%                             stimulus info, imageStacks, and running
%                             information for a given imaging experiment.
%                           : roiSets all the rois present in the imExp
%                             being analyzed
%                           : currentRoi, the current roi that the user
%                             would like the df/f signal for (can be [])
%                             It is the returned struct from imExpMaker
%                           : chNum, the channel being analyzed
%                           : runState, a user defined value (0,1,2)
%                             indicating whether to include non-running 
%                             trials, running trials or both in the map 
%                             object
%                           : neuropil ratio, % to multiply neuropil by
%                             prior to subtracting from soma signal
%
% OUTPUTS                   : imagesMap, a map object keyed on the
%                             centerAngles containing image stacks as 
%                             values
%                           : fluorescenceMap, a map object keyed on the
%                             centerAngle contating the fluorescent signal
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
% The stimulus 'values' for a csFluorMap are numbers 1:5 representing in
% order the following surround conditions {center alone, cross1 cross2 iso,
% and surround alone}
% Rotate the stimulusStruct since the values will be read along rows first
% (i.e. keep the triggers in order)
stimStruct = imExp.stimulus';

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
imagesCell = {imagesStruct(:,:).(['Ch',num2str(chNum)])};

% find missing triggers denoted by an NaN and replace with []. Note missing
% image stacks due to trigger misses have not been found to occur on the
% 2-photon setup, but just in case.

for cell = 1:numel(imagesCell)
    if isnan(imagesCell{cell})
        imagesCell{cell} = [];
    end
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
    
    % now set the imagesCell and stimVals of the blankIndices to []
    stimVals(blankIndices) = [];
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
%%%%%%%%%%%%%%%% CREATE ROI LOGICAL IMAGES FOR ALL ROIS %%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We are going to create a logical image for each roi that matches the
% width and height of each of our collected data frames so first get the
% width and height of images in the imExp
imageDim = ...
        size(imExp.correctedStacks(1,1).(['Ch',num2str(chNum)]));

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
% outer circle will be 20% greater.

% determine the center and the radius for each of the rois
% simply take the mean of all the xs (stored in first col of each cell in
% allrois
centers = cellfun(@(g) [mean(g(:,1)), mean(g(:,2))], allRois,...
                   'UniformOut', 0);
               
% compute the radii for each roi stored in allRois
% compute as r = max(sqrt((x-x0)^2+(y-y0)^2)) where x0,y0 is the center of roi
roiRadii = cellfun(@(roi,c) max(sqrt((roi(:,1)-c(1)).^2 +...
                    (roi(:,2)-c(2)).^2)), allRois, centers,'UniformOut',0);
            
% now create inner and outer circles to create an annular region
radians = linspace(0, 2*pi, 100);

innerCircles = cellfun(@(center,radius)...
    [center(1)+radius*cos(radians);center(2)+radius*sin(radians)]',...
    centers, roiRadii, 'UniformOut',0);

% create the outerCircles to be 20% larger (want to make 20 um!!!!)
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
        class(imExp.correctedStacks(1,1).(['Ch',num2str(chNum)]));

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

% get all the images from the images map. These are stored to a cell array
% ordered by the angle and suborder as numtrials x numConds
allImages = imagesMap.values;
% obtain the number of angles (typically 8). We need this because next we
% are going to flatten allImages
numAngles = numel(allImages);
% also obtain the number of trials
numTrials = size(allImages{1},1);
% get the number of surround conditions
numConds = size(allImages{1},2);

% flatten allImages from a {{10x5}{10x5}...{10x5}) over 8 angles to a
% {10x40} then perform multiplication 
unrolledImages = [allImages{:}];

% Perform the multiplications
%roiImageStacks = cell(1,400);
%neuroImageStacks = cell(1,400);
for stack = 1:numel(unrolledImages)
    roiImageStacks{stack} = comboRoiStack.*unrolledImages{stack};
    neuroImageStacks{stack} = comboNeuropilStack.*unrolledImages{stack};
end

% roiImageStacks = cellfun(@(x) comboRoiStack.*x, unrolledImages,...
%                         'UniformOut',0); 
% neuroImageStacks = cellfun(@(x) comboNeuropilStack.*x, unrolledImages,...
%                         'UniformOut',0); 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%% CALCULATE NEUROPIL SUBTRACTED SIGNAL %%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We have created roiImageStacks and neuroImageStacks. These stacks contain
% the product of the combined roiLogical and neuropil logicals with all the
% images in the imExp. Essentially we have a filtered set of images where 
% only the pixels in the rois and neuropils are non zero. We will now
% obtain the row and col indices for each roi and neuropil region and
% extract these values from each of the image stacks and calculate the
% dfbyf.

%tic
if isempty(currentRoi)
    % start by looping through each roi (same as size of allRoiImages)
    for roi = 1:numel(allRois)
        % create a 3-D Logical logical for each roi
        logicalRoiMat = repmat(allRoiImages{roi},[1,1,imageDim(3)]);
        logicalNeuroMat = repmat(neuropilLogicalImages{roi},[1,1,imageDim(3)]);
        
        % now loop through all the imageStacks ex. 10 trials x 8 angles x
        % 5conds = 400 images
        for imageStack = 1:numel(roiImageStacks)
            
            % use logical indexing to extract the substack corresponding to
            % this roi
            roiSubmatrix = roiImageStacks{imageStack}(logicalRoiMat);
            neuroSubmatrix = neuroImageStacks{imageStack}(logicalNeuroMat);
            
            % now above line converts to a single array take mean of every
            % numFrames elements using reshape. frames will be along
            % columns. Each column will caontain all the luminance values
            % in that frame
            roiSubmatrix = reshape(roiSubmatrix,[],imageDim(3));
            neuroSubmatrix = reshape(neuroSubmatrix,[],imageDim(3));
            
            % get the uncorrected fluorVals by taking the mean row wise
            fluorVals = (mean(roiSubmatrix,1))';
            
            %now take mean along rows to get corrected fluorVals
            corrFluorVals = (mean(roiSubmatrix,1)...
                            -neuropilRatio*mean(neuroSubmatrix,1))';

            % Call deltaFbyF function to calculate percentage change in
            % fluorescence during visual stimulation
            dFByF{roi}{imageStack} = deltaFbyF(fluorVals, corrFluorVals,...
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
     
     logicalRoiMat = repmat(allRoiImages{roiImageNumber},[1,1,imageDim(3)]);
     logicalNeuroMat = repmat(neuropilLogicalImages{roiImageNumber},[1,1,imageDim(3)]);
     
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
            
            % get the uncorrected fluorVals by taking the mean row wise
            fluorVals = (mean(roiSubmatrix,1))';
            
            %now take mean along rows
            corrFluorVals = (mean(roiSubmatrix,1)-...
                            neuropilRatio*mean(neuroSubmatrix,1))';
            
        
            % Call deltaFbyF function to calculate percentage change in
            % fluorescence during visual stimulation
            dFByF{1}{imageStack} = deltaFbyF(fluorVals,corrFluorVals,...
                imExp.stimulus(1,1).Timing,...
                imExp.fileInfo(1,1).imageFrameRate);
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%% REORGANIZE THE DFBYF CELL ARRAY %%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Our dFByF cell array is 1xnum(rois) where each roi contains a 1x400 cell
% containing [1x30] doubles

% reshape each roi from 1x400 cell to a 10 by 5 by 8 cell
dFByF = cellfun(@(t) reshape(t,numTrials,numConds,numAngles), dFByF,...
                'UniformOut',0);
        
% reshape each 10x5x8 into a cell of {{10x5},{},...}
for roi = 1:numel(dFByF)
    for k=1:numAngles
        fluorCell{roi}{k} = [dFByF{roi}(:,:,k)];
    end
end

%assignin('base','fluorCell',fluorCell)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%% CONSTRUCT FLUOR MAPS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We now have a {1x8} for each roi over angles stored in fluorCell. We now
% need to convert this cell into a map keyed on angles so that we have a
% cell array of maps for each roi. We will loop over all the rois and
% construct a map for each

for roi = 1:numel(fluorCell)
    % initialize a map with a double key type and any value type
    fMap = containers.Map('KeyType','double','ValueType','any');
    
    % initialize the map keys as the unique angles and the values as empty
    % cells
    for keyIndex = 1:numel(uniqAngles)
        fMap(uniqAngles(keyIndex)) = {};
    end
    
    % add the fluorCell to this roi fluorescence map
    for angleIndex = 1:numel(fluorCell{roi})
        fMap(uniqAngles(angleIndex)) = [fMap(uniqAngles(angleIndex)),...
                                        fluorCell{roi}{angleIndex}];
    end
    % lastly assign this map to the set of all fluorMaps
    fluorMaps{roi} = fMap;
end
%assignin('base','fluorMaps',fluorMaps)    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
%assignin('base','signalMaps',signalMaps)    
%toc
