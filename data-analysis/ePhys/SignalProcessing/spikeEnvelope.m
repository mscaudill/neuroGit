function [ spikeWaveForms] = spikeEnvelope(filtSignal, samplingFreq,...
                                               spikeIdxs, window)
%spikeEnvelope returns back the spike shapes withing filtSignal and
%computes the standard deviation in the spike shapes
%INPUTS: 
%   filtSignal             : a filtered n-element double array
%   samplingFreq           : sampling Frequency data was acquired at
%   spikeIndices           : a double array of spike indices for filtSignal
%   window                 : a two element array of pre and post time
%                            around the spike index
% OUTPUTS:
%   spikeWaveForms         : a cell array containing arrays of doubles over
%                            the samples within window
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%% CONVERSIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
window_samples = round(window./1000*samplingFreq);

%PREALLOCATE

spikeWaveForms = cell(1,numel(spikeIdxs));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% GET SPIKEWAVEFORMS %%%%%%%%%%%%%%%%%%%%%%%%%
% first check that there are spikes to look at
if ~isempty(spikeIdxs)
    for index = 1:numel(spikeIdxs)
        % a check that we have samples around the spike
        if spikeIdxs(index)-window_samples(1)>0 && ...
                spikeIdxs(index)+window_samples(2)<numel(filtSignal)
            
            spikeWaveForms{index} = filtSignal(spikeIdxs(index)-...
                window_samples(1):...
                spikeIdxs(index)+...
                window_samples(2));
        end
    end
end
% In the above loop we requried that we have enough samples around each
% spike, if this was not true in the above loop then spikes{index} = []. We
% must remove these empty cell arrays
emptyIndices = find(cellfun(@isempty,spikeWaveForms));
spikeWaveForms(emptyIndices) = [];

end

