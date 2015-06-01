function [allAreas] = ePhysAreaCalculator( dataMapObj, baseLineIndices,...
                                            vStimIndices,samplingFrequency)
% ePhysAreaCalculator computes the area between baseLine and the data array
% over the tuple time values in vStimEpoch.
% INPUTS:               dataMapObj: map object of data values
%                       baselineIndices: indices of data to compute
%                                        baseline over
%                       vStimEpoch: indices during which visual stimulation
%                                   is present
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%copyright (c) 2013  Matthew Caudill
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

% Get all the values
dataVals = values(dataMapObj);

% For each condition in the map use cell fun to loop through the trials and
% compute the area using trapz numerical integration. We also convert the
% area to be mV/pA * time(secs) by dividing by the sampling frequency
for cond = 1: numel(dataVals)    
    allAreas{cond} = cellfun(@(x) trapz(x(vStimIndices)-...
                                  mean(x(baseLineIndices)))/...
                                  samplingFrequency,...
                                  dataVals{cond},'UniformOut',0);
end




end

