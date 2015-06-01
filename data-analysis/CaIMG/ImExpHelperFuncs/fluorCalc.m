function fluorSignal = fluorCalc(maskedImageStack, stimTiming, frameRate)
% fluorSignal calculates the fluorescent signal of an image stack.
% Specifically, it computes the fluorescence prior to visual stimulation 
% and the fluroscence during the visual stimulation and computes the
% percentage change
% INPUTS                : imageStack, a 3d matrix of images
%                       : stimTiming, a 1x3 array of stimulus
%                         delay,presentation,wait
%                       : frameRate, the rate at which the image stack was
%                         collected
% OUTPUTS               : fluorSignal, an array of the mean fluorescent
%                         percentage change
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

% if ~any(isnan(maskedImageStack(:)))
if ~isempty(maskedImageStack(:))
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%% CALCULATE THE MEAN PRESTIMULUS FLUORESCENCE %%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %  We first extract the frames corresponding to the prestimulus time
    preStimStack = ...
        maskedImageStack(:,:,...
        1:floor(stimTiming(1)*frameRate));
    % compute the mean within each frame and across all frames
    preStimMean = mean(mean(mean(preStimStack,3)));
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %EXPLANATION
    % Our masked images contain 0s everywhere except in the roi so we can take
    % use the following formula (mean(frame)-preStimMean)/preStimMean. Lets do
    % an example to make sure we understand.
    % mean of 50pix region prior to stimulation is 100
    % mean of same 50 pix region during stimulation is 120
    % size of the frame is 128x128
    % we expect a percent change of pxs in roi to be (120-100)/100 = .2
    % This is equivalent to [(50pix*120+ 16334*0)/(16384)-(50pix*100 +
    % 16334*0)/(16384)] / (50pix*100 +16334*0)/(16384)] = .2. Where we have
    % averaged the entire frame rather than just the pixels in the roi. The
    % reason is becasue we are looking at the percent change and all the 0s in
    % the frame do not affect the percentage change
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%% CALCULATE THE MEAN OF EACH FRAME %%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    meansOfStack = squeeze(mean(mean(maskedImageStack)));
    %  note squeeze performs removal of singleton dimensions
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%% CALCULATE PERCENTAGE FLUORESCENCE CHANGE %%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    fluorSignal = (meansOfStack - preStimMean)/(preStimMean);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
else
    fluorSignal = [];

end

