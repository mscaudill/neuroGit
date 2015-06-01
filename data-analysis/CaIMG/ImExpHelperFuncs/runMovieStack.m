function runMovieStack(imageStack, stimulusTiming, acqFrameRate,...
                       scaleFactor, framesPerSec, repeats)
% runMovieStack plays an image stack as a movie
% INPUTS:               imageStack, a sequnce of images stored in a 3D
%                                   matrix
%                       scaleFactor, a double used to shrink the range of
%                                    values present in imageStack
%                       framesPerSec, the speed at which to play the movie
%                       repeats, # of times to play movie
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
%%%%%%%%%%%%%%%%%%% OPEN FIGURE AND SET AXIS PROPS %%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Define the rendering method as OpenGL since most pcs feature hardware
% acceleration for this renderer. Note if running on a MAC set the rederer
% to zbuffer since OpenGL is not available
hfig = figure('Renderer','zbuffer');
% Set the axis tight to the images
axis tight;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%% RENDER THE MOVIE AND SAVE FRAMES %%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The process of creating a movie involves 2-steps. First we must render 
% the movie with the graphics hardware and use get frame to capture each
% image in the figure for future replay.

% Loop through our image stack (along d3), scale the images using
% scaleFactor and magnify the image to double original size
for i=1:size(imageStack,3)
    imshow(imageStack(:,:,i),[0 max(max(max(imageStack)))/scaleFactor],...
                     'initialmagnification',100)
    % Create a frame text box to be displayed on each image (note
    % positioning is in pixel units)
    ht = text(size(imageStack,2)/2-15,size(imageStack,1)-10,...
                ['Frame:',num2str(i),'/',num2str(size(imageStack,3))]);
            
    % set the color of frame text to gray if pre and post stimulus
    if i/acqFrameRate < stimulusTiming(1) ||...
            i/acqFrameRate > stimulusTiming(1) + stimulusTiming(2) 
        set(ht,'color',[.5 .5 .5],'FontSize',12);
    else % set the color to yellow if during the stimulus
        set(ht,'color', [1 1 0],'FontSize',12)
    end
    
    % call get frame to capture the current image shown in the figure and
    % save to mov
    mov(i) = getframe;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%% PLAY THE MOVIE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Now play the movie 3 times at frames/sec specified by user
movie(mov,repeats,framesPerSec)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%% CLOSE THE FIGURE %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% If the figure was not closed by the user then we will autoclose the
% figure to prevent conflicts with other programs displaying figures
% Check whether figure handle exist, if so close the figure
if ishandle(hfig)
    close(hfig)
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

