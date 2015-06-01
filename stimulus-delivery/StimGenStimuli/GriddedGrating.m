function GriddedGrating(trials)
%Gridded grating generates and draws a set of gratings drawn at locations
%that are determined by the user defined rows and columns. The only input
%needed is trials. Trials structures are automatically generated from the
%table values in the gui by trialsStruct.m so your stimulus should take
%only one input namely trials. You can access parameters of a structure in
%the trials structure array using dynamic field referencing (e.g.
%trials(1).Orientation ... returns the orientaiton of trial 1). As you
%write your stimulus you can test it by creating a Default trials structure
%as done below so you can see if it is behaving as expected before adding
%it to the stimGen gui.
%
% INPUTS:  TRIALSSTRUCT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Written by MSC 11-06-12 
% Modified by: MSC/
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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

%%%%%%%%%%%%%%%%%%%%%% DEFAULTS FOR TESTING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%UNCOMMENT THIS SECTION FOR RUNNING STIMULUS AS STAND ALONE; COMMENT ABOVE
%CONFLICTING FUNCTION FULLFIELDGRATING(TRIALS)
% function [trials] = GriddedGrating(stimType,table)
%  if nargin<1
%     table = { 'Rows', 1, 1, 2;...
%               'Columns', 1, 1, 2;...
%               'Spatial Frequency (cpd)', .04, .04, .04;...
%               'Temporal Frequency (cps)', 3, 1, 3;...
%               'Contrast (start,end,numsteps)', 1, 1, 1;...
%               'Orientation', 30, 30, 30 ;...
%               'Timing (delay,duration,wait) (s)', 1, 1, 0;...
%               'Mask Type (Sq., Circ.)', 'Square',[],[];...
%               'Blank', 0, [], [];...
%               'Randomize', 0, [], [];...
%               'Interleave', 0, [], [];...
%               'Repeats', 0, [], []};
%           stimType = 'Gridded Grating';
%     
%  end
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

% When Screen('OpenWindow',w,color) is called, PTB performs many checks of
% your system. The time it takes to perform these checks depends on the
% noisiness of your system (up to two seconds on 2-photon rig). During this
% time it displays a white screen which is obviously not good for visual
% stimulation. We can disable the startup screen using the following. The
% sreen will now be black before visual stimulus
Screen('Preference', 'VisualDebuglevel', 3);
% see http://psychtoolbox.org/FaqBlueScreen for a reference
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
    
