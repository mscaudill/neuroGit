function SimpleCenterSurroundV2(trials)
% simpleCenterSurroundV2 draws two concentric gratings to the screen with
% parameters defined by the trials array structure input

% INPUTS:  TRIALSSTRUCT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Written by MSC 3-12-13
% Modified by:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
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
%  function [trials] = SimpleCenterSurroundV2(stimType,table)
%  if nargin<1
%      table = {'Surround Spatial Frequency (cpd)', 0.04, .04, 0.04;...
%               'Center Spatial Frequency (cpd)', 0.04, .04, 0.04;...
%               'Surround Temporal Frequency (cps)', 3, 1, 3;...
%               'Center Temporal Frequency (cps)', 3, 1, 3;...
%               'Mask Outer Diameter (deg)', 60, 1, 60;...
%               'Gaussian Mask FWHM (deg)', 5, [], [];...
%               'Center Grating Diameter (deg)', 30, [], [];
%               'Surround Contrast', 1, 1, 1;...
%               'Center Contrast', 1, 1, 1;...
%               'Center Orientation', 270, 45, 270;...
%               'Surround Condition', 1, 1, 5;...
%               'Stimulus Center (degs)', 0, 0, [];...
%               'Timing (delay,duration,wait) (s)', 1, 2, 1;...
%               'Blank', 0, [], [];... 
%               'Randomize', 0, [], [];...
%               'Interleave', 0, [], [];
%               'Repeats', 0, [], []};
%  stimType = 'Simple Center-surround Grating';
%     
%  end
%  trials = trialStruct(stimType, table);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%% OBTAIN RIG SPECIFIC MONITOR INFORMATION %%%%%%%%%%%%%%%%%
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
    % Size of the Surround grating (in pix) that we will draw (1.5 times 
    % monitor width)
    visibleSize = 1.5*monitorInfo.screenSizePixX;
    
