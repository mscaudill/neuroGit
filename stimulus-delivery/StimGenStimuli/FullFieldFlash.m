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
 function FullFieldFlash(trials)
% This function generates and draws a Full-field Flash with parameters
%defined by the array of trials structures (see trialStruct.m). Trials
%structures are automatically generated from the table values in the gui
%by trialsStruct.m so your stimulus should take only one input namely 
%trials. You can access parameters of a structure in the trials structure 
%array using dynamic field referencing (e.g. trials(1).Orientation ...
%returns the orientaiton of trial 1). As you write your stimulus you can
%test it by creating a Default trials structure as done below so you can
%see if it is behaving as expected before adding it to the stimGen gui.
%
% INPUTS:  TRIALSSTRUCT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% Written by MSC 5-3-12 (Modified from DriftDemo2 in PTB)
% Modified by: MSC/, 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%% DEFAULTS FOR TESTING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%UNCOMMENT THIS SECTION FOR RUNNING STIMULUS AS STAND ALONE; COMMENT ABOVE
%CONFLICTING FUNCTION FULLFIELDGRATING(TRIALS)
% function [trials] = FullFieldFlash(stimType,table)
% if nargin<1
%     table = {'Delay Shade (0-255)',255, [], [];...
%              'Duration Shade', 128, [], [];...
%              'Wait Shade', 0, [], [];...
%              'Timing (delay,duration,wait) (s)', 1, 1, 1;...
%              'Repeats', 2, [], []};
%    stimType = 'Full-field Flash';
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
    
    % GET SIZING INFO FOR SCREEN
    % Size of the texture (in pix) that we will draw (1.5 times 
    % monitor width)
    visibleSize = 1.5*monitorInfo.screenSizePixX;
%%%%%%%%%%%%%%%%%%%%%%%%%% INITIAL SCREEN DRAW %%%%%%%%%%%%%%%%%%%%%%%%%%%    
% We start with a black screen before generating and displaying our
% stimulus. This is done to try and prevent as opposed to gray becasue the
% screen will start as black during PTB Checks (see comment two above). So
% this shade choice will ensure that the first shade change is actually our
% stimulus and not due to an errant screen open window command.

    % HIDE CURSOR FROM SCREEN
    HideCursor;
    
    % COLOR INFORMATION OF SCREEN
    whitePix = WhiteIndex(screenNumber);
    blackPix = BlackIndex(screenNumber);
    
    %Convert balck and white to luminance values to determine gray
    %luminance
    whiteLum = PixToLum(whitePix);
    blackLum = PixToLum(blackPix);
    
    % Now determine the pixel value of gray from the gray luminance
    grayPix = GammaCorrect((whiteLum + blackLum)/2);
    
    % OPEN A SCREEN WITH A BG COLOR OF BLACK (RETURN POINTER W)
	[w screenRect]=Screen(screenNumber,'OpenWindow',blackPix);
    
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
    %ifiDuration = waitframes*ifi;
    
% CREATE A DESTINATION RECTANGLE where the stimulus will be drawn to
    dstRect=[0 0 visibleSize visibleSize];
    %center the rectangle to the screen
    dstRect=CenterRect(dstRect, screenRect);
% CREATE A SOURCE RECTANGLE (IN THIS CASE SAME AS DESTINATION RECT)
    srcRect = dstRect;

%%%%%%%%%%%%%%%%%%%% GET STIMULUS TIMING INFORMATION %%%%%%%%%%%%%%%%%%%%%%
    
    % The wait, duration, and delay are stored in trials structure. They
    % are the same for all trials so just get timing info from 1st trial
    delay = trials(1).Timing(1);
    duration = trials(1).Timing(2);
    wait = trials(1).Timing(3);
    
    %%%%%%%%%%%%%%%%%%%%%% DRAW PRESTIM GRAY SCREEN %%%%%%%%%%%%%%%%%%%%%%%
    % We call the function stimInitScreen to draw a screen to the window
    % before the stimulus appears to allow for any adaptation that is need
    % to a change in luminance
    %stimInitScreen(w,trials(1).Initialization_Screen,grayPix,ifiDuration)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
%%%%%%%%%%%%%%%%%%%%% CONSTRUCT AND DRAW TEXTURES %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This is the main body of the code. We will loop through our trials array
% structure, construct a shade texture based on the values for each trial
% and then execute the drawing in a while loop. All of this must be done in
% a single loop becasue we need to close the textures in the trial loop
% after using each texture becasue otherwise they will hang around in
% memory and cause the familiar Java runtime error: Out of memory.

