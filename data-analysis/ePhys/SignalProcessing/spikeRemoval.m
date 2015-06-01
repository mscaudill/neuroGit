function [noSpikeData] = spikeRemoval( data, spikeIndices, samplingRate,...
                                       varargin)
%spikeRemoval removes the 
% INPUTS
%   data                :an array of data points
%   spikeIndices        :an array of spikeIndices (not spikeTimes!)
%   smaplingRate        :sampling rate of data collection
%   varargin:
%   tau                 :time in msec preceeding and following peak spike 
%                        time to be replaced; Defaults to 2 msec
% OUTPUTS
%   noSpikeData
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%% RETURN IF THERE ARE NO SPIKES %%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isempty(spikeIndices)
    noSpikeData = data;
    return
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%% DEFINE TAU IN MSEC IF NOT SPECIFIED %%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Tau is the number of points of the data (in msec) that we will
% replace with an interpolation. If not specified, we set it to 2 msecs (or
% roughly twice the spike width
if nargin < 4
    tau = 5;
end

%convert the tau to samle points
tauSamples = (tau/1000*samplingRate);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%% CREATE ARRAYS OF REPLACEMENT INDICES AROUND SPIKES %%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We convert the spikeIndices array into a cell of cells where each inner
% cell contains a single spikeIndex
spikesCell = mat2cell(spikeIndices,[1],ones(1,numel(spikeIndices)));

% now use cellfun and and expand the arrays around each spike index by an
% amount tau/2
for spikeIndex = 1:numel(spikesCell)
    if spikesCell{spikeIndex}-ceil(tauSamples/2) > 0 &&...
            spikesCell{spikeIndex}+ceil(tauSamples/2)<numel(data)
        
        replacementIndices{spikeIndex} =[spikesCell{spikeIndex}-ceil(tauSamples/2):...
                                 spikesCell{spikeIndex}+ceil(tauSamples/2)];
    else
        replacementIndices{spikeIndex} = [1,2];
    end
end

% replacementIndices = cellfun(@(x)...
%                             [x-ceil(tauSamples/2):x+ceil(tauSamples/2)],...
%                             spikesCell, 'UniformOut',0);

% Check if any of the replacement indices are negative and remove if true
% replacementIndicesLogical = logical(ones(1,numel(replacementIndices)));
% for indices = 1:numel(replacementIndices)
%     if any(replacementIndices{indices}<0)
%         replacementIndicesLogial(indices) = false;
%     end
% end
% replacementIndices = replacementIndices(replacementIndicesLogical);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%% CONSTRUCT LINEAR INTERPOLOANTS %%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Now call the function interp1 (matlab builtin) to construct a linear
% interpolation between the endpoints of the arrays surrounding each spike
linearInterps = cellfun(@(x) interp1([x(1),x(end)],...
                                     [data(x(1)),data(x(end))],...
                                      x,'linear'),...
                                      replacementIndices,'UniformOut',0);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%% REPLACE DATA AROUND SPIKES WITH INTERPOLANTS %%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Lastly replace the data with the new interpolated data
for i = 1:numel(replacementIndices)
    data(replacementIndices{i}) = linearInterps{i};
end
% assign to output variable
noSpikeData = data;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end
