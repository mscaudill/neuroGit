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
function dispStimTiming( stimFileName, tiffImageStack, frameNum,...
                         imagePath, axes )
% dispStimTiming creates a figure of the stimulus timing with a shaded box
% that moves to indicate when a tiff image was taken relative to the
% stimulus. We access the stimulus timing using stimFileName, we access the
% sampling rate to draw a shaded box over the stimulus timing plot from the
% header of the tiff stack. We draw the timing plot and shaded box to axes


%TESTING
% imagePath = 'C:\Users\Matthew Caudill\Desktop\matprac\ImageTest\20121107';
% tiffImageStack = 'n1orientation_1_001.tif';
% stimFileName = 'MSC_2012-11-7_n1orientation_1_Trials.mat';
% frameNum = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%% CONSTRUCT FULLFILE NAME AND LOAD %%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ImExpDirInformation;
stimFileLoc = dirInfo.stimFileLoc;

load(fullfile(stimFileLoc,stimFileName));
timing = trials(1,1).Timing;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%% DRAW THE STIMULUS TIMING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% create stimValues from the timing array using numPoint samples for each
% peirod (wait, duration, delay) of the stimulus
numPoints = 1000;
stimValue = [1*ones(1,timing(1)*numPoints),...
             2*ones(1,timing(2)*numPoints),...
             1*ones(1,timing(3)*numPoints)];
         
time = linspace(0,sum(timing),sum(timing)*numPoints);

hPlot = plot(time, stimValue,'Parent', axes);
hold on;
ylim(axes,[.75 2.25]);
xlimits = get(axes,'xlim');
set(hPlot, 'LineWidth',     2,...
           'Color',         [0 0 0]);
       
%%%%%%%%%%%%%%% CONSTRUCT FULLFILE PATH/NAME TO TIFF STACK %%%%%%%%%%%%%%%%
tiffFile = fullfile(imagePath,tiffImageStack);

%%%%%%%%%%%%%%%%%%%%%%% GET TIFF FILE INFORMATION %%%%%%%%%%%%%%%%%%%%%%%%%
% Get image info structure
InfoImage=imfinfo(tiffFile);

% We now need to get the frame rate. This is determined by scan image as
% 1/(lines/frame * ms/line). We can get the lines/frame and the ms/line
% from the header file Scan image is written poorly, the designer saved all
% the aquistion info to a character array. . The character array is called
% ImageDescription, I rename to 'a' here for brevity. We will locate the
% strings in tha character array coresponding to our variables of interest

a = InfoImage(1,1).ImageDescription;

% start by locating the start indices of the strings
stringsToFind = {'state.acq.linesPerFrame', 'state.acq.msPerLine'};
startIndices = [strfind(a, stringsToFind{1}),...
                strfind(a, stringsToFind{2})];
% Now use strtok to extract the lines from 'a' using the newline char(13)
% as the delimiter
tokenLines = {strtok(a(startIndices(1):end),char(13)),...
          strtok(a(startIndices(2):end),char(13))};
      
% now break each line on the equals and retrieve the remainder (i.e. the
% number string for the variable)
[~,linesPerFrame] = strtok(tokenLines{1},'=');
% note we take 2:end becasue remainder also returns the equal sign
linesPerFrame = str2double(linesPerFrame(2:end));

[~, msPerLine] = strtok(tokenLines{2},'=');

% note we take 2:end becasue remainder also returns the equal sign
msPerLine = str2double(msPerLine(2:end));

% Now we calculate our frame rate and time per frame
frameRate = 1/(linesPerFrame*msPerLine/1000);
timePerFrame = (1/frameRate);

% now we need to create a shaded area that will start at
% frame#*timePerFrame and have a width of timePerFrame

%Calculate the start point
frameTimeStartPoint = timePerFrame*(frameNum-1);
% construct a vector of time points for the area
frameTimesVector =...
            (frameTimeStartPoint:1/numPoints:...
            frameTimeStartPoint+timePerFrame);
% get the current axis limits
yLimits = get(axes, 'ylim'); 
% construct the upper boundary of our shaded region
ylimVector= yLimits(2)*ones(numel(frameTimesVector),1);
% construct our area
 ha = area(axes, frameTimesVector, ylimVector, yLimits(1));
% 
 set(ha, 'FaceColor', [255/255 204/255 204/255])
 set(ha, 'LineStyle', 'none')
 set(axes, 'box','off') 
 set(axes,'YTickLabel','')
 set(axes, 'xlim', xlimits);
% % We now want to reorder the data plot and the area we just made so that
% % the stimulus always appears on top we do this by accessing all lines
% % ('children') and flip them
 set(axes,'children',flipud(get(axes,'children')))
 hold off;


