function [firingRate] = firingRateFunc( spikeIndices, timeEdges,...
                                        samplingRate )
%firingRateFunc take an array of spike indices and returns back the number
%of spikes that fall within timeEdges (note spikes occuring on end edge are
%not counted).
%INPUTS                         
%   spikeIndices                   : an array of spike inices
%   timeEdges                      : a two element array of times
%                                   (in secs) to count the # of spikes in
%   samplingRate
%OUTPUTS
%   firingRate                     : firing rate in Hz
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

% We first convert the time of the edges to the sample number of edges. We
% do this because our spike indices are in samples not seconds
sampleEdges = timeEdges*samplingRate;
% we now call histc to count the number of spike occurences within
% sampleEdges. This func returns a two element array with (#spikes, #spikes
% on edge)
twoElementArr = histc(spikeIndices, sampleEdges);
% we don't care about the number of spikes on the edges so just get the
% first element and divide by the time difference of the edges to get a
% scalar firing rate
firingRate = twoElementArr(1)/(timeEdges(2)-timeEdges(1));


end

