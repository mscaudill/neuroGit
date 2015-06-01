function fluorCalibration(roiSet, roiNum, varagin)
%fluorCalibration opens an imExp and an eExp and plots the trasform
%function between the spike numbers and area below the fluorecscence curve
%for a given cell specified in the imExp by roiSet, roiNum.
% INPUTS:   roiSet, the roiSet to whcih the cell belongs
%           roiNum, the number within the roiSet that identifies our cell
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% LOAD EEXP %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We will now call multiEexpLoader to load single or multiple Exp files
% from the raw electroExp directory

eExps = multiEexpLoader('raw', {'spikeIndices','stimulus','behavior',...
                        'fileInfo'});
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% LOAD IMEXP %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We will now call the multiImExpLoader to load a the specified fields from
% a set of imExps. We technically don't need to reload some of the fields
% since they should be the same as in eExp but we do so just in case. 

imExps = multiImExpLoader('roi',{'signalMaps','stimulus',...
                                'behavior','fileInfo'});
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%% AUTO LOCATE STIMVARIABLE %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We will call the function autoLocateStimVariables to locate the variable
% that was varied in the eExp. Not we assume here that there was only one
% variable. If not true we throw an error
stimVariable = autoLocateStimVariables(eExps{1}.stimulus);

if numel(stimVariable) > 1
    error(['Please select data with only one stimulus variable for',...
           'calibration'])
else
    % We convert the cell array of stimulus variables to a string since
    % there is only one
    stimVariable = stimVariable{1};
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%% CALL THE AREA CALCULATOR %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We now will call the area calculator and return the mean areas abd the
% std of the areas

for imExp = 1:numel(imExps)
        [meanAreas{imExp},stdAreas{imExp},~] = areaCalculator(...
                          imExps{imExp}.signalMaps, ...
                          roiSet, roiNum, imExps{imExp}.stimulus,...
                          imExps{imExp}.fileInfo);

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%% OBTAIN SPIKE TIMES MAP FOR EACH EEXP %%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for eExp = 1:numel(eExps)
    spikeTimesMap = oneDimSpikeTimesMap(eExps{eExp}.spikeIndices,...
                                eExps{eExp}.stimulus, stimVariable,...
                                eExps{eExp}.behavior, ...
                                eExps{eExp}.fileInfo);

    spikeTimes = spikeTimesMap.values;

    spikeTimesCell = vertcat(spikeTimes{:})';

    spikesPerSec = cellfun(@(x)...
        numel(find(x>1 & x<3))/eExps{eExp}.stimulus(1,1).Timing(2),...
        spikeTimesCell);
    
    meanSpikesPerSec{eExp} = mean(spikesPerSec,1);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%assignin('base','meanSpikesPerSec',meanSpikesPerSec)
%assignin('base','meanAreas',meanAreas)
for eExp = 1:numel(eExps)
    plot(meanSpikesPerSec{eExp},cell2mat(meanAreas{eExp}),'lineStyle','none','Marker','o')
    hold all
    ylabel('FiringRate sp/s')
    xlabel('meanArea')
end
end

