function saveAviMovie(saveFileName, varargin )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
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
%%%%%%%%%%%%%%%%%%%%%%%%%% PARSE VARARGIN %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
p = inputParser;

% Set the default channel  in the data to view
defaultDataCh = 2;
% Set the defualt scaleFactor of the video: max(movieIntensity)/scaleFactor
% sets the range of intensities in the output movie
defaultScalFactor = 3;
% Set the initial magnification of the video
defaultMagnification = 200;
defaultSaveLocation = 'A:\MSC\Data\CSproject\videos';

% Add required save fileName
addRequired(p,saveFileName,@ischar);

% Add each optional parameter to the input parser
addParamValue(p, 'dataCh', defaultDataCh, @isnumeric);
addParamValue(p, 'scaleFactor', defaultScalFactor, @isnumeric);
addParamValue(p, 'initialMagnification', defaultMagnification, @isnumeric);
addParamValue(p, 'saveLocation', defaultSaveLocation, @ischar);

% call input parse method
parse(p,saveFileName, varargin{:});

% retrieve variable arguments fromt the parser object
dataCh = p.Results.dataCh;
scaleFactor = p.Results.scaleFactor;
initialMagnification = p.Results.initialMagnification;
saveLocation = p.Results.saveLocation;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%% OBTAIN THE STIMULUS AND DATA FILENAMES %%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Call imExpDirInformation to load the stimFileLoc
ImExpDirInformation;
stimFileLoc = dirInfo.stimFileLoc;

% Call uigetfile to access user choice stimulus filenames and paths
[stimFileNames, stimFilePath] = uigetfile('*.mat',...
                                   'SELECT STIMULUS FILES', stimFileLoc,...
                                   'MultiSelect', 'On');

% If the user has selected only one file we need to recast it to a cell
if ~iscell(stimFileNames)
    stimFileNames = {stimFileNames};
end
% call the stimImageMatcher to load the image dataFiles that match the user
% selected stimulus files
[imageFileNames, ~ , imagePath] = stimImageMatcher(stimFileNames);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%% LOAD STIMULUS FILES & DETERMINE STIMVARIABLE %%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% For each file load the stimulus struct and determine the stimVariable
for fileName = 1:numel(stimFileNames)
    % load the trials to a structure
    stimStruct = load(fullfile(stimFilePath,...
                               stimFileNames{fileName}));
    % extract the trialsStruct for this file
    stimulus{fileName} =  stimStruct.trials;

    % autoLocate the stimVariable
    stimVars{fileName} = autoLocateStimVariables(stimulus{fileName});
end

% Make sure we have identified only one stimvariable
stimVariable = unique([stimVars{:}]);
if numel(stimVariable) > 1
    errordlg(['More than one stimulus variable located,', char(10),...
              'Please check stimulus files'])
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%% OBTAIN ALL THE STIMULUS VARIABLE PARMETERS %%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Now that we have the stimulus variable we will obtain all the values of
% this variable across all stimulus sets
stimParamsCell = cellfun(@(x) [x.(stimVariable{1})], stimulus,...
                        'UniformOut', 0);
% now collapse this cell into a single array 1xnumel(files)xnumel(trials)
stimulusParameters = cell2mat(stimParamsCell);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%% LOAD IMAGE METADATA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get header information from the first tiffFileName and get the frameRate
tiffOne = fullfile(imagePath,imageFileNames{1});
InfoImage = imfinfo(tiffOne);

% Get the image description for the first image in the sequence
a = InfoImage(1,1).ImageDescription;

% start by locating the start indices of the strings
stringsToFind = {'state.acq.frameRate', 'state.acq.binFactor'};
startIndices = [strfind(a, stringsToFind{1}),...
                strfind(a, stringsToFind{2})];
% Now use strtok to extract the lines from 'a' using the newline char(13)
% as the delimiter
tokenLines = {strtok(a(startIndices(1):end),char(13)),...
          strtok(a(startIndices(2):end),char(13))};
      
% now break each line on the equals and retrieve the remainder (i.e. the
% number string for the variable)
[~,acqFrameRate] = strtok(tokenLines{1},'=');
% note we take 2:end becasue remainder also returns the equal sign
acquisitionFrameRate = str2double(acqFrameRate(2:end));

[~, numFrames] = strtok(tokenLines{2},'=');

% note we take 2:end becasue remainder also returns the equal sign
imagesPerAcquisition = str2double(numFrames(2:end));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%% LOAD EACH TIFF FILE %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We will now load each of the tiffFiles into a tiffCell and then
% concatenate into one matrix imageWidth x ImageHeight x
% (numImagesxNumStimuli)
for file = 1:numel(imageFileNames)
    [~, tiff{file}] = tiffLoader(imagePath,imageFileNames{file},dataCh);
end

% now we concatenate all of the tiffMatrices along the thrid dim
allTiffs = [tiff{:}];

% remove the empty cells corresponding to the other chs
allTiffs = allTiffs(~cellfun('isempty',allTiffs));

% Lastly concatenate all the tiff matrices to a single large matrix
allTiffs = cat(3,allTiffs{:});
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%% WRITE FRAMES TO AVI %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Create an avi obj and open it for writing to
writerObj = VideoWriter(fullfile(saveLocation,saveFileName));
writerObj.FrameRate = acquisitionFrameRate;
open(writerObj);

numTriggers = numel(stimulus{1});
stimTiming = stimulus{1}.Timing;

for image = 1:size(allTiffs,3)
    % use imshow to display the image to the figure
    imshow(allTiffs(:,:,image),[0,max(max(max(allTiffs)))/scaleFactor],...
           'initialMagnification',initialMagnification);
    
    % the current file number for this image is the image number divided by
    %(images/trigg*triggs/file)
    fileNumber = ceil(image/(imagesPerAcquisition*numTriggers)); 
    
    %The trigger number is 
    trigger = mod(ceil(image/imagesPerAcquisition),numTriggers);
    if trigger == 0
        trigger = numTriggers;
    end
    
    frame = mod(image,imagesPerAcquisition);
    if frame == 0
        frame = imagesPerAcquisition;
    end
    
    % Obtain the stimValue
    stimValue = stimulusParameters(trigger*fileNumber);
    
    % Create a frame text box to be displayed on each image (note
    % positioning is in pixel units)
     ht = text(size(allTiffs,2)/2+30,size(allTiffs,1)-5,...
           ['File : ',num2str(fileNumber),...
           ' Trigger : ', num2str(trigger),...
           ' Frame : ',num2str(frame),'/',num2str(imagesPerAcquisition)]);
       
     ht2 = text(10,size(allTiffs,1)-5,...
           [stimVariable{1},' = ' num2str(stimValue)]);
     
    set(ht,'color',[.5,.5,.5]); 
    set(ht2,'color',[.5,.5,.5]);
    
     %If the stimulus is on the monitor during this frame color the text
     if (frame/acquisitionFrameRate) > stimTiming(1) &&... 
        (frame/acquisitionFrameRate)<(stimTiming(1)+stimTiming(2))
        set(ht,'color',[1,1,0]); 
        set(ht2,'color',[1,1,0]);
     end
       
   frame = getframe;
   writeVideo(writerObj,frame);
end
close(writerObj);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end

