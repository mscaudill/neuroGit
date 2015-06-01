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
%function MouseControlledGrating(table)
% This function generates and draws a grating based on the initial values
% passed from the StimGen gui table. The grating 'tracks' the mouse
% position on the screen. It will return a plot of the mouse clicks.
%
% INPUTS: STIMGEN GUI TABLE
% OUTPUTS: FIGURE OF MOUSE CLICK POSITIONS
% USAGE: UP AND DOWN KEYS INCREASE/DECREASE GRATING SIZE, LEFT AND RIGHT TO
% CHANGE GRATING ORIENTATION.  SPACE BAR TO SAVE A
% POSITION, CLICK MOUSE TO EXIT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Written by MSC 6-15-12
% Modified by:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function MouseControlledGrating(table)
%%%%%%%%%%%%%%%%%%%%%% DEFAULTS FOR TESTING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%UNCOMMENT THIS SECTION FOR RUNNING STIMULUS AS STAND ALONE; COMMENT ABOVE
%CONFLICTING FUNCTION
%  function MouseControlledGrating(table)
% if nargin<1
%     table = {'Background Shade', 127, [], [];...
%              'Initial Grating Diameter (degs)', 20, [], [];...
%              'Initial Grating Angle (degs)', 0, [], [];...
%              'Spatial Frequency (cpd)', .08, [], []};
% end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Get monitor info from monitorInformation located in RigSpecificInfo dir.
% This structure contains all the pertinent monitor information we will
% need such as screen size and appropriate conversions from pixels to
% visual degrees
monitorInformation;

%%%%%%%%%%%%%%%%%%%%% TURN OFF PTB SYSTEM CHECK REPORT %%%%%%%%%%%%%%%%%%%%
Screen('Preference', 'Verbosity',1); 
% This will suppress all but critical warning messages
% At the end of the code we will return the verbosity back to norm level 3
% please see the following page for an explanation of this function
% http://psychtoolbox.org/FaqWarningPrefs
% NOTE: as you debug your code comment this line because PTB will return
% back useful info about memory usage that will tell you about leaks that
% may casue problems

% When Screen('OpenWindow',w,color) is called, PTB performs many checks of
% your system. The time it takes to perform these checks depends on the
% noisiness of your system (up to two seconds on 2-photon rig). During this
% time it displays a white screen which is obviously not good for visual
% stimulation. We can disable the startup screen using the following. The
% sreen will now be black before visual stimulus
Screen('Preference', 'VisualDebuglevel', 3);
% see http://psychtoolbox.org/FaqBlueScreen for a reference

%%%%%%%%%%%%%%%%%%%%% OPEN A SCREEN & DETERMINE PARAMETERS %%%%%%%%%%%%%%%%
% Use a try except block to prevent the screen from hanging. During testing
% if the screen does hang press cntrl C or cntrl-alt del to bring up the
% task manager to stop PTB execution
 try   
    % Require OPENGL becasue some of the functions used here need the
    % OPENGL version of PTB
    AssertOpenGL;
    
%%%%%%%%%%%%%%%%%%%%%% GET SPECIFIC MONITOR INFORMATION %%%%%%%%%%%%%%%%%%%

    % SCREEN WE WILL DISPLAY ON
    %Query monitorInformation for screenNumber
    screenNumber = monitorInfo.screenNumber;

    % CONVERSION FROM DEGS TO PX AND SIZING INFO FOR SCREEN
    %conversion factor specific to monitor
    degPerPix = monitorInfo.degPerPix;
    % Size of the drawing area (in pix) that we will draw (1.0 times 
    % monitor width)
    ScreenSize = 1.0*monitorInfo.screenSizePixX;
    
    %Set the background color (gamma corrected)
    % COLOR INFORMATION OF SCREEN
    % Get black, white and gray color values for the current monitor
    whitePix = WhiteIndex(screenNumber);
    blackPix = BlackIndex(screenNumber);
    
    %Convert balck and white to luminance values to determine gray
    %luminance
    whiteLum = PixToLum(whitePix);
    blackLum = PixToLum(blackPix);
    
    grayLum = (whiteLum + blackLum)/2;
    
    % Now determine the pixel value of gray from the gray luminance
    grayPix = GammaCorrect((whiteLum + blackLum)/2);
    
    inc = (whiteLum-grayLum);
    
%%%%%%%%%%%%%%%%%%%%%%%%%%% GET TABLE VALUES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    % GET TABLE VALUES
    BGShade = GammaCorrect(table{1,2}/whitePix*...
                                (whiteLum + blackLum));
    gratingDiamPix = round(table{2,2}/degPerPix);
    gratingAngle = table{3,2};
    spatialFrequency = table{4,2};
    
    % Convert spatial frequency and grating size to pixel units
    spatialFreqPix = spatialFrequency*degPerPix;
    pixPerCycle = ceil(1/spatialFreqPix);
    spatialFreqRad = 2*pi*spatialFreqPix;
    
%%%%%%%%%%%%%%%%%% SET UP KEYBOARD KEYS USER CAN USE %%%%%%%%%%%%%%%%%%%%%%
    % Switch from operating system specific naming system to MacOS-X system
    % allowing all kbs to use a common naming system
    KbName('UnifyKeyNames');
    upKey = KbName('UpArrow');
    downKey = KbName('DownArrow');
    leftKey = KbName('LeftArrow');
    rightKey = KbName('RightArrow');
    space = KbName('space');
    
%%%%%%%%%%%%%%%%%% SET INITIAL STATE OF MOUSE AND KEYS %%%%%%%%%%%%%%%%%%%%
    %button state
    buttons = 0;
    %x-y coordinates of mouse initially
    mX = 0;
    mY = 0;
    
    %%%%%%%%%%%%%%%%%%%%%%%% OPEN WINDOW AND RETURN POINTER W %%%%%%%%%%%%%%%%%        
    % Open a window and return a pointer w
    [w] = Screen('OpenWindow', screenNumber,  BGShade);
    % Hide the mouse cursor from the screen
    HideCursor;
    

%%%%%%%%%%%%%%%%%%%%%%% CREATE AND DRAW TEXTURES %%%%%%%%%%%%%%%%%%%%%%%%%%
% This is the main loop of the MouseControlGrating code. The loop will
% continue while no buttons on the mouse are pressed. We first construct a
% texture for the grating based on the current diameter  and spatial
% frequency and draw the grating to the screen. We then check the keyboard
% to see if the user has selected to increase or decrease the grating
% diameter, change oreintation, or plot a point. If the user selects to
% increase or decrease the size, we make a new texture and go through the
% loop again. If the user selects an orientation change then we just call
% 'DrawTexture' with the new orientation arg. If the user selects to plot a
% point we will save the position (x,y) and the stroke number to a
% structure called Strokes. Note that when the user presses any key we need
% to allow time for the key to be pressed and release so that one stroke of
% the space bar only registers as one click. This is because KbCheck is
% much faster than human reaction time so we must build in a delay called
% lastsecs.

    % Initialize arrays and structures to hold user inputs
    % a structure to hold keyboard strokes
    Strokes = struct();
    % a constant to hold number of strokes
    strokeNum = 0;
    % a constant of the time of the last stroke user made
    lastsecs = [];
    
    
    while ~any(buttons) %Buttons refers to mouse buttons not KeyBoard keys
        
%%%%%%%%%%%%%%%%%%%%%% CREATE THE GRATING TEXTURE %%%%%%%%%%%%%%%%%%%%%%%%%
        %Set up the texture size
        texsize = gratingDiamPix/2;
        % array of points for computing tex
        x = -2*texsize:2*texsize + pixPerCycle;
        %now create the 1D grating in luminance values
        grating = grayLum+inc*cos(spatialFreqRad*x);
        %convert grating to pixel values
        grating = GammaCorrect(grating);
        %and finally make the texture
        gratingtex = Screen('MakeTexture',w,grating);

        % Define the size of where to draw the grating to be the same size
        % as the grating texture
        dstRect=[0 0 gratingDiamPix gratingDiamPix];

