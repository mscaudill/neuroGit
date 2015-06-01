function iImageMapper(varargin)
% iImageMapper generates three plots for intrinsic signal data. It
% generates the mean evoked activity frame, the thresholded region of
% responsiveness and a histogram of pixels across the evoked frame.
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
%%%%%%%%%%%%%%%%%%%%% OBTAIN REFERENCE/DATA FRAMES %%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% set where to locate image files
iImageLoc = 'A:\MSC\Data\CSproject\intrinsicData\';

% Call uigetFile to get the reference frame collected with ccd
[referenceName, refPathName] = uigetfile('*.tif','Select Reference Image',...
                                        iImageLoc,...
                                        'MultiSelect','off');

% uigetfile to get a list of tiff file names collected with a ccd camera
[dataFileNames, PathName] = uigetfile('*.tif','Selectect Data Images',...
                                       iImageLoc,...
                                       'MultiSelect','on');

% If only one data file is selected we convert it to a cell array
if ~iscell(dataFileNames)
    dataFileNames = {dataFileNames};
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%% BUILD AN INPUT PARSER %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The input parser will allow the user to enter varaible arguments into the
% function and set defaults if not specified

% construct a parser object (builtin matlab class)
p = inputParser;

%Set the default acquisition time to be twelve seconds
defaultAcqTime = 14;
% Set the frame rate to be 5 Hz
defaultFrameRate = 5;
% Set the time vector of the stimulus [delay, duration, wait]
defaultStimTime = [2 4 10];
% Set the number of stimuli shown to be 12 (12 orientations of a center
% grating)
defaultNumStims = 24;
% Set the standard deviations for thresholding to auto-locate responsive
% region. 1 stds is default
defaultThreshold = 1;
% Set the default number of frame drops to be zeros the length of dataFiles
defaultFrameDrops = zeros(1,numel(dataFileNames));

% add each optional parameter to the parse object and validate
addParamValue(p, 'acqTime', defaultAcqTime, @isnumeric);
addParamValue(p, 'frameRate', defaultFrameRate, @isnumeric);
addParamValue(p, 'stimTime', defaultStimTime, @isvector);
addParamValue(p, 'numStims', defaultNumStims, @isnumeric);
addParamValue(p, 'threshold', defaultThreshold, @isnumeric);
addParamValue(p, 'firstAcqFrameDrops', defaultFrameDrops, @isvector);

% call the input parser method parse
parse(p,varargin{:})

% retrieve the variable arguments from the parser inputs
acqTime = p.Results.acqTime;
frameRate = p.Results.frameRate;
stimTime = p.Results.stimTime;
numStimuli = p.Results.numStims;
firstAcqFrameDrops = p.Results.firstAcqFrameDrops;
threshold = p.Results.threshold;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%% LOAD REFERENCE IMAGE TO MATRIX %%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Construct the reference file name
refFile = fullfile(refPathName,referenceName);

% get image information from the header
InfoImage=imfinfo(refFile);
% Get image dimensions
imageWidth=InfoImage(1).Width;
imageHeight=InfoImage(1).Height;

% Read in the the file to a matrix
refFrame = imread(refFile,'Info',InfoImage);
% rotate the reference frame so that rostral is north

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%% LOAD DATA IMAGES TO MATRIX %%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialize a cell to hold our matrices
tiffCell = {};
% For each data image file, we will load it and chunk the data into
% individual triggered image stacks ex. 512x512x50 image stacks one for
% each stimulus codition.
for file = 1:numel(dataFileNames)
    
    % construct fullFile name
    tiffFile = fullfile(PathName, dataFileNames{file});
    
    % obtain the number of frame drops for this file
    firstFrameDrops = firstAcqFrameDrops(file);
    
    % call the ccdTiffLoader to load an individual file and take care of
    % missing frames if they occurred.
    [tiffMatrix, acquisitionsToDrop] = ccdTiffLoader(acqTime, stimTime,...
                                            frameRate,numStimuli,...
                                            tiffFile,firstFrameDrops);

    % cut the large tiffmatrix image using mat 2cell and class into tiffCel   
    tiffCell = [tiffCell; squeeze(mat2cell(tiffMatrix, imageWidth,...
                                           imageHeight,...
                                           size(tiffMatrix,3)/...
                     (numStimuli-acquisitionsToDrop)*...
                     ones(1,numStimuli-acquisitionsToDrop)))];
                    
    % clear the tiffMatrix variable
    clear tiffMatrix

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%% COMPUTE THE MEAN IMAGE STACK OVER ALL STIMULI %%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We will now compute the mean 3-D stack across all stimuli by
% concatenating them along the 4th dim and taking the mean. Also rotate the
% matrix values so rostral is north
meanMatrix = mean(cat(4,tiffCell{:}),4);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%% EXTRACT PRE-STIM AND STIM FRAMES %%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% To compute  the percvent change in reflectance we need the prestimulus
% frames and the stimulus frames from our meanMatrix

