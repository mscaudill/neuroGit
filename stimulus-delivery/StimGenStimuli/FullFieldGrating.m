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
function FullFieldGrating(trials)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%This function generates and draws a full field grating with parameters
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
% Written by MSC 4-23-12 (Modified from DriftDemo2 in PTB)
% Modified by: MSC/2012-4-27, 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%% DEFAULTS FOR TESTING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%UNCOMMENT THIS SECTION FOR RUNNING STIMULUS AS STAND ALONE; COMMENT ABOVE
%CONFLICTING FUNCTION FULLFIELDGRATING(TRIALS)
% function [trials] = FullFieldGrating(stimType,table)
% if nargin<1
%     table = {'Spatial Frequency (cpd)', 0.04, .04, 0.04;...
%               'Temporal Frequency (cps)', 3, 1, 6;...
%               'Contrast (start,end,numsteps)', 1, .2, 1;...
%               'Orientation', 0, 30, 330;...
%               'Timing (delay,duration,wait) (s)', 1, 2, 1;...
%               'Blank', 0, [], []; 
%               'Randomize', 0, [], [];...
%               'Interleave', 0, [], [];...
%               'Repeats', 0, [], [];...
%               'Initialization Screen (s)', 5, [],[]};
%    stimType = 'Full-field Grating';
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
    grayLum = (whiteLum + blackLum)/2;
    
    % Now determine the pixel value of gray from the gray luminance
    grayPix = GammaCorrect(grayLum);
   

    % CONVERSION FROM DEGS TO PX AND SIZING INFO FOR SCREEN
    %conversion factor specific to monitor
    degPerPix = monitorInfo.degPerPix;
    % Size of the grating (in pix) that we will draw (1.5 times 
    % monitor width)
    visibleSize = 1.5*monitorInfo.screenSizePixX;
    
%%%%%%%%%%%%%%%%%%%%%%%%%% INITIAL SCREEN DRAW %%%%%%%%%%%%%%%%%%%%%%%%%%%    
% We start with a gray screen before generating our stimulus and displaying
% our stimulus. 

    % HIDE CURSOR FROM SCREEN
    HideCursor;
    % OPEN A SCREEN WITH A BG COLOR OF GRAY (RETURN POINTER W)
	[w screenRect]=Screen(screenNumber,'OpenWindow', grayPix);
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
    
% CREATE A DESTINATION RECTANGLE where the stimulus will be drawn to
    dstRect=[0 0 visibleSize visibleSize];
    %center the rectangle to the screen
    dstRect=CenterRect(dstRect, screenRect);
    
%%%%%%%%%%%%%%%%%%%%%% DRAW PRESTIM GRAY SCREEN %%%%%%%%%%%%%%%%%%%%%%%%%%%
% We call the function stimInitScreen to draw a screen to the window before
% the stimulus appears to allow for any adaptation that is need to a change
% in luminance
stimInitScreen(w,trials(1).Initialization_Screen,grayPix,ifiDuration)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
%%%%%%%%%%%%%%%%%%%%% CONSTRUCT AND DRAW TEXTURES %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This is the main body of the code. We will loop through our trials array
% structure, construct a grating texture based on the values for each trial
% and then execute the drawing in a while loop. All of this must be done in
% a single loop becasue we need to close the textures in the trial loop
% after using each texture becasue otherwise they will hang around in
% memory and cause the familiar Java runtime error: Out of memory.

% Exit Codes and initialization

    % This is a flag indicating we need to break from the trials
    % structure loop below. The flag becomes true (=1) if the
    % user presses any key
    exitLoop=0;

% MAIN LOOP OVER TRIALS TO CONSTRUCT TEXTURES AND DRAW THEM
    for trial=1:numel(trials)
        if exitLoop==1;
            break;
        end
       n=0; % This is a counter to shift our grating on each redraw
       
%%%%%%%%%%%%%%%%%%%% GET STIMULUS TIMING INFORMATION %%%%%%%%%%%%%%%%%%%%%%
    % The wait, duration, and delay are stored in trials structure. They
    % may vary over the trials if an LED was shown so get them for each
    % trial
    delay = trials(trial).Timing(1);
    duration = trials(trial).Timing(2);
    wait = trials(trial).Timing(3);
        
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%% CONSTRUCT STIMULUS TEXTURES %%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% To make a static grating texture of a drifting grating we need the
% contrast and the spatial frequency. For each trial in our structure we
% will get these two variables and convert them to appropraite units and
% then make our texture.

        % Check that the trial is not a blank trial
        if ~strcmp(trials(trial).Stimulus_Type, 'Blank')
            
            % Get the contrast and spatial frequency of the trial
            contrast = trials(trial).Contrast;
            spaceFreq = trials(trial).Spatial_Frequency;
        
            % convert to pixel units
            pxPerCycle = ceil(1/(spaceFreq*degPerPix));
            freqPerPix = (spaceFreq*degPerPix)*2*pi;
        
            % construct a 2-D grid of points to calculate our grating over
            % (note we extend by one period to account for shift of
            % grating later)
            x = meshgrid(-(visibleSize)/2:(visibleSize)/2 + pxPerCycle, 1);
        
            % compute the grating in Luminance units
            grating = grayLum + (whiteLum-grayLum)*contrast*cos(freqPerPix*x);
            
            % convert grating to pixel units
            grating = GammaCorrect(grating);
            
            % make the grating texture and save to gratingtex cell array
            % note it is not strictly necessary to save this to a cell
            % array since we will delete at the end of the loop but I want
            % to be explicit with the texture so that I am sure to delete
            % it when it is no longer needed in memory
            gratingtex{trial}=Screen('MakeTexture', w, grating);
        
        else % we have a blank trial
            gratingtex{trial}=Screen('MakeTexture', w,...
                                     grayPix*ones(visibleSize));
        end
        
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% DRAW TEXTURES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% In DRAW TEXTURES, we will obtain specific parameters such as the
% orientation etc for each trial in the trials struct. We will then draw an
% initial gray screen persisting for a time called delay. Then we will draw
% our grating using the parameters we pulled from the trials structure.
% Lastly we will draw another gray screen persisting for a time called
% wait. We repeat until the end of trials.

    % first check that the trial is not blank since these may not exist for
    % a blank trial
    if ~strcmp(trials(trial).Stimulus_Type, 'Blank')

        % Get the parameters for drawing the grating
        tempFreq = trials(trial).Temporal_Frequency;
        orientation = trials(trial).Orientation;
        
        % calculate amount to shift the grating with each screen update
        shiftperframe = tempFreq * pxPerCycle * ifiDuration;
    end
        