% Exit Codes and initialization

    % This is a flag indicating we need to break from the trials
    % structure loop below. The flag becomes true (=1) if the
    % user presses any key
    exitLoop=0;
                
    n=0;  % This is a counter to shift our grating on each redraw
    
% MAIN LOOP OVER TRIALS TO CONSTRUCT TEXTURES AND DRAW THEM
    for trial=1:numel(trials)
        if exitLoop==1;
            break;
        end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%% CONSTRUCT STIMULUS TEXTURES %%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We will make a shade texture based on the values of the delay, duration
% and wait shades provided in the first trial of the trial array structure.
       
        delayTex{trial}= Screen('MakeTexture', w,...
                       GammaCorrect(trials(1).Delay_Shade/whitePix*...
                       (whiteLum + blackLum))* ones(visibleSize));
                                 
        durationTex{trial}= Screen('MakeTexture', w,...
                        GammaCorrect(trials(1).Duration_Shade/whitePix*...
                        (whiteLum + blackLum))* ones(visibleSize));
                                 
        waitTex{trial}= Screen('MakeTexture', w,...
                            GammaCorrect(trials(1).Wait_Shade/whitePix*...
                            (whiteLum + blackLum))* ones(visibleSize));
                              
%%%%%%%%%%%%%%%%%%%%%%% PARALLEL PORT TRIGGER %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% After constructing the stimulus texture we are now ready to trigger the 
% parallel port and begin our draw to the screen. This function
% is located in the stimGen helper functions directory.
%ParPortTrigger;
%%%%%%%%%%%%%%%%%%%%%%%%%% DRAW DELAY TEXTURE %%%%%%%%%%%%%%%%%%%%%%%%%%%         
    
    % We start by performing an initial screen flip using Screen, we return
    % back a time called vbl. This value is a high precision time estimate
    % of when the graphics card performed a buffer swap. This time is what
    % all of our times will be referenced to. More details at
    % http://psychtoolbox.org/FaqFlipTimestamps
        vbl=Screen('Flip', w);
        
        % Set the runtime of each epoch of the stimulus by adding duration 
        % to vbl time
        runtime = vbl + delay;
        
        while (vbl < runtime)
            Screen('DrawTextures', w, delayTex{trial}, srcRect,...
                    dstRect);
            
            % update the vbl timestamp and provide headroom for jitters
            vbl = Screen('Flip', w, vbl + (waitframes - 0.5) * ifi);
            
            % exit the while loop and flag to one if user presses any key
            if KbCheck
                exitLoop=1;
                break;
            end
        end
        
%%%%%%%%%%%%%%%%%%%%%%%%%% DRAW DURATION TEXTURE %%%%%%%%%%%%%%%%%%%%%%%%%%
        vbl=Screen('Flip', w);
        
        % Set the runtime of each trial by adding duration to vbl time
        runtime = vbl + duration;
        
        n = 0; % counter for our flipCheck box
        while (vbl < runtime)
            n = n+1;
            % Draw the full field stimulus flash to the screen
            Screen('DrawTextures', w, durationTex{trial}, srcRect,...
                    dstRect);
            % Draw a box at the bottom right of the screen to record all 
            % screen flips using a photodiode. Please see the file
            % FlipCheck.m in the stimulus directory for further explanation
            FlipCheck(w, screenRect, [grayPix, blackPix], n)
            
            % update the vbl timestamp and provide headroom for jitters
            vbl = Screen('Flip', w, vbl + (waitframes - 0.5) * ifi);
            
            % exit the while loop and flag to one if user presses any key
            if KbCheck
                exitLoop=1;
                break;
            end
        end
        
%%%%%%%%%%%%%%%%%%%%%%%%%% DRAW WAIT TEXTURE %%%%%%%%%%%%%%%%%%%%%%%%%%%         
        vbl=Screen('Flip', w);
        
        % Set the runtime of each trial by adding duration to vbl time
        runtime = vbl + wait;
        
        while (vbl < runtime)
            Screen('DrawTextures', w, waitTex{trial}, srcRect,...
                    dstRect);
            
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
    Screen('Close', [delayTex{trial},durationTex{trial},waitTex{trial}])
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
