function AnnularSimpleCenterSurround(trials)
% draws the simple center surround stimulus (Center alone,
% cross-orientations, iso-orientation, surround alone) but with annular
% surrounds.
% INPUTS:  TRIALSSTRUCT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Written by MSC 5-6-2016
% Modified by:
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

%%%%%%%%%%%%%%%%%%%%%% DEFAULTS FOR TESTING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%UNCOMMENT THIS SECTION FOR RUNNING STIMULUS AS STAND ALONE; COMMENT ABOVE
%CONFLICTING FUNCTION 
%  function [trials] = AnnularSimpleCenterSurround(stimType,table)
%  if nargin<1
%      table = {'Surround Spatial Frequency (cpd)', 0.04, .04, 0.04;...
%               'Center Spatial Frequency (cpd)', 0.04, .04, 0.04;...
%               'Surround Temporal Frequency (cps)', 3, 1, 3;...
%               'Center Temporal Frequency (cps)', 3, 1, 3;...
%               'Border Diameter (deg)', 16, [], [];...
%               'Center Grating Diameter (deg)', 15, [], [];
%               'Surround Diameter (deg)', 25, [], [];
%               'Surround Contrast', 1, 1, 1;...
%               'Center Contrast', 1, 1, 1;...
%               'Center Orientation', 270, 45, 270;...
%               'Surround Condition', 1, 1, 5;...
%               'Stimulus Center (degs)', 0, 0, [];...
%               'Timing (delay,duration,wait) (s)', 1, 2, 5;...
%               'Blank', 0, [], [];... 
%               'Randomize', 0, [], [];...
%               'Interleave', 1, [], [];
%               'Repeats', 0, [], [];...
%               'Initialization Screen',2,[],[];...
%               'Interleave Timing',1, 2, 4};
%  stimType = 'Annular Simple Center-surround Grating';
%     
%  end
%  trials = trialStruct(stimType, table);
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
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
    
    %%%%%%%%%%%%%%%%%%%%%% GET SPECIFIC MONITOR INFORMATION %%%%%%%%%%%%%%%

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
    % Size of the screen area we will draw to. It is larger than the
    % screens largest dimensions so the stimulus we rotated will always
    % fill the screen.
    visibleSize = 1.5*monitorInfo.screenSizePixX;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%% INITIAL SCREEN DRAW %%%%%%%%%%%%%%%%%%%%%%%%    
    % We start with a gray screen before generating our stimulus and 
    % displaying our stimulus.

    % HIDE CURSOR FROM SCREEN
    HideCursor;
    % OPEN A SCREEN WITH A BG COLOR OF GRAY (RETURN POINTER W)
    [w, screenRect]=Screen(screenNumber,'OpenWindow',grayPix);
        
    % We are going to use the alpha channel (R,G,B,alpha) which controls 
    % tranparencies to 'blend' gratings at boundaries. We first assert that
    % the graphics card supports this blending:
    AssertGLSL;
    
    % ENABLE ALPHA BLENDING OF GRATING WITH THE MASK
    Screen('BlendFunction', w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    % Create a special texture drawing shader for blending:
    glsl = MakeTextureDrawShader(w, 'SeparateAlphaChannel');
    
    %%%%%%%%%%%%%%%%%%%%%%%%% PREP SCREEN FOR DRAWING %%%%%%%%%%%%%%%%%%%%%

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
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %%%%%%%%%%%%%%%%%%%%% CONSTRUCT & DRAW TEXTURES %%%%%%%%%%%%%%%%%%%%%%%%
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % This is the main body of the code. We will loop through the trials
   % structures and construct a surround grating, a mask, a center grating
   % and an inner mask from the stimulus paprameters of each trial and
   % execute the drawing in a while loop. All of this must be done in a
   % single loop becasue we need to close the textures in the trial loop
   % after using each texture becasue otherwise they will hang around in
   % memory and cause the familiar Java runtime error: Out of memory.
   
   % Exit Codes and initialization
    exitLoop=0; %This is a flag indicating we need to break from the trials
                % structure loop below. The flag becomes true (=1) if the
                % user presses any key
    
    % MAIN LOOP OVER TRIALS TO DRAW TEXS
    for trial=1:numel(trials)
        if exitLoop==1;
            break;
        end
        
        n=0;        % Phase of grating to be updated on each redraw
        
        %%%%%%%%%%%%%%%% GET STIMULUS TIMING INFORMATION %%%%%%%%%%%%%%%%%%
        % The wait, duration, and delay are stored in trials structure.
        delay = trials(trial).Timing(1);
        duration = trials(trial).Timing(2);
        wait = trials(trial).Timing(3);
        
        %%%%%%%%%%%%%%%%%%% CONSTRUCT SURROUND TEXTURE %%%%%%%%%%%%%%%%%%%%
        % To draw the center and surround gratings we will need to get the
        % temporal frequencies, the surround space freq and contrast
        % parameters
        surrTempFreq = trials(trial).Surround_Temporal_Frequency;
        surrSpaceFreq = trials(trial).Surround_Spatial_Frequency;
        surrContrast = trials(trial).Surround_Contrast;
        
        % convert to pixel units
        surrPxPerCycle = ceil(1/(surrSpaceFreq*degPerPix));
        surrFreqPerPix = (surrSpaceFreq*degPerPix)*2*pi;
        
        % calculate amount to shift the gratings with each screen update
        surrShiftPerFrame= ...
            surrTempFreq * surrPxPerCycle * ifiDuration;
    
        %%%%%%%%%%%%%%%%%%% SURROUND ANNULUS GRATING %%%%%%%%%%%%%%%%%%%%%%
        % Get the surround size from the trials struct (in degs)
        surroundDiam = trials(trial).Surround_Diameter;
        % Convert to pixels
        surrDiamPix = ceil((surroundDiam/degPerPix));
        
        % construct a 2-D grid of points to calculate our grating over
        % (note we extend by one period to account for shift of
        % grating later)
        gx = meshgrid(-(surrDiamPix)/2:(surrDiamPix)/2 +...
            surrPxPerCycle, -(surrDiamPix)/2:(surrDiamPix)/2, 1);
        
        % compute the grating in Luminance units
        surrGrating = grayLum +...
            (whiteLum-grayLum)*surrContrast*cos(surrFreqPerPix*gx);
       
        % set the complement region outside the surrGrating circle to be
        % transparent
        [sx,sy] = meshgrid(-surrDiamPix/2:surrDiamPix/2,...
                        -surrDiamPix/2:surrDiamPix/2);
        % set transparent everywhere
        surrGrating(:,:,2) = 0;
        % set nontranparent inside surround diameter
        surrCircle = whiteLum * (sx.^2 + sy.^2 <= (surrDiamPix/2)^2);
        
        surrGrating(1:surrDiamPix+1, 1:surrDiamPix+1, 2) = surrCircle;
        
        % convert grating to pixel units
        surrGrating = GammaCorrect(surrGrating);
        
        % make the grating texture and save to gratingtex cell array
        % note it is not strictly necessary to save this to a cell
        % array since we will delete at the end of the loop but I want
        % to be explicit with the texture so that I am sure to delete
        % it when it is no longer needed in memory
        surrGratingTex{trial}=Screen('MakeTexture', w,...
            surrGrating,[], [], [], [], glsl);
        
        %%%%%%%%%%%%% CONSTRUCT THE CENTER GRATING %%%%%%%%%%%%%%%%%%%%%%%%
        % Now we construct the center grating to be overlayed onto the
        % border
        
        % Get the contrast, spatial frequency and diameter of the trial
        centerContrast = trials(trial).Center_Contrast;
        centerTempFreq = trials(trial).Center_Temporal_Frequency;
        centerSpaceFreq = trials(trial).Center_Spatial_Frequency;
        centerDiam = trials(trial).Center_Grating_Diameter;
        
        
        centerOrientation = trials(trial).Center_Orientation;
        
        % convert to pixel units
        centerPxPerCycle = ceil(1/(centerSpaceFreq*degPerPix));
        centerFreqPerPix = (centerSpaceFreq*degPerPix)*2*pi;
        centerDiamPix = ceil(centerDiam/degPerPix);
        
        centerShiftPerFrame= ...
            centerTempFreq * centerPxPerCycle * ifiDuration;   
        
        % construct a 2-D grid of points to calculate our grating over
        % (note we extend by one period to account for shift of
        % grating later)
        gx = meshgrid(-(centerDiamPix)/2:(centerDiamPix)/2 +...
            centerPxPerCycle,-(centerDiamPix)/2:(centerDiamPix)/2, 1);
        
        % compute the grating in Luminance units
        centerGrating = grayLum +...
            (whiteLum-grayLum)*centerContrast*cos(centerFreqPerPix*gx);
        
        % construct a circle aperature the size of the center grating
        [cx,cy] = meshgrid(-centerDiamPix/2:centerDiamPix/2,...
            -centerDiamPix/2:centerDiamPix/2);
        
        circle = whiteLum * (cx.^2 + cy.^2 <= (centerDiamPix/2)^2);
        
        % Set the alpha to be 0 (non-transparent everywhere)
        centerGrating(:,:,2) = 0;
        % for the points in inside centerDiamPix set transparent
        centerGrating(1:centerDiamPix+1, 1:centerDiamPix+1, 2) = circle;
        
        % convert grating to pixel units
        centerGrating = GammaCorrect(centerGrating);
        
        % make the grating texture and save to gratingtex cell array
        % note it is not strictly necessary to save this to a cell
        % array since we will delete at the end of the loop but I want
        % to be explicit with the texture so that I am sure to delete
        % it when it is no longer needed in memory
        centerGratingTex{trial}=Screen('MakeTexture', w,...
            centerGrating, [], [], [], [], glsl);

        %%%%%%%%%%%%%%%% CONSTRUCT OUTER MASK TEXTURE %%%%%%%%%%%%%%%%%%%%%
        % The gray mask is simply a gray circle overlayed on the surround
        % grating 

        % The mask diameter will match the centerDiameter
        maskDiamPix = centerDiamPix;
        % construct a grid of mask locations so we can set the alpha
        % channel to 0 where the grating should show through the mask
        % (i.e. the complement or area outside the circular mask)
        [maskX, maskY] = meshgrid(-maskDiamPix/2:...
            maskDiamPix/2);
        % construct the rectangular mask, a square of size maskDiamPix
        mask = ones(maskDiamPix+1, maskDiamPix+1,2)*grayPix;
        % set the alpha channel of the complimentary region (outside of
        % the circle to be transparent so the grating shows through
        mask(:,:,2) = 255*(1-(maskX.^2+maskY.^2 >= (maskDiamPix/2)^2));
        % Construct the mask
        maskTex{trial} = Screen('MakeTexture', w, mask,...
                                                    [], [], [], [], glsl);

        
        %%%%%%%%%%%%%%%%%%%%%%% PARALLEL PORT TRIGGER %%%%%%%%%%%%%%%%%%%%%
        % After constructing the stimulus texture we are ready to trigger
        % the parallel port and begin our draw to the screen. This function
        % is located in the stimGen helper functions directory.
   
        %ParPortTrigger;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%% DRAW TEXTURES %%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % In DRAW TEXTURES, we will obtain specific parameters such as the
        % orientation etc for each trial in the trials struct. We will then
        % draw an initial gray screen persisting for a time called delay.
        % This screen will be followed by the c/s stimulus composed of
        % overlaying all the above defined textures The sum time of these
        % presentations will equal the stimulus duration. Following the
        % different grating conditions a gray screen will be shown 
        % persisting for a time called wait
        
        %%%%%%%%%%%%%%%%%%%% DRAW DELAY GRAY SCREEN %%%%%%%%%%%%%%%%%%%%%%%
        % DEVELOPER NOTE: Prior vers of stimuli used the func WaitSecs to
        % draw gray screens. This is a bad practice because the functionit
        % KbCheck clicks. In addition PTB only guarantees the accuracy of 
        % WaitSecs to the millisecond scale whereas VBL timestamps 
        % described below uses.
        % GetSecs() a highly accurate submillisecond estimate of the system
        % time. All times should be referenced to this estimate for better
        % accuracy.
    
        % We perform an initial screen flip using Screen, we return
        % back a time called vbl. This val. is a precise time estimate
        % of when the graphics card performed a buffer swap. This time is 
        % what all of our times will be referenced to. More details at
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
            Screen('FillRect', w, grayPix);
            
            % Relay to user the current triggerNumber
            Screen('TextSize', w, 40);
            Screen('DrawText', w, num2str(trial), 10, 10, [0,0,0]);
            
            % update the vbl timestamp and provide headroom for jitters
            vbl = Screen('Flip', w, vbl + (waitframes - 0.5) * ifi);
            
            % exit the while loop and flag to one if user presses any key
            if KbCheck
                exitLoop=1;
                break;
            end
        end

        %%%%%%%%%%%%%%%%%%%% DRAW CENTER-SURROUND STIMULUS %%%%%%%%%%%%%%%%
        % If the trial is a blank then we do not need worry about all the
        % drawings of the textures, otherwise we must calculate the grating
        % shifts for each draw loop for each grating (since they may have
        % different spatial and temporal frequencies) and draw them
        if ~strcmp(trials(trial).Stimulus_Type, 'Blank')

            % get the end time of the stimulus relative to our clocked vbl
            % time
            % update the vbl timestamp and provide headroom for jitters
            stimRunTime = vbl+duration;
            % If we are at a time between delay and duration we are in the
            % draw stimulus time period
            while vbl < stimRunTime
                
                % calculate the offset of the grating and use the mod func
                % to ensure the grating snaps back once the border is
                % reached
                surrXOffset = mod(n*surrShiftPerFrame,surrPxPerCycle);
                % calculate the same offset for the center grating
                centerXOffset = mod(n*centerShiftPerFrame,...
                                    centerPxPerCycle);
                n = n+1;
                
                % Set the source rectangles to excise the shifted textures
                surrSrcRect = [0 0 ...
                               surrDiamPix+1 surrDiamPix+1];
                
                centerSrcRect = [0 0 ...
                                 centerDiamPix+1 ...
                                 centerDiamPix+1];
                             
                           
                switch trials(trial).Surround_Condition
                    case 1 % center alone condition, modify the offset on 
                        % the fly using the final 'special flags arg.
                        Screen('DrawTexture', w,...
                            centerGratingTex{trial},...
                            centerSrcRect, [],...
                            centerOrientation,[], [], [], [], [],...
                            [0 centerXOffset 0 0]);
                        
                    case 2 % center and positive cross (+90)
                        
                        % Draw the annulus surround
                        Screen('DrawTexture', w,...
                            surrGratingTex{trial}, surrSrcRect,...
                            [], centerOrientation+90,...
                            [], [], [], [], [],...
                            [0 surrXOffset 0 0]);
                        
                        % Draw the center grating
                        Screen('DrawTexture', w,...
                            centerGratingTex{trial},...
                            centerSrcRect, [],...
                            centerOrientation,[], [], [], [], [],...
                            [0 centerXOffset 0 0]);
                        
                        
                    case 3 % center and negative cross (-90)
                        
                        % Draw the annulus surround
                        Screen('DrawTexture', w,...
                            surrGratingTex{trial}, surrSrcRect,...
                            [], centerOrientation-90,...
                            [], [], [], [], [],...
                            [0 surrXOffset 0 0]);
                        
                        % Draw the center grating
                        Screen('DrawTexture', w,...
                            centerGratingTex{trial},...
                            centerSrcRect, [],...
                            centerOrientation,[], [], [], [], [],...
                            [0 centerXOffset 0 0]);
                        
                    case 4 % center and iso surround
                        
                        % Draw the annulus surround
                        Screen('DrawTexture', w,...
                            surrGratingTex{trial}, surrSrcRect,...
                            [], centerOrientation,...
                            [], [], [], [], [],...
                            [0 surrXOffset 0 0]);
                        
                        % Draw the center grating
                        Screen('DrawTexture', w,...
                            centerGratingTex{trial},...
                            centerSrcRect, [],...
                            centerOrientation,[], [], [], [], [],...
                            [0 centerXOffset 0 0]);
                        
                    case 5 % surround alone
                        
                        % Draw the surround
                        Screen('DrawTexture', w,...
                            surrGratingTex{trial}, surrSrcRect,...
                            [], centerOrientation,...
                            [], [], [], [], [],...
                            [0 surrXOffset 0 0]);
                        
                        Screen('DrawTexture', w,...
                            maskTex{trial}, centerSrcRect,...
                            [], centerOrientation,...
                            [], [], [], [], [],...
                            [0 centerXOffset 0 0]);
                        
                end % switch stim condition end
                
                % Relay to user the current triggerNumber
                Screen('TextSize', w, 40);
                Screen('DrawText', w, num2str(trial), 10, 10, [0,0,0]);
                
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
            end % end of draw time period loop delay < vbl < runtime

        else % this is a blank trial
            % get an initial time stamp
            vbl=Screen('Flip', w);
            
            % Set the runtime of each trial by adding duration to vbl time
            stimRunTime = vbl + duration;
            
            while (vbl < stimRunTime)
                
                  n = n+1; % Add to counter for flipCheck box
                  
                % Draw a gray screen
                Screen('FillRect', w,grayPix);
                
                % Relay to user the current triggerNumber
                Screen('TextSize', w, 40);
                Screen('DrawText', w, num2str(trial), 10, 10, [0,0,0]);
                
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
            end % end of draw time period for blank stimulus
        end % end for test if this trial is blank
        
        %%%%%%%%%%%%%%%%%%%%% DRAW INTERSTIMULUS GRAY SCREEN %%%%%%%%%%%%%%
        % Between trials we want to draw a gray screen for a time of wait
        % get a new timestamp for this stimulus perion
        vbl = Screen('Flip', w, vbl + (waitframes - 0.5) * ifi);
        waitTime = vbl + wait;
         
        while vbl < waitTime
            % Draw a gray screen
            Screen('FillRect', w,grayPix);
            
            % Relay to user the current triggerNumber
            Screen('TextSize', w, 40);
            Screen('DrawText', w, num2str(trial), 10, 10, [0,0,0]);
            
            % update the vbl timestamp and provide headroom for jitters
            vbl = Screen('Flip', w, vbl + (waitframes - 0.5) * ifi);
            
            % exit the while loop and flag to one if user presses any key
            if KbCheck
                exitLoop=1;
                break;
            end
        end % end while less than waitTime
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % IMPORTANT YOU MUST CLOSE EACH TEXTURE IN THE LOOP OTHERWISE THESE
        % OBJECTS WILL REMAIN IN MEMORY FOR SOME TIME AN ULTIMATELY LEAD TO
        % JAVA OUT OF MEMORY ERRORS!!!
        Screen('Close', centerGratingTex{trial})
        Screen('Close', surrGratingTex{trial})
    end % End of trials loop
    
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
    display('Closed All Textures')
    Screen('CloseAll');
    Priority(0);
    psychrethrow(psychlasterror);
end

%%%%%%%%%%%%%%%%%%%%%%%% Turn On PTB verbose warnings %%%%%%%%%%%%%%%%%%%%
Screen('Preference', 'Verbosity',3);
% please see the following page for an explanation of this function
%  http://psychtoolbox.org/FaqWarningPrefs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end