%%%%%%%%%%%%%%%%%%%%%%% PARALLEL PORT TRIGGER %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% After constructing the stimulus texture we are now ready to trigger the 
% parallel port and begin our draw to the screen. This function
% is located in the stimGen helper functions directory.
ParPortTrigger;
        
%%%%%%%%%%%%%%%%%%%% DRAW DELAY GRAY SCREEN %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        
    % DEVELOPER NOTE: Prior versions of stimuli used the func WaitSecs to
    % draw gray screens. This is a bad practice because the function sleeps
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
        
    % Display a gray screen while the vbl is less than delay time. NOTE
    % we are going to add 0.5*ifi to the vbl to give us some headroom
    % to take possible timing jitter or roundoff-errors into account.
        while (vbl < delayTime)
            % Draw a gray screen
            Screen('FillRect', w,grayPix);
            
            % update the vbl timestamp and provide headroom for jitters
            vbl = Screen('Flip', w, vbl + (waitframes - 0.5) * ifi);
            
            % exit the while loop and flag to one if user presses any key
            if KbCheck
                exitLoop=1;
                break;
            end
        end
        
%%%%%%%%%%%%%%%%%%%%%%%%%% DRAW GRATING TEXTURE %%%%%%%%%%%%%%%%%%%%%%%%%%%         
        % If the trial is a blank then we do not need to set src and dst
        % rect and calculate grating shifts etc
        if ~strcmp(trials(trial).Stimulus_Type, 'Blank')
            
            vbl=Screen('Flip', w);
            
            % Set the runtime of each trial by adding duration to vbl time
            runtime = vbl + duration;
            
            while (vbl < runtime)
                % calculate the offset of the grating and use the mod func
                % to ensure the grating snaps back once the border is
                % reached
                xoffset = mod(n*shiftperframe,pxPerCycle);
                n = n+1;
                
                % Set the source rect to excise the grating from
                srcRect = [xoffset 0 xoffset + visibleSize visibleSize];
                
                % Draw the grating texture for this trial to the dst
                % rectangle
                Screen('DrawTextures', w, gratingtex{trial}, srcRect,...
                    dstRect, orientation);
                
                % Draw a box at the bottom right of the screen to record
                % all screen flips using a photodiode. Please see the file
                % FlipCheck.m in the stimulus directory for further
                % explanation
                FlipCheck(w, screenRect, [whitePix, blackPix], n)
                
                % update the vbl timestamp and provide headroom for jitters
                vbl = Screen('Flip', w, vbl + (waitframes - 0.5) * ifi);
                
                % exit the while loop and flag to one if user presses any
                % key
                if KbCheck
                    exitLoop=1;
                    break;
                end
            end
            
             % if the trial is a blank, simply fill screen with a gray box    
        else 
            vbl=Screen('Flip', w);
            
            % Set the runtime of each trial by adding duration to vbl time
            runtime = vbl + duration;
            
            while (vbl < runtime)
                
                  n = n+1; % Add to counter for flipCheck box
                  
                % Draw a gray screen
                Screen('FillRect', w,grayPix);
                
                % Draw a box at the bottom right of the screen to record
                % all screen flips using a photodiode. Please see the file
                % FlipCheck.m in the stimulus directory for further
                % explanation
                FlipCheck(w, screenRect, [whitePix, blackPix], n)
              
                % update the vbl timestamp and provide headroom for jitters
                vbl = Screen('Flip', w, vbl + (waitframes - 0.5) * ifi);
                % exit the while loop and flag to one if user presses  key
                if KbCheck
                    exitLoop=1;
                    break;
                end
            end
        end        
        
%%%%%%%%%%%%%%%%%%%%% DRAW INTERSTIMULUS GRAY SCREEN %%%%%%%%%%%%%%%%%%%%%%
        % Between trials we want to draw a gray screen for a time of wait
        
        % Flip the screen and collect the time of the flip
        vbl=Screen('Flip', w);
        
        % We will loop until delay time referenced to the flip time
        waitTime = vbl + wait;
        % 
        while (vbl < waitTime)
            % Draw a gray screen
            Screen('FillRect', w,grayPix);
            
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
    Screen('Close', gratingtex{trial})
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

