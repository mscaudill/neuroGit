%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%copyright (c) 2012  Matthew Caudill
%
%this program is free software: you can redistribute it and/or modify
%it under the terms of the gnu general public license as published by
%the free software foundation, either version 3 of the license, or
%at your option) any later version.

%this program is distributed in the hope that it will be useful,
%but without any warranty; without even the implied warranty of
%merchantability or fitness for a particular purpose.  see the
%gnu general public license for more details.

%you should have received a copy of the gnu general public license
%along with this program.  if not, see <http://www.gnu.org/licenses/>.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function FlipCheck( window, screenRect, colors, counter )
%FLIPCHECK places a square (60 x 60 pixels) at the bottom right corner of
%each of of the visual stimuli called by the stimGen Gui. The square will
%modulate shade on every call to screen flip. The user can place a
%photodiode over this screen position to determine which frames of the
%stimulus were not shown. Before using stimGen, it is recommended that the
%user calls the PTB function VblSyncTest to assess how many frames are
%being missed. Checking for missed frames is only relevant if you are
%asking for tightly controlled stimulus values (like spike trigerred
%averages)
%INPUTS:  window         a pointer to the window where we will draw to.
%         screenRect     a 1x4 matrix of coordinates of the screen
%         colors         a two element array of the colors to modulate
%         counter        a counter recording each draw of the stimulus

% we will draw a rectangle that is 80x80 pixels to the bottom right corner
% of the screen. The shade will modulate between white and black

% set the size of the flip check box 
boxSize = 50;

% Get the upperLeft coordinates of our box
upperLeft = [screenRect(3)-boxSize, screenRect(4)-boxSize];

% Get the lower right coordinates
lowerRight = [screenRect(3), screenRect(4)];

% draw the box to the screen
Screen('FillRect', window, colors(mod(counter,2)+1),...
          [upperLeft(1) upperLeft(2) lowerRight(1) lowerRight(2)]);
end