%%%%%%%%%%%%%%%%%%%%%%%%%% INITIAL SCREEN DRAW %%%%%%%%%%%%%%%%%%%%%%%%%%%    
% We start with a gray screen before generating our stimulus and displaying
% our stimulus.

    % HIDE CURSOR FROM SCREEN
    HideCursor;
    % OPEN A SCREEN WITH A BG COLOR OF GRAY (RETURN POINTER W)
	[w, screenRect]=Screen(screenNumber,'OpenWindow', grayPix);
    
    
    % Make sure this GPU supports shading at all:
    AssertGLSL;
    
    % ENABLE ALPHA BLENDING OF GRATING WITH THE MASK
    Screen('BlendFunction', w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    % Create a special texture drawing shader for masked texture drawing:
    glsl = MakeTextureDrawShader(w, 'SeparateAlphaChannel');

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
    
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %%%%%%%%%%%%%%%%%%%%% CONSTRUCT AND DRAW TEXTURES %%%%%%%%%%%%%%%%%%%%%%
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
   
    
    % MAIN LOOP OVER TRIALS TO CONSTRUCT TEXS AND DRAW THEM
    for trial=1:numel(trials)
        if exitLoop==1;
            break;
        end
        
         n=0;        % This is a counter to shift our grating on each redraw
    
        %%%%%%%%%%%%%%%%%%% CONSTRUCT SURROUND TEXTURE %%%%%%%%%%%%%%%%%%%%
        % We start by constructing a surround grating texture (note 
        % in prior stimuli I was explicit to take care not to compute a 
        % grating texture if the trial was blank to save on computation.
        % However this makes the code a little more difficult to read so I
        % abandon that here. We will always make all textures but in the
        % draw loop we will only draw what we need to show
        
        % we construct a grating texture from parameters of the trial
        % Get the contrast, spatial frequency of the trial
        surrContrast = trials(trial).Surround_Contrast;
        surrSpaceFreq = trials(trial).Surround_Spatial_Frequency;
    
        % convert to pixel units
        surrPxPerCycle = ceil(1/(surrSpaceFreq*degPerPix));
        surrFreqPerPix = (surrSpaceFreq*degPerPix)*2*pi;
    
        % construct a 2-D grid of points to calculate our grating over
        % (note we extend by one period to account for shift of
        % grating later)
        sx = meshgrid(-(visibleSize)/2:(visibleSize)/2 +...
            surrPxPerCycle, 1);
    
        % compute the grating in Luminance units
        surrGrating = grayLum +...
            (whiteLum-grayLum)*surrContrast*cos(surrFreqPerPix*sx);
    
        % convert grating to pixel units
        surrGrating = GammaCorrect(surrGrating);
    
        % make the grating texture and save to gratingtex cell array
        % note it is not strictly necessary to save this to a cell
        % array since we will delete at the end of the loop but I want
        % to be explicit with the texture so that I am sure to delete
        % it when it is no longer needed in memory
        surroundGratingTex{trial}=Screen('MakeTexture', w,...
                                        surrGrating,[], [], [], [], glsl);
    
        %%%%%%%%%%%%% CONSTRUCT CIRCULAR MASK TEXTURE %%%%%%%%%%%%%%%%%%%%%
        % A circular mask with gray values will now be created. The purpose
        % of this circulare mask is two-fold. First, the circular mask will
        % provide the inner gray cirle for the surround only condition.
        % Second the circular mask can be made larger than the center
        % grating to allow for a circular boundary between the center and
        % surround gratings. The user can then choose to apply a gaussian
        % border around the center grating.

        % Get the mask diameter in degrees from the trials structure
        circMaskDiameter = trials(trial).Mask_Outer_Diameter;
        
        % Convert the mask Diameter to degrees
        circMaskDiamPix = ceil((circMaskDiameter/degPerPix));
        
        % construct a grid of mask locations so we can set the alpha
        % channel to 0 where the grating should show through the mask
        % (i.e. the complement or area outside the circular mask)
        [circMaskX, circMaskY] = meshgrid(-circMaskDiamPix/2:...
            circMaskDiamPix/2);
        
        % construct the rectangular mask, a square of size maskDiamPix
        circMask = ones(circMaskDiamPix+1, circMaskDiamPix+1,2)*grayPix;
        
        % set the alpha channel of the complimentary region (outside of
        % the circle to be transparent so the grating shows through
        circMask(:,:,2) = 255*(1-(circMaskX.^2+circMaskY.^2 >=...
                          (circMaskDiamPix/2)^2));
                      
        % Construct the mask
        circMaskTex{trial} = Screen('MakeTexture', w, circMask,...
                                                    [], [], [], [], glsl);
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %%%%%%%%%%%%% CONSTRUCT THE CENTER GRATING %%%%%%%%%%%%%%%%%%%%%%%%
        % Now we construct the center grating to be overlayed onto the
        % outer mask

        % Get the contrast, spatial frequency and diameter of the trial
        centerContrast = trials(trial).Center_Contrast;
        centerSpaceFreq = trials(trial).Center_Spatial_Frequency;
        centerDiam = trials(trial).Center_Grating_Diameter;
        
        % convert to pixel units
        centerPxPerCycle = ceil(1/(centerSpaceFreq*degPerPix));
        centerFreqPerPix = (centerSpaceFreq*degPerPix)*2*pi;
        centerDiamPix = ceil(centerDiam/degPerPix);
        
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
        
        % Set 2nd channel (the alpha channel) of 'CenterGrating' to the aperture
        % defined in 'circle':
        centerGrating(:,:,2) = 0;
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
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %%%%%%%%%%%%%%% CONSTRUCT GAUSSIAN MASK TEXTURE %%%%%%%%%%%%%%%%%%%
        % We now will create the circular gaussian aperture mask. We will
        % set the alpha transparency value equal to the gaussian function
        % centered at a radius equal to the center grating. If the user
        % wishes not to have the gaussian mask they simply set the half
        % width to 0 degrees
        
        % make a 2-D matrix of gray values (note we add one along
        % each dimension so the mask will be centered about the x,y
        % grating position specified by the user)
        gaussMask = ones(visibleSize+1,visibleSize+1,2)*grayPix;
        
        % obtain all the coordinates of the mask using meshgrid and center
        % around the center of the monitor.
        [gaussMaskX, gaussMaskY] = meshgrid(-visibleSize/2:visibleSize/2,...
            -visibleSize/2:visibleSize/2);
        
        % convert the mask coordinates into polar coordinates (r,theta) with
        % the following transformations
        theta = atan2(gaussMaskY, gaussMaskX);
        r = sqrt(gaussMaskX.^2+gaussMaskY.^2);
        
        % Now create a gaussian mask centered on ro and rotated about the
        % center of the monitor
        
        % set the gaussian width (full width at half max) in degrees
        fwhm = trials(trial).Gaussian_Mask_FWHM;
        % calculate the standard deviation corresponding to this FWHM in
        % pixel units
        sigma = fwhm/(2*sqrt(2*log(2)))*1/degPerPix;
        
        % set the center of the gaussian to be at the edge of the circular
        % center grating
        ro = (trials(trial).Center_Grating_Diameter*1/degPerPix)/2;
        
        % Define the transparency to be opaque (255) at ro and drop off with
        % a standard deviation of sigma
        gaussMask(:,:,2) = 255*...
            exp(-(r-ro).^2/(2*sigma^2)).*(cos(theta).^2+sin(theta).^2);
        
        % Make the mask texture
        gaussMaskTex{trial} = Screen('MakeTexture', w, gaussMask,[],[],...
                                     [],[],glsl);
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
    %%%%%%%%%%%%%%% OBTAIN GRATING PARAMS FROM TRIALSSTRUCT %%%%%%%%%%%%%%%
    % To draw each texture, we will need the temporal frequencies and the
    % orientations of the inner and outer gratings and construct rectangles
    % to draw the textures to.

    % Get the parameters for drawing the both the center and surround
    % gratings
    surrTempFreq = trials(trial).Surround_Temporal_Frequency;
    centerTempFreq = trials(trial).Center_Temporal_Frequency;
    surrCondition = trials(trial).Surround_Condition;
    centerOrientation = trials(trial).Center_Orientation;
    
    % calculate amount to shift the gratings with each screen update
    surrShiftPerFrame= ...
        surrTempFreq * surrPxPerCycle * ifiDuration;
    
    centerShiftPerFrame= ...
        centerTempFreq * centerPxPerCycle * ifiDuration;
    
    % Calculate the destination rectangles. We will need the x y
    % location of the grating from the first trial and we will need the
    % size of the screen so that the grating center will be referenced
    % to the screen center. So when the user slects x = 20 degs and y
    % =0 degs the grating will shift from the center of the screen
    % twenty degrees to the right. Note that the y positive direction
    % is downwards along screen so the y position has a negative sign
    % to reverse this Now +y moves grating up. Remenber degrees must be
    % converted to pixels
    x = (trials(1).Stimulus_Center(1))*(1/degPerPix)+...
        monitorInfo.screenSizePixX/2;
    y = -1*trials(1).Stimulus_Center(2)*(1/degPerPix)+...
        monitorInfo.screenSizePixY/2;
    
    % create destination rectangle for the surround (size of grating)
    surrDstRect = [0 0 visibleSize visibleSize];
    % create destination rectangle for the center (size of center grating)
    centerDstRect = [0 0 centerDiamPix+1 centerDiamPix+1];
    % create a destination rectangle for the circular mask (size of circ
    % mask)
    circMaskDstRect = [0 0 circMaskDiamPix+1 circMaskDiamPix+1];
    % create a destination rectangle for the gaussian mask
    gaussMaskDstRect = [0 0 visibleSize visibleSize];
    
    % center each dstRect about user selected x,y coordinate
    surrDstRect = CenterRectOnPoint(surrDstRect,x,y);
    centerDstRect = CenterRectOnPoint(centerDstRect,x,y);
    circMaskDstRect = CenterRectOnPoint(circMaskDstRect,x,y);
    gaussMaskDstRect = CenterRectOnPoint(gaussMaskDstRect,x,y);
        
    %%%%%%%%%%%%%%%%%%%%%%% PARALLEL PORT TRIGGER %%%%%%%%%%%%%%%%%%%%%%%%%
    % After constructing the stimulus texture we are now ready to trigger
    % the parallel port and begin our draw to the screen. This function is
    % located in the stimGen helper functions directory.
    
    %ParPortTrigger;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%% DRAW TEXTURES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % In DRAW TEXTURES, we will obtain specific parameters such as the
    % orientation etc for each trial in the trials struct. We will then
    % draw an initial gray screen persisting for a time called delay. This
    % screen will then be followed by the center surround stimulus composed
    % of overlaying all the above defined textures The sum time of these
    % presentations will equal the stimulus duration (e.g. if duration is 3
    % secs, each grating condition will appear for 1-sec). Following the
    % different grating conditions a gray screen will be shown persisting
    % for a time called wait
    
    %%%%%%%%%%%%%%%%%%%% DRAW DELAY GRAY SCREEN %%%%%%%%%%%%%%%%%%%%%%%%%%%      
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
     %%%%%%%%%%%%%%%%%%%% DRAW CENTER-SURROUND STIMULUS %%%%%%%%%%%%%%%%%%%
     % If the trial is a blank then we do not need worry about all the
     % drawings of the textures, otherwise we must calculate the grating
     % shifts for each draw loop for each grating (since they may have
     % different spatial and temporal frequencies) and draw them
        if ~strcmp(trials(trial).Stimulus_Type, 'Blank')
            vbl=Screen('Flip', w);
            
            % Set the runtime of each trial by adding duration to vbl time
            runtime = vbl + duration;
            
            while (vbl < runtime)
                % calculate the offset of the grating and use the mod func
                % to ensure the grating snaps back once the border is
                % reached
                surrXOffset = mod(n*surrShiftPerFrame,surrPxPerCycle);
                % calculate the same offset for the center grating
                centerXOffset = mod(n*centerShiftPerFrame,...
                                    centerPxPerCycle);
                n = n+1;
                
                %%%%%% SET ALL SRC RECTANGLES TO EXCISE TEXS FROM %%%%%%%%%
                
                surrSrcRect = [surrXOffset 0 ...
                            surrXOffset+visibleSize+1 visibleSize+1];
                        
                centerSrcRect = [0 0 ...
                            centerDiamPix centerDiamPix];
                
                circMaskSrcRect = [0 0 ...
                            circMaskDiamPix+1 circMaskDiamPix+1];
                        
                gaussMaskSrcRect = [0 0 visibleSize+1 visibleSize+1];
              
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
                %%%%%%%%%%%%%%%%%%%%% DRAW EACH TEXTURE %%%%%%%%%%%%%%%%%%%
                % We are now ready to draw our textures. The specific
                % combinations of centers and surrounds are given by two
                % parameters, the center orientation and the surround
                % condition. The surround conditions have values 1:5 where
                % 1=centerAlone, 2=center with cross surround (+90),
                % 3=center+crossSurround(-90), 4=isoOrientation, 5=
                % surroundAlone (at iso ori)
                % we will use a switch case to determine what to draw
                switch trials(trial).Surround_Condition
                    
                    case 1 % CENTER ALONE CONDITION
                        Screen('DrawTexture', w,...
                            centerGratingTex{trial},...
                            centerSrcRect, centerDstRect,...
                            centerOrientation,[], [], [], [], [],...
                            [0 centerXOffset 0 0]);
                        
                        % If the gaussian mask width option is chosen draw
                        % it over the center
                        if trials(trial).Gaussian_Mask_FWHM > 0;
                         Screen('DrawTexture', w,...
                            gaussMaskTex{trial},...
                            gaussMaskSrcRect, gaussMaskDstRect,...
                            centerOrientation);
                        end
                        
                    case 2 % CENTER AND POSITIVE (+90) CROSS CONDITION
                        % Draw surround
                        Screen('DrawTexture', w,...
                            surroundGratingTex{trial}, surrSrcRect,...
                            surrDstRect, centerOrientation+90,...
                            [], [], [], [], [],...
                            [surrXOffset 0 ...
                            surrXOffset+visibleSize+1 visibleSize+1]);
                        
                        % Draw circular mask
                        Screen('DrawTexture', w, circMaskTex{trial},...
                            circMaskSrcRect, circMaskDstRect,...
                            centerOrientation+90);
                        
                        % Draw the center grating
                        Screen('DrawTexture', w,...
                            centerGratingTex{trial}, centerSrcRect,...
                            centerDstRect, centerOrientation,...
                            [], [], [], [], [], [0 centerXOffset 0 0]);
                        
                        % If the gaussian mask width option is chosen draw
                        % it over the center
                        if trials(trial).Gaussian_Mask_FWHM > 0;
                         Screen('DrawTexture', w,...
                            gaussMaskTex{trial},...
                            gaussMaskSrcRect, gaussMaskDstRect,...
                            centerOrientation);
                        end
                        
                    case 3 % CENTER AND NEGATIVE (-90) CROSS CONDITION
                        % Draw surround
                        Screen('DrawTexture', w,...
                            surroundGratingTex{trial}, surrSrcRect,...
                            surrDstRect, centerOrientation-90,...
                            [], [], [], [], [],...
                            [surrXOffset 0 ...
                            surrXOffset+visibleSize+1 visibleSize+1]);
                
                        % Draw circular mask
                        Screen('DrawTexture', w, circMaskTex{trial},...
                            circMaskSrcRect, circMaskDstRect,...
                            centerOrientation-90);
                   
                        % Draw the center grating
                        Screen('DrawTexture', w,...
                            centerGratingTex{trial}, centerSrcRect,...
                            centerDstRect, centerOrientation,...
                            [], [], [], [], [], [0 centerXOffset 0 0]);
                        
                        % If the gaussian mask width option is chosen draw
                        % it over the center
                        if trials(trial).Gaussian_Mask_FWHM > 0;
                         Screen('DrawTexture', w,...
                            gaussMaskTex{trial},...
                            gaussMaskSrcRect, gaussMaskDstRect,...
                            centerOrientation);
                        end
                        
                    case 4 % CENTER AND ISO-ORIENTED SURROUND CONDITION
                        % Draw the surround
                        Screen('DrawTexture', w,...
                            surroundGratingTex{trial}, surrSrcRect,...
                            surrDstRect, centerOrientation,...
                            [], [], [], [], [],...
                            [surrXOffset 0 ...
                            surrXOffset+visibleSize+1 visibleSize+1]);
                        
                    case 5 % SURROUND ALONE CONDITION
                        Screen('DrawTexture', w,...
                            surroundGratingTex{trial}, surrSrcRect,...
                            surrDstRect, centerOrientation,...
                            [], [], [], [], [],...
                            [surrXOffset 0 ...
                            surrXOffset+visibleSize+1 visibleSize+1]);
                        
                        % Draw circular mask
                        Screen('DrawTexture', w, circMaskTex{trial},...
                            circMaskSrcRect, circMaskDstRect,...
                            centerOrientation);
                        
                        % If the gaussian mask width option is chosen draw
                        % it over the center
                        if trials(trial).Gaussian_Mask_FWHM > 0;
                         Screen('DrawTexture', w,...
                            gaussMaskTex{trial},...
                            gaussMaskSrcRect, gaussMaskDstRect,...
                            centerOrientation);
                        end

                
                end % end switch/case 
                
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
            end 
                
        else % we have a blank trial
            vbl=Screen('Flip', w);
            
            % Set the runtime of each trial by adding duration to vbl time
            runtime = vbl + duration;
            
            while (vbl < runtime)
                
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
            end
        end  
        
        %%%%%%%%%%%%%%%%%%%%% DRAW INTERSTIMULUS GRAY SCREEN %%%%%%%%%%%%%%
        % Between trials we want to draw a gray screen for a time of wait
        
        % Flip the screen and collect the time of the flip
        vbl=Screen('Flip', w);
        
        % We will loop until delay time referenced to the flip time
        waitTime = vbl + wait;
        % 
        while (vbl < waitTime)
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
        end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % IMPORTANT YOU MUST CLOSE EACH TEXTURE IN THE LOOP OTHERWISE THESE
    % OBJECTS WILL REMAIN IN MEMORY FOR SOME TIME AND ULTIMATELY LEAD TO
    % JAVA OUT OF MEMORY ERRORS!!!
    Screen('Close', centerGratingTex{trial})
    Screen('Close', surroundGratingTex{trial})
    Screen('Close', circMaskTex{trial})
    Screen('Close', gaussMaskTex{trial})
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

