function griddedGratingHist( centerPos,baseVoltTime )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
% open a set of exps using
% construct the mean signal cell array
% compute the max v for each postion
% subtract the baseline
% plot

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
%%%%%%%%%%%%%%%%%%%%%%%%%%%% CALL EXP LOADER %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[loadedExpCell,eExpNames] = multiEexpLoader('wholeCell',{'data',...
                                            'stimulus', 'behavior',...
                                            'fileInfo', 'spikeIndices'});
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%% GET STIMULUS TIMING INFORMATION %%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% For plotting the signals stored in the map we will need timing
% information and the frame rate at which the data was collected. We will
% collect this from the first experiment and assume these parameters were
% fixed across experiments.

% use the first stimulus to get the timing
stimTiming = loadedExpCell{1}.stimulus(1,1).Timing;

%use the first file in fileInfo to obtain the sampling rate
samplingFreq = loadedExpCell{1}.fileInfo(1,1).samplingFreq;

% get the samples for the resting membrane voltage
voltSamples = [round(baseVoltTime(1)+1):round(baseVoltTime(2)*samplingFreq)];

% get the samples for when the visual stimulation was present
dataSamples = [round(stimTiming(1)*samplingFreq):...
                    round(samplingFreq*(stimTiming(1)+stimTiming(2)))];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%% CALL EPHYSDATAMAP TO CONSTRUCT MAP OBJ %%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for exp = 1:numel(loadedExpCell)
    [~,meanDataMaps{exp},~] = ePhysDataMap(loadedExpCell{exp}.data,...
                                           loadedExpCell{exp}.stimulus,...
                                           {'Rows','Columns',...
                                           'Orientation'},...
                                           loadedExpCell{exp}.behavior,...
                                           loadedExpCell{exp}.fileInfo,...
                                           loadedExpCell{exp}.spikeIndices);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%% OBTAIN THE POSITION AND ANGLE KEYS %%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Obtain the number of positions and the number of angles shown
keySet = keys(meanDataMaps{1});
%get the number of positions
numPos = numel(unique((cellfun(@(x) x{1}, keySet))));
% get the number of angles
numAngles = numel(unique(cellfun(@(x) x{2},keySet)));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%% EXTRACT THE MEAN SIGNALS %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We use the value method to extract the mean signals from each data map
% and store to a meanSignals cell over exps. The structure of each cell is
% then reshaped to be numAngles x numPos for each exp in meanSignals 
meanSignals = cellfun(@(x) values(x), meanDataMaps,'UniformOut',0);

meanSignals = cellfun(@(x) reshape(x,numAngles,numPos), meanSignals,...
                       'UniformOut',0);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
assignin('base','meanSignals',meanSignals)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%% OBTAIN THE MAXIMUM FOR CENTER POSITION DATA %%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Concatenate the center signals into a numPoints x numAngles 2-d arrays
% for each exp
centerSignals = cellfun(@(x) [x{:,5}], meanSignals, 'UniformOut',0);

% calculate the maximum of the center responses for each exp and get the
% linear index
[maxCenterSignals,maxCenterAngleIdxs] = cellfun(@(x) max(x(:)),....
                                                centerSignals);
%convert the linear index to a subscript getting column (i.e. angle)
[~,maxCenterAngleIdxs] = arrayfun(@(x) ind2sub(size(centerSignals{1}),x),...
                        maxCenterAngleIdxs);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
assignin('base','maxCenterSignals',maxCenterSignals)
assignin('base','maxCenterAngleIdx',maxCenterAngleIdxs)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%% OBTAIN MAXIMUM AT EACH POSTION FOR MAX CENTER ANGLE %%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Now that we have the max center angle we will extract the mean traces for
% this angle at every position and obtain the maximum response at this
% angle for each positiion. We will do this for each experiment loaded.

for exp = 1:numel(maxCenterAngleIdxs)
    % get the max center angle for this exp
    angleIdx = maxCenterAngleIdxs(exp);
    % get the signals for this angle index this will make  a 
    % numDataPts x numPos matrix for each experiment
    signals{exp} = [meanSignals{exp}{angleIdx,:}];
    % get the max during the visual stimulation. This will return an array
    % of maxes one for each column (pos) of data
    maxSignals{exp} = max(signals{exp}(dataSamples,:));
    % We also want the baseVoltage of the exp so we can caculate the change
    % in voltage at each position the grating was shown
    baseVoltages{exp} = mean(signals{exp}(voltSamples,:));
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
assignin('base','maxSignals', maxSignals)
assignin('base','baseVoltages',baseVoltages)

% Convert the maxSignals cell into a matrix numExps x NumPos containing the
% max voltages during stimulation
maxSignalsMatrix = cell2mat(maxSignals');
% conver the cell of base voltages into a matrix numExp x NumPos containing
% the base voltages
baseVoltages = cell2mat(baseVoltages');
% subtract maxes during stimulation from base voltages
deltaVs = bsxfun(@minus, maxSignalsMatrix,baseVoltages);


meanDeltaVSignal = mean(maxSignalsMatrix,1)-mean(baseVoltages,1);

plot([1:numPos],deltaVs)
hold on
plot([1:numPos],meanDeltaVSignal,'color','k','lineWidth', 3)
hold off
 
end