% extract the pre-stim frames
preStimFrames = meanMatrix(:,:,1:stimTime(1)*frameRate);

% compute average frame of pre-stim frames
avgPreStimFrame = mean(preStimFrames,3);

% extract stim frames
stimFrames = meanMatrix(:,:,stimTime(1)*frameRate:(stimTime(1)+...
                                                   stimTime(2))*frameRate);
% compute average frame of stim frames
avgStimFrame = mean(stimFrames,3);
                                               
% construct an evoked stack                                            
evokedStack = bsxfun(@minus,meanMatrix,avgPreStimFrame);

% compute avg evokedFrame
avgEvokedFrame = (avgStimFrame-avgPreStimFrame);

% Calculate the percentage change in reflectance
DRbyR = bsxfun(@rdivide,evokedStack,avgPreStimFrame);

avgEvokedReflectanceFrame = bsxfun(@rdivide,avgEvokedFrame,avgPreStimFrame);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% PLOTTING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%% PLOT THE PERCENTAGE REFLECTANCE CHANGES %%%%%%%%%%%%%%
% Extract frames for each second of prestim time and stimulationTime +
% extra to plot
framesToGrab = ...
    DRbyR(:,:,frameRate:frameRate:frameRate...
                                  *(stimTime(1)+stimTime(2))+2*frameRate);

% determine the numPlots we will need
numPlots = size(framesToGrab,3);
% determine the layout of the plots (always a square) 
rows = ceil(sqrt(numPlots));
cols = ceil(sqrt(numPlots));

% set up figure size
hFig1 = figure(1);
set(hFig1,'position', [581 155 920 730]);
for frame = 1:numPlots
    subplot(rows,cols,frame)  
    imshow(framesToGrab(:,:,frame),[]);
    % place some text on the plot to indicate frame time
    text(10,20,[num2str(frame), ' secs'],'color',[0 0 0],'fontSize',14)
end

% add the average evoked Reflectance frame as the last image
subplot(rows,cols,numPlots+1)
imshow(avgEvokedReflectanceFrame,[]);
text(-10,-20,['<Evoked Reflectance>'], 'color', 'k',...
            'fontSize',14)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%% PLOT REFLECTANCE, FILTERED, AND BINARY DATA %%%%%%%%%%%%%%%%

%# Gaussian-filter the image:
gaussFilter = fspecial('gaussian',[20 20],10);  %# Create the filter
filteredData = imfilter(avgEvokedReflectanceFrame,gaussFilter);

%imshow(filteredData,[]);
%title('Gaussian-filtered image');

%
 meanRef = mean2(avgEvokedReflectanceFrame);
 stdRef = std2(avgEvokedReflectanceFrame);
%meanRef = mean2(filteredData);
%stdRef  = std2(filteredData);
%

bwImage = filteredData < meanRef-threshold*stdRef;
%bwImage = avgEvokedReflectanceFrame < meanRef-threshold*stdRef;
%imshow(bwImage)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% make a green image
B = cat(3,zeros(size(avgEvokedFrame)), ones(size(avgEvokedFrame)),...
          zeros(size(avgEvokedFrame)));


figure(2)
set(gcf,'position', [913   264   668   537]);
% Display the reference image
imshow(refFrame,[])
hold on
h = imshow(B);
hold off;
% use the logical image to set the alpha component
set(h,'AlphaData', 0.3*bwImage)

%runMovieStack(DRbyR,[2,4,10],5,2,2,2)
% 
figure(3)
hist(avgEvokedReflectanceFrame(:),1000);
ylim=get(gca,'ylim');
line([meanRef meanRef], ylim, 'Color','g');
line([meanRef-threshold*stdRef,meanRef-threshold*stdRef],ylim,'Color','r');

assignin('base','filteredData',filteredData)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end

