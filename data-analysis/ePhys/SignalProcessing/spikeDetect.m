function [spikeIndices] = spikeDetect(filtSignal,...
                                           samplingFreq, thresholdType,...
                                           threshold,...
                                           maxSpikeWidth,...
                                           refractoryPeriod,...
                                           triggerRemoval)
%spikeFinder locates the indices of spikes within a signal
%INPUTS
%   filtSignal          : an input array of doubles
%   samplingFreq        : sampling frequency in Hz
%   thresholdType       : multiples of sd or fixed value
%   threshold           : threshold for spike detection
%   maxSpikeWidth       : maximum allowable spike width, default (3 ms)
%   refractoryPeriod    : minimum time between spikes (default 10 ms) if
%                         two peaks are closer than this value the latter
%                         is discarded
%OUTPUTS
%   spikeIndices        : array of spike indices
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% DEFAULTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We only require that the user input a signal, sampling frequency and
% threshold. The maxspikeWidth and refractory period will be set to the
% following defaults if not specified by the user
if nargin < 5
    refractoryPeriod = 5; % in ms
end

if nargin <4
    maxSpikeWidth = 2; %in ms
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%% CONVERSIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%convert refractoryPeriod and maxSpike width to samples
refractorySamples=samplingFreq*refractoryPeriod/1000;
maxWidthSamples = samplingFreq*maxSpikeWidth/1000;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%% DETERMINE THRESHOLD CROSSINGS %%%%%%%%%%%%%%%%%%%%%
% First we get all the crossings of signal with the thresold by calling
% thresholdDetect..m
crossings = thresholdDetect(filtSignal, thresholdType, threshold);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%% LOCATE SPIKES AND IMPOSE SPIKE CONSTRAINTS %%%%%%%%%%%%%%%
% Now we locate the max/min in the signal between the crossings. This is
% the index corresponding to the peak of the spike

%Preallocate an array for the spike indices. The length of the spikes
%should be exactly half of the size of crossings
spikeIndices = 0*(1:1:(numel(crossings)/2));

% Locate the spike indices for each crossing pair returned from
% thresholdDetect.m
for crossingPair = 1:numel(crossings)
    % Check that the spikeWidth is less than the maximum allowed width
    if crossings{crossingPair}(2)-crossings{crossingPair}(1) <...
                                                            maxWidthSamples
                                                        
        % if so locate max index and save to spikeIndices array                                                
        [~,index] = max(filtSignal(crossings{crossingPair}(1):...
                              crossings{crossingPair}(2)));
                          
        % now the index bove starts at 1 but we must add this to the first
        % crossing to get the index relative to the entire signal
        spikeIndices(crossingPair)=index+crossings{crossingPair}(1);
        % If the spike width condition is not met than some of the spike
        % indices will remain zero (remember we initiliazed the array for
        % speed) so we remove any spikes at 0 index
        spikeIndices(spikeIndices == 0) = [];
    end
end

% Now impose the rectification constraint (note we add one because we
% remove the spike *following* too close to the previous spike
violatingSpikeIndex = find(diff(spikeIndices) < refractorySamples) + 1;
spikeIndices(violatingSpikeIndex) = [];

%now determine if the user wants to remove the first spikeIndex due to
%trigger pulse contamination
if triggerRemoval
    if ~isempty(spikeIndices)
        spikeIndices(1) = [];
    end
end

end

