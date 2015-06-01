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
function RadiallyMovingBar(trials)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%This function generates and draws a radially moving bar with parameters
%defined by the array of trials structures input. Trial structure arrays
%are automatically generated from the table values in the stimGen gui by
%the function trialsStruct.m so your stimulus should only take one input
%called trials. You can access parameters of a structure in the trials 
%structure array using dynamic field referencing (e.g. 
%trials(1).Orientation returns the orientaiton of trial 1). 
%As you write your stimulus you can test it by creating a Default trials 
%structure as done below so you can see if it is behaving as expected 
%before adding it to the stimGen gui.
%
% INPUTS:  TRIALSSTRUCT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Written by MSC 5-18-12
% Modified by:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%% DEFAULTS FOR TESTING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%UNCOMMENT THIS SECTION FOR RUNNING STIMULUS AS STAND ALONE; COMMENT ABOVE
%CONFLICTING FUNCTION RADIALLYMOVINGBAR(TRIALS)
% function [trials] = RadiallyMovingBar(stimType,table)
% if nargin<1
%     table = {'Screen Shade (0-255)', 128, [], [];...
%               'Bar Shade', 0, [], [];...
%               'Width (degs)', 5, 1, 5;...
%               'Length (degs)', 30, 1, 30;...  
%               'Speed (degs/sec)', 10, 1, 10;...
%               'Orientation', 0, 30, 330;...
%               'Timing (delay,[],wait) (s)', 0.1, [], 0.1;...
%               'Blank', 0, [], []; 
%               'Randomize', 0, [], [];...
%               'Interleave', 0, [], [];...
%               'Repeats', 0, [], []};
%    stimType = 'Radially Moving Bar';
%    
% end
% trials = trialStruct(stimType, table);
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

    % COLOR INFORMATION OF SCREEN
    % Get black, white and gray color values for the current monitor
    whitePix = WhiteIndex(screenNumber);
    blackPix = BlackIndex(screenNumber);
    
    %Convert balck and white to luminance values to determine gray
    %luminance
    whiteLum = PixToLum(whitePix);
    blackLum = PixToLum(blackPix);
    
    % Now determine the pixel value of gray from the gray luminance
    grayPix = GammaCorrect((whiteLum + blackLum)/2);

    % CONVERSION FROM DEGS TO PX AND SIZING INFO FOR SCREEN
    %conversion factor specific to monitor
    degPerPix = monitorInfo.degPerPix;
    % Size of the area to draw bars to (in pix)( 90% of screen width 
    % monitor width)
    visibleSizeX = round(1.0*monitorInfo.screenSizePixX);
    visibleSizeY = round(1.0*monitorInfo.screenSizePixY);
%%%%%%%%%%%%%%%%%%%%%%%%%% INITIAL SCREEN DRAW %%%%%%%%%%%%%%%%%%%%%%%%%%%    
% We start with a gray screen before generating our stimulus and displaying
% our stimulus.

    % HIDE CURSOR FROM SCREEN
    HideCursor;
    % OPEN A SCREEN WITH A BG COLOR OF GRAY (RETURN POINTER W)
	[w, screenRect]=Screen(screenNumber,'OpenWindow', grayPix);
    
%%%%%%%%%%%%%%%%%%%%%%%%% PREP SCREEN FOR DRAWING %%%%%%%%%%%%%%%%%%%%%%%%%

% SCRIPT PRIORITY LEVEL
% Query for the maximum priority level availbale on this system. This
% determines the priority level of the matlab thread (0= normal,
% 1=high, 2=realTime priority) note that a setting of 2 may cause the
% keyboard to be unresponsive. You may want to play with this number if
% you have trouble recovering the screen back
    
    priorityLevel=MaxPriority(w);
    Priority(priorityLevel);

% INTERFRAME INTERVAL INFO   
    % Get the montior inter-frame-interval 
    ifi = Screen('GetFlipInterval',w);
    
    %on old slow machines we may not be able to update every ifi. If your
    %graphics processor is too slow you can buy a better one or adjust the
    %number of frames to wait between flips below
    
    waitframes = 1; %I expect most new computers can handle updates at ifi
    ifiDuration = waitframes*ifi;
    
    
%%%%%%%%%%%%%%%%%% GET STIMULUS SHADE AND TIMING INFORMATION %%%%%%%%%%%%%%
        
% The shades are currently not parameters so get the shade
% information from the first trial only. Note  the shade is a fraction of
% 255 to be multiplied by the range in luminance values ( so for example if
% white = 100 cd/m^2, black = 0 then gray values of 128 mean gray = 50
% cd/m^2 so we call Gamma correct to perform this operation
    ScreenShade = GammaCorrect(trials(1).Screen_Shade/whitePix*...
                                (whiteLum + blackLum));
    BarShade = GammaCorrect(trials(1).Bar_Shade/whitePix*...
                                (whiteLum + blackLum));
    
% The wait and delay are stored in trials structure. They
% are the same for all trials so just get timing info from 1st trial. Note
% there is no duration time here becasue that will be determined by the
% speed of the bar
    delay = trials(1).Timing(1);
    wait = trials(1).Timing(3);
        
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
%%%%%%%%%%%%%%%%%%%%% CONSTRUCT AND DRAW TEXTURES %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This is the main body of the code. We will loop through our trials array
% structure, construct a bar texture based on the values for each trial
% and then execute the drawing in a while loop. All of this must be done in
% a single loop becasue we need to close the textures in the trial loop
% after using each texture becasue otherwise they will hang around in
% memory and cause the familiar Java runtime error: Out of memory.

% Exit Codes and initialization

    % This is a flag indicating we need to break from the trials
    % structure loop below. The flag becomes true (=1) if the
    % user presses any key
    exitLoop=0;
                
    n=0;  % This is a counter for flipCheck box 

% MAIN LOOP OVER TRIALS TO CONSTRUCT TEXTURES AND DRAW THEM
    for trial=1:numel(trials)
        if exitLoop==1;
            break;
        end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%% CONSTRUCT STIMULUS TEXTURES %%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% To make a static bar texture of a drifting grating we need the
% contrast, the bar length, and the bar width. For each trial in our 
% structure we will get these two variables and convert them to appropraite
% units and then make our texture.

        % Check that the trial is not a blank trial
        if ~strcmp(trials(trial).Stimulus_Type, 'Blank')
            
            % Get length and width of the bar for this trial
            length = trials(trial).Length;
            width = trials(trial).Width;
        
            % Convert the length and width to pixel units
            lengthPix = length/degPerPix;
            widthPix = width/degPerPix;
        
            % Our source texture will be a full screen texture with a shade
            % equal to the bar shade
            barTex{trial} = Screen('MakeTexture',w,...
                                BarShade*ones(visibleSizeX));
                            
        else % we have a blank trial
            barTex{trial} = Screen('MakeTexture',w,...
                                ScreenShade*ones(visibleSizeX));
        end
        
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% DRAW TEXTURES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% In DRAW TEXTURES, we will obtain specific parameters such as the
% orientation etc for each trial in the trials struct. We will then draw an
% initial blank screen persisting for time called delay. Then we will draw
% our bar using the parameters we pulled from the trials structure.
% Lastly we will draw another blank screen persisting for a time called
% wait. We repeat until the end of trials.

% Get the parameters for drawing the bar to the screen (speed and orien.)
        speed = trials(trial).Speed;
        orientation = trials(trial).Orientation;
        
%%%%%%%%%%%%%%%%%%%%%%% PARALLEL PORT TRIGGER %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% After constructing the stimulus texture we are now ready to trigger the 
% parallel port and begin our draw to the screen. This function
% is located in the stimGen helper functions directory.

%ParPortTrigger;
        
%%%%%%%%%%%%%%%%%%%%%%%%% DRAW DELAY SCREEN %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        
% DEVELOPER NOTE: Prior versions of stimuli used the func WaitSecs to
% draw delay screens. This is a bad practice because the function sleeps
% the matlab thread making the computer unresponsive to KbCheck clicks.
% In addition PTB only guarantees the accuracy of WaitSecs to the
% millisecond scale whereas VBL timestamps described below uses
% GetSecs() a highly accurate submillisecond estimate of the system
% time. All times should be referenced to this estimate for better
% accuracy.

% We start by performing an initial screen flip using Screen, we return
% back a time called vbl. This value is a high precision time estimate
% of when the graphics card performed a buffer swap. This time is what
% all of our times will be referenced to. More details at
% http://psychtoolbox.org/FaqFlipTimestamps
        vbl=Screen('Flip', w);
    
    % The first time element of the stimulus is the delay from trigger
    % onset to stimulus onset
        delayTime = vbl + delay;
        
    % Display a blank screen while the vbl is less than delay time. NOTE
    % we are going to add 0.5*ifi to the vbl to give us some headroom
    % to take possible timing jitter or roundoff-errors into account.
        while (vbl < delayTime)
            % Draw a screen with shade matched to screen shade user chose
            Screen('FillRect', w,ScreenShade);
            
            % update the vbl timestamp and provide headroom for jitters
            vbl = Screen('Flip', w, vbl + (waitframes - 0.5) * ifi);
            
            % exit the while loop and flag to one if user presses any key
            if KbCheck
                exitLoop=1;
                break;
            end
        end
        
%%%%%%%%%%%%%%%%%%%%%%%%%%%% DRAW BAR TEXTURE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%         
        % Perform initial flip to get accurate timestamp
        vbl=Screen('Flip', w);
        % set the source rectangle ( i.e. the excised rectangle from the
        % barTex)
        srcRect = [0 0 widthPix lengthPix];
        
        % Set the dstRect the size of the bar for this trial
        dstRect = [0 0 widthPix lengthPix];
        
        % PLACE BAR ON SCREEN
        % Because your screen is likely not square, we will set the start
        % positions and end positions of the bar to lie along an ellipse
        % whos major and minor axis correspond to the size of your screen
        % in horzontal and vertical direction. Why do we do this instead of
        % a circle? We do this because we want to ensure that when the bar
        % is being displayed that it is somwhere within the viewable area
        % of the screen. If we place the bar on a circle with a radius =
        % sqrt(monitorWidth^2+monitorHeight^2), the bar would sometimes be
        % shown in screen areas that are not visible. This would make
        % analysis difficult becasue you would have to figure out whether
        % the bar was on the display at a given time based on its velocity
        % and size and time. It is easier just to start the bar at one of
        % the screen edges.
        
        % Convert degrees to radians
        radOrien = orientation*pi/180;
        % Determine the ellipsoidal radius values (not angle dependent)
        radius = (visibleSizeX/2*visibleSizeY/2)/sqrt((visibleSizeY/2*...
                    cos(radOrien))^2+(visibleSizeX/2*sin(radOrien))^2);
        % Conver the angle and radius values into cartesian coordinates
        [x,y] = pol2cart(radOrien,radius);
        % The upper left of our screen is x,y=(0,0) so we shift our
        % cordinates to match this coordinate system
        x = x + visibleSizeX/2;
        y = y + visibleSizeY/2;
        
        % Below is some testing to make sure the bar is starting in the
        % right position.
        %hold on;
        %plot(x,y,'r*')
        %x = x+visibleSizeX/2;
        %y = abs(y-visibleSizeY/2);
        
        % Center the destination rectangle on the cartesian coordinates of
        % the ellipse
        dstRect = CenterRectOnPoint(dstRect, x, y);
        
        % Now we must determine the duration of the stimulus based on the
        % speed of the bar for each trial since the speed is a potential
        % parameter. The duration will be the distance divided by the bar
        % speed
        runtime = vbl + radius/(speed/degPerPix);
        
        while (vbl < runtime)
            n = n+1;
            % Draw the bar texture for this trial to the dstRect and set it
            % to the proper orinetation for this trial
            Screen('DrawTextures', w, barTex{trial}, srcRect, dstRect,...
                    orientation)
                
            % Draw a box at the bottom right of the screen to record all 
            % screen flips using a photodiode. Please see the file
            % FlipCheck.m in the stimulus directory for further explanation
            FlipCheck(w, screenRect, [whitePix, blackPix], n)
                
            % update the vbl timestamp and provide headroom for jitters
            vbl = Screen('Flip', w, vbl + (waitframes - 0.5) * ifi);
                
            % Now update the dstRect position
            % Not the sign convention ensures the bar moves *toward* the
            % desired angle
            x = x - speed*cos(radOrien);
            y = y - speed*sin(radOrien);
            % reset dstRect position
            dstRect = CenterRectOnPoint(dstRect, x, y);
            
            % exit the while loop and flag to one if user presses any key
            if KbCheck
                exitLoop=1;
                break;
            end
        end
        
%%%%%%%%%%%%%%%%%%%%% DRAW INTERSTIMULUS SCREEN %%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Between trials we want to draw a blank screen for a time of wait
        
        % Flip the screen and collect the time of the flip
        vbl=Screen('Flip', w);
        
        % We will loop until delay time referenced to the flip time
        waitTime = vbl + wait;
        % 
        while (vbl < waitTime)
            % Draw a gray screen
            Screen('FillRect', w,ScreenShade);
            
            % update the vbl timestamp and provide headroom for jitters
            vbl = Screen('Flip', w, vbl + (waitframes - 0.5) * ifi);
            
            % exit the while loop and flag to one if user presses any key
            if KbCheck
                exitLoop=1;
                break;
            end
        end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % IMPORTANT YOU MUST CLOSE EACH TEXTURE IN THE LOOP OTHERWISE THESE
    % OBJECTS WILL REMAIN IN MEMORY FOR SOME TIME AND ULTIMATELY LEAD TO
    % JAVA OUT OF MEMORY ERRORS!!!
    Screen('Close', barTex{trial})
    end
    
    % Restore normal priority scheduling in case something else was set
    % before:
    Priority(0);
	
	%The same commands wich close onscreen and offscreen windows also close
	%textures. We still need to close any screens opened prior to the trial
	%loop ( the prep screen for example)
	Screen('CloseAll');
    
catch 
    %this "catch" section executes in case of an error in the "try" section
    %above.  Importantly, it closes the onscreen window if its open.
    Screen('CloseAll');
    Priority(0);
    psychrethrow(psychlasterror);
end

%%%%%%%%%%%%%%%%%%%%%%%% Turn On PTB verbose warnings %%%%%%%%%%%%%%%%%%%%
Screen('Preference', 'Verbosity',3);
% please see the following page for an explanation of this function
%  http://psychtoolbox.org/FaqWarningPrefs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
java.lang.Runtime.getRuntime().gc % call garbage collect (likely useless)
return
        
end