%%%%%%%%%%%%%%%%%%%%%%%%% DRAW TEXTURE TO SCREEN %%%%%%%%%%%%%%%%%%%%%%%%%%        
        % Relay to the user a message (in cyan) on how to use the stimulus
        Screen('DrawText', w,...
    'Move mouse. Arrow keys to change Space bar to plot. Click to exit',...
            10, 10, [255 0 255]);

        % Determine the location of the mouse (mX, mY) and get the button
        % state (0 or 1)
        [mX, mY, buttons] = GetMouse;

        % Draw the texture to the screen and center it at the mouse
        % location mX,mY
        Screen('DrawTexture', w, gratingtex, dstRect,...
            CenterRectOnPoint(dstRect, mX, mY), gratingAngle);
    
        % Flip the texture to the screen (w)        
        Screen('Flip', w);
    
        % Check the keyboard keys (upKey, downKey and SpaceBar) to see if
        % we need to make updates to the texture
        [keyIsDown, secs, keyCode] = KbCheck;
        
        % if the user has not clicked before or if the last click was more
        % than 300 ms ago then the user has a valid click
        if isempty(lastsecs)||(secs-lastsecs) >= 0.3;
            if keyIsDown
                lastsecs=secs; % Update our click time interval
                % If the user has hit the up key we increase the size of
                % the grating by 2 degrees. Note tha we can't let the
                % user increase the dot forever so we set max dot diameter
                % to screenSize/1.25
                if keyCode(upKey)
                    gratingDiamPix = min(ScreenSize/1.25,...
                    gratingDiamPix + round(2/degPerPix));
                % If the user has hit the down key we decrease the size of
                % the dotDiameter by 2 degrees. Note tha we can't let the
                % user decrease the dot forever so we set min dot diameter
                % to 0.5 degrees
                elseif keyCode(downKey)
                    gratingDiamPix = max(round(0.5/degPerPix),...
                        gratingDiamPix - round(2/degPerPix));
                    
                elseif keyCode(rightKey) % rotate grating cw
                    gratingAngle = mod(gratingAngle+15,360);
                    
                elseif keyCode(leftKey) %rotate grating ccw
                    gratingAngle = mod(gratingAngle-15,360);
                    
                % If the user has hit the space bar then we need to save
                % the current position of the mouse (mX,mY) into our
                % strokes structure which is indexed by the stroke number.
                % We also will save the current dotDiam in Px because this
                % is a measure of the error in our position when a spike
                % was audibly detected
                elseif keyCode(space)
                    strokeNum = strokeNum+1;
                    Strokes(strokeNum).X = mX;
                    Strokes(strokeNum).Y = mY;
                    Strokes(strokeNum).gratingDiameter = gratingDiamPix;
                end
            end
        end
         % It is vital that we close the dot texture in during each run of
        % the loop because everytime we move the mouse or hit keys we
        % create a texture. This means the above loop can generate
        % thousands of textures very fast and overwhelm your systems
        % memory
        Screen('Close', gratingtex)
    end
 % Now that we no longer need the window we can close that too. Use
 % 'CloseAll' just in case we missed any other windows or textures before
 % entering our while loop above
 Screen('CloseAll')
 
%%%%%%%%%%%%%%%%%%%%%%%%%%%% PLOTTING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % If the user hit the spacebar then they should see a plot of the saved
 % click positions. We access these positions from our stroke structure
 
 % Did the user hit the spacebar?
 if numel(fieldnames(Strokes))>0;
    % If so open a new figure (remember our Gui is a figure too so open a
    % new one)
    figure(2);
    % Plot the X and Y posiotions of the mouse with a marker the size of
    % our dot
    for i=1:numel(Strokes)
        hold on;
        plot(Strokes(i).X, Strokes(i).Y, 'sb', 'MarkerSize',...
                (Strokes(i).gratingDiameter)/2,'MarkerEdgeColor',[0 0 0],...
                'MarkerFaceColor',[.75 .75 .75])
        % set axis limits to be the size of the monitor
        xlim([0,ScreenSize]);
        ylim([0,monitorInfo.screenSizePixY]);
    end
 end 
catch
% If there is an error in our try block, let's
    % return the user to the familiar MATLAB prompt.
    ShowCursor;
    Screen('CloseAll');
    psychrethrow(psychlasterror);

end
 