%%%%%%%%%%%%%%%%%%%%%%%%%% INITIAL SCREEN DRAW %%%%%%%%%%%%%%%%%%%%%%%%%%%    
% We start with a gray screen before generating our stimulus and displaying
% our stimulus.

    % HIDE CURSOR FROM SCREEN
    HideCursor;
    % OPEN A SCREEN WITH A BG COLOR OF GRAY (RETURN POINTER W)
	[w, screenRect]=Screen(screenNumber,'OpenWindow', grayPix);
    
    % ENABLE ALPHA BLENDING OF GRATING WITH THE MASK
    Screen('BlendFunction', w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

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
    stimInitScreen(w,trials(1).Initialization_Screen,grayPix,ifiDuration)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %%%%%%%%%%%%%%%%%%%% GET THE GRATING SIZE IN PIXELS %%%%%%%%%%%%%%%%%%%
    % The grating diameter will be determined from the size of the area of
    % an individual grid. It will be the size of the smallest dimension of
    % each grid box across all trials
    diamPix = min(monitorInfo.screenSizePixX/max([trials(:).Columns]),...
                  monitorInfo.screenSizePixY/max([trials(:).Rows]));
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%% CONSTRUCT AND DRAW TEXTURES %%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This is the main body of the code. We will loop through our trials array
% structure, construct a mask & grating texture from values for each trial
% and then execute the drawing in a while loop. All of this must be done in
% a single loop becasue we need to close the textures in the trial loop
% after using each texture becasue otherwise they will hang around in
% memory and cause the familiar Java runtime error: Out of memory.

% Exit Codes and initialization
    exitLoop=0; %This is a flag indicating we need to break from the trials
                % structure loop below. The flag becomes true (=1) if the
                % user presses any key
    %n=0;        % This is a counter to shift our grating on each redraw
    
% MAIN LOOP OVER TRIALS TO CONSTRUCT TEXS AND DRAW THEM
    for trial=1:numel(trials)
        if exitLoop==1;
            break;
        end
        n=0;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%% CONSTRUCT STIMULUS & MASK TEXTURES %%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% To make a stating grating texture of a drifting grating we need the
% contrast and the spatial frequency. For each trial in our structure we
% will get these two variables and convert them to appropraite units and
% then make our texture. In the end we will have a cell array of textures
% indexed by the trial number

%%%%%%%%%%%%%%%%%%%%% CONSTRUCT GRATING TEXTURE %%%%%%%%%%%%%%%%%%%%%%%%%%%

        % Check that the trial is not a blank trial. If we do have a blank
        % trial then the grating texture will just be a gray screen
        % executed in the draw loop below.
        
        if ~strcmp(trials(trial).Stimulus_Type, 'Blank')                    
            % we construct a grating texture from parameters of the trial
            % Get the contrast, spatial frequency and diameter of the trial
            contrast = trials(trial).Contrast;
            spaceFreq = trials(trial).Spatial_Frequency;
            
            % convert to pixel units
            pxPerCycle = ceil(1/(spaceFreq*degPerPix));
            freqPerPix = (spaceFreq*degPerPix)*2*pi;
            
            % construct a 2-D grid of points to calculate our grating over
            % (note we center the grating and extend it by one period)
            x = meshgrid(-(diamPix)/2:(diamPix)/2 + pxPerCycle, 1);
        
            % compute the grating in Luminance values
            grating = grayLum + (whiteLum-grayLum)*contrast*cos(freqPerPix*x);
            
            % convert the grating to pixel values
            grating = GammaCorrect(grating);
            
            % make the grating texture and save to gratingtex cell array
            gratingtex{trial}=Screen('MakeTexture', w, grating);
        
        end
%%%%%%%%%%%%%%%%%%%%%%%% CONSTRUCT MASK TEXTURE %%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Check that the trial is not blank, if so, no mask needs to be
    % constructed
    if ~strcmp(trials(trial).Stimulus_Type, 'Blank')      
        % make a 2-D matrix of gray values (note we add one along
                % each dimension so the mask will be centered about the x,y
                % grating position specified by the user)
                mask = ones(diamPix+1, diamPix+1, 2) * grayPix; 
            
                % make a 2-D grid over mask positions (mx,my) to calculate
                % the mask value
                [mx,my]=meshgrid(-diamPix/2:diamPix/2,...
                                    -diamPix/2:diamPix/2);
            
                % Calculate mask transparency vals (i.e. the 3rd Dimension
                % over the gridpoints (note 255 is fully transparent)
                mask(:, :, 2)=255 * (1-(mx.^2 + my.^2 <=...
                                                          (diamPix/2).^2));
            
                %make the mask texture
                masktex{trial}=Screen('MakeTexture', w, mask);
    end
    
%%%%%%%%%%%%%%% OBTAIN GRATING PARAMS FROM TRIALSSTRUCT %%%%%%%%%%%%%%%%%%
    % We only obtain grating parameters if trial is not blank
    if ~strcmp(trials(trial).Stimulus_Type, 'Blank')
        
        % Get the parameters for drawing the grating
        tempFreq = trials(trial).Temporal_Frequency;
        orientation = trials(trial).Orientation;
        
        % calculate amount to shift the grating with each screen update
        shiftperframe = tempFreq * pxPerCycle * ifiDuration;
        
        % Calculate the center of the grating using the grid number and the
        % size of the screen in pixels. We will create a dstRect where we
        % will draw the grating and the mask to based on this calculation.
        
        xLoc = monitorInfo.screenSizePixX/(max([trials(:).Columns]*2)) *...
            (2*trials(trial).Columns-1);
        
        yLoc = monitorInfo.screenSizePixY/(max([trials(:).Rows]*2)) *...
            (2*trials(trial).Rows-1);
        
        % create destination rectangle (size of grating)        
        dstRect = [0 0 diamPix+1 diamPix+1];
        % center dstRect about user selected x,y coordinate
        dstRect=CenterRectOnPoint(dstRect,xLoc,yLoc);
    end
    
%%%%%%%%%%%%%%%%%%%%%%% PARALLEL PORT TRIGGER %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% After constructing the stimulus texture we are now ready to trigger the 
% parallel port and begin our draw to the screen. This function
% is located in the stimGen helper functions directory.

%ParPortTrigger;
        
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
%%%%%%%%%%%%%%%%%%%%%%%%%% DRAW TEXTURES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% In DRAW TEXTURES, we will obtain specific parameters such as the
% orientation etc for each trial in the trials struct. We will then draw an
% initial gray screen persisting for a time called delay. Then we will draw
% our grating using the parameters we pulled from the trials structure.
% Lastly we will draw another gray screen persisting for a time called
% wait. We repeat until the end of trials.
       
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
        % rect based on diameter. In fact they may not be defined in the
        % trials structure if the diameter is a parameter the user selected
        % because a blank adds a NaN to the parameter arrays struct
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
                
                % Set the source rect to excise the grating from (note
                % again we add 1 to ensure we center properly)
                srcRect = [xoffset 0 xoffset+diamPix+1 diamPix+1];
                
                % Set the maskSrcRect
                mSrcRect = [0 0 diamPix+1 diamPix+1];
                
                % Draw the grating texture for this trial to the dest
                % rectangle
                Screen('DrawTextures', w, gratingtex{trial}, srcRect,...
                    dstRect, orientation);
                
                % Draw the mask texture over the grating texture
                if ~isempty(masktex{trial})
                    Screen('DrawTextures', w, masktex{trial}, mSrcRect,...
                        dstRect, orientation);
                end
                
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
        else % we have a blank trial
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
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % IMPORTANT YOU MUST CLOSE EACH TEXTURE IN THE LOOP OTHERWISE THESE
    % OBJECTS WILL REMAIN IN MEMORY FOR SOME TIME AND ULTIMATELY LEAD TO
    % JAVA OUT OF MEMORY ERRORS!!!
        if ~strcmp(trials(trial).Stimulus_Type, 'Blank')
            Screen('Close', gratingtex{trial})
                if ~isempty(masktex{trial})
                    Screen('Close', masktex{trial})
                end
        end
    end
    %
    
     % Restore normal priority scheduling in case something else was set
    % before:
    Priority(0);
	
	%The same commands wich close onscreen and offscreen windows also close
	%textures.
	Screen('CloseAll');
    
catch 
    %this "catch" section executes in case of an error in the "try" section
    %above.  Importantly, it closes the onscreen window if its open.
    Screen('CloseAll');
    Priority(0);
    psychrethrow(psychlasterror);
end

%%%%%%%%%%%%%%%%%%%%%%%% Turn Off PTB verbose warnings %%%%%%%%%%%%%%%%%%%%
Screen('Preference', 'Verbosity',3);
% please see the following page for an explanation of this function
%  http://psychtoolbox.org/FaqWarningPrefs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
return
        
