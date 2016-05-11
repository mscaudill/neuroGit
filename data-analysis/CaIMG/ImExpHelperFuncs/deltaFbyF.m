function signal = deltaFbyF(fluorVals, corrFluorVals, stimTiming,...
                            frameRate, baselineFrames)
% deltaFbyF calculates the percentage change in fluorescence during a
% visual stimulus from a set of fluor values calculated as the mean pixel
% intensity within an roi - neuropil
% INPUTS                : fluorVals, an array of mean intensities
%                         predetermined for an image stack
%                       : corrFluorVals, neuropil subtracted intensities
%                       : stimTiming, a 1x3 array of stimulus
%                         delay,presentation,wait
%                       : frameRate, the rate at which the image stack was
%                         collected
%                       : baseline frames, frames to use as the baseline
% OUTPUTS               : signal, an array of the mean fluorescent
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

% We will follow the equation
%(F_cellTrue(t0:t3)-F_cellTrue(t0:t1))/(F_cellApparent(t0:t1) where
%F_cellTrue is the neuropil subtracted signal t0 is the start time t1 is
%the visual stimulation start and t3 is the end time of the entire signal.
%F_cellApparent is the measured f without subtraction
% start(t0), visualStart(t1), visualEnd(t2), end(t3)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%% CALCULATE PRESTIMULUS CORRECTED MEAN SIGNAL %%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% If the user left blank the baseline frames to use then we take frame one
% up to the first stimulus frame.
if isempty(baselineFrames)
    preStimMean = mean(corrFluorVals(1:floor(stimTiming(1)*frameRate)));
else
    preStimMean = mean(corrFluorVals(baselineFrames));
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%% CALCULATE UNCORRECTED PRESTIMULUS SIGNAL %%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
uncorrPreStimMean = mean(fluorVals(1:floor((stimTiming(1))*frameRate)));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%% CALCULATE DF BY F %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
signal = (corrFluorVals-preStimMean)/uncorrPreStimMean;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%