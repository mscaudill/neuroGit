function [figureHandle, axesHandles, uiHandles ] = ...
                                             createImageFigure(viewerState)
%imageFugurer creates the basic figure window that opens when a file is
%loaded into the tiffViewerGui. It consist of the images (one for each
%channel) and various uiControls.
% INPUTS:       viewerState, state structure containing all the image
%               information needed to image the channels being requested
% OUTPUTS:      handles for the figure, the axes and all the uicontrols are
%               passed back
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
%%%%% OBTAIN THE NUMBER OF FILES ALREADY OPENED IN TIFFVIEWER GUI %%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The viewer state contains all the tiff files previously opened
numFiles = numel(viewerState.tiffCells);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%% CREATE A NEW FIGURE %%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% First obtain the number of open figures (this will include all gui's
% since they are also figure files)
numFigs = length(findall(0,'type','figure'));

% create a new figure file and set the tag to be tiffViewerImage_...
% num2str(numFigs+1)
figureHandle = figure(numFigs+1);

%set the name of the figure to the current image fileName in viewerState
set(figureHandle,'name', viewerState.currentImageFileName);

% set the tag of this image
set(figureHandle,'tag',...
    ['tiffViewerImage ',num2str(numFiles+1)])
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%% CREATE AXES WITHIN THE FIGURE %%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Determine the number of channels and hence the number of subplots to
% create
numChs = numel(viewerState.chsAcquired);

% create our axes and display data and all uicontrols always returning the
% handles
%%%%%%%%%%%%%%%%%%%%%%%%%% Create axes %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
axesHandles = tight_subplot(1, numChs, 0.05, [.1,.01], .01);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for chIndex = 1:numChs
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%% Image to axes %%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % obtain the tiffImage from the tiffCell stored in viewerState it is
    % the last tiffCell (i.e. the latest file loaded and obtain ch)
    tiffImage =...
        viewerState.tiffCells{end}{viewerState.chsAcquired(chIndex)};
    
    % obtain the stack extremas for this tiff image stack
    stackExtrema = ...
        viewerState.stackExtremas{end}{viewerState.chsAcquired(chIndex)};
    
    % image to axes by calling dispTiff using the first image of the stack
    % and  scaling of 1
    dispTiff(axesHandles(chIndex), tiffImage, stackExtrema, 1, 1)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%% Title axes %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    title(axesHandles(chIndex),[viewerState.chColors{chIndex},' Ch'],...
            'Interpreter','None','BackgroundColor',...
            viewerState.chColors{chIndex});
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%% Add Slider Control %%%%%%%%%%%%%%%%%%%%%%%%
    % get the position vector of the figure
    figPos = get(figureHandle,'position');
    % set the sliderWidth
    sliderWidth = figPos(3)-.1*figPos(3);
    % set the slider left position
    sliderXpos = (figPos(3)-sliderWidth)/2;
    % set the slider vertical position ( set it as bottom + 10% of height)
    sliderYpos =.1*figPos(4);
    
    % Set the slider min, max, minor and major step size
    sliderMin = 1;
    sliderMax = size(tiffImage,3);
    sliderStep = ([1,1]/(sliderMax-sliderMin));
    
    % Lastly add the slider and return back the control with an anonymous
    % callback function
    uiHandles.sliderControl = uicontrol('Style', 'slider',...
       'Min',sliderMin,'Max', sliderMax, 'SliderStep',sliderStep,...
       'Value',sliderMin,'Position', [sliderXpos sliderYpos sliderWidth 30],...
       'Callback',@(hObject,eventdata) imageFigureUpdater(viewerState,'slider'));
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end