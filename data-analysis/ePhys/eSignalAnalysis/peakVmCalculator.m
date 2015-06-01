function [peakVoltages] = peakVmCalculator(dataMapObj,vStimIndices)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

dataVals = values(dataMapObj);

% for each condition in the map, compute the max voltage acheived
for cond = 1:numel(dataVals)
    peakVoltages{cond} = cellfun(@(x) max(x(vStimIndices)),...
                                dataVals{cond}, 'UniformOut',0);
end

end

