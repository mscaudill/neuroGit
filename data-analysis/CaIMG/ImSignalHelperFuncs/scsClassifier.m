function [maxAreaAngle, maxSurroundAngle, nSigma, classification, threshold] = ...
                        scsClassifier(signalMaps, cellTypeOfInterest,...
                                      roiSetNum, roiNum, stimulus,...
                                      fileInfo, minNSigma, mThreshold)
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
% scsClassifier calls the area calculator and locates the center angle with
% the largest combined area below the c0 c1 and c2 curves. It then gets all
% the conditions from the signals map for this angle. It then looks at the
% standard deviation of the signals prior to visual stimulation and
% compares with the max response of of each meaned signal during visual
% stimulation. It uses a threshold to decide if the signal is a responding
% or not to each condtion. This results in a binary classification for each
% condition of the stimulus for this angle.
% INPUTS:                          signalMaps:  a cell array of cells
%                                               containing signal maps 
%                                               corresponding to each roi 
%                                               in the imExp. Signal Maps
%                                               are the df/f signals across
%                                               stimulus conditions
%                                   cellTypeOfInterst:cellType of interest,
%                                               currently on pyr and som 
%                                               accepted
%                                   RoiSetNum:  index corresponding to the
%                                               cell containing signal maps
%                                               for that trial
%                                   roiNum:     index used to identify a
%                                               particular signal map in
%                                               the set of signal maps for
%                                               that trial 
%                                   stimulus:   stimulus struct containing
%                                               all stimuli info in imExp
%                                   fileInfo:   structure containg all file
%                                               information in the imExp
%                                   threshold:  scalar multiplier of the
%                                               standard deviation of 
%                                               signals, to decide whether 
%                                               cell responded to a given 
%                                               stimulus condition 
%
% OUTPUTS:                      maxAreaAngle:   angle for which area below 
%                                               center only is greatest
%                               nSigma:         multiples of stds for each
%                                               stimulus condition
%                               classification: binary array classifying
%                                               responses
%                               threshold:      scalar multiplier of the
%                                               standard deviation of 
%                                               signals, to decide whether 
%                                               cell responded to a given 
%                                               stimulus condition 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% calculate the stimulation frames
startFrame = round(stimulus(1,1).Timing(1)*fileInfo(1,1).imageFrameRate);
endFrame = round((stimulus(1,1).Timing(1) + ...
                  stimulus(1,1).Timing(2))*fileInfo(1,1).imageFrameRate);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%% CALL AREA CALCULATOR AND LOCATE MAX CENTER AREA INDEX %%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Call the area calculator to return the areas for all angles and all
% conditions of the surround
[meanAreas, ~, roiKeys] = areaCalculator(signalMaps, roiSetNum, roiNum,...
                                         stimulus, fileInfo);
% Depending on the cellType we will calculate the max angle differently
% (although later we may unify be always requiring max angle at
% max(sum(co,c1,c2,I).
switch cellTypeOfInterest
    case 'pyr'
        % use cellfun to sum the c0 c1 c2 meanAreas and locate the maximum                                     
        [~, maxIndex] = max(cellfun(@(x) sum(x(1:3)), meanAreas));
    case 'som'
        % use cellfun to sum the co and I meanAreas to loc max
        [~, maxIndex] = max(cellfun(@(x) (x(1)+x(4)), meanAreas));
end
% convert the maxIndex into an angle using the roiKeys returned from the
% area calculator
maxAreaAngle = roiKeys{maxIndex};
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%% OBTAIN TRIALS FROM SIGNAL MAPS %%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% obtain the roiMap for the specified roi
roiMap = signalMaps{roiSetNum}{roiNum};

% retrieve the signals for all trials and all condition for the maxArea
% angle (e.g. a 10x5 cell array)
allSignals = roiMap(maxAreaAngle);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%% COMPUTE THE MEAN SIGNALS FOR EACH CONDITION %%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% First determine the number of conditions (usually 5: c0 c1 c2 I S)
numConds = size(allSignals,2);

% Initialize two cells to hold matrices of all trials and arrays of means
% of those trials
condMats = cell(1,numConds);
condMeans = cell(1,numConds);

% loop through the conditions and for each condtion, conatenate the trials
% along the second dimension and store this matrix to the condMats cell.
% Then compute the mean along the second dim (i.e. across trials) and store
% that result to the condMeans cell of arrays
for cond = 1:numConds
        condMats{cond} = cat(2,allSignals{:,cond}); 
        % above makes a matrix with rows that correspond to signal points 
        % and columns corresponding to trials
        condMeans{cond} = mean(condMats{cond},2);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%% RECOMPUTE SURROUND CONDMEAN %%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% In the condMeans cell above we have calculated the mean signals for the 5
% surround conditions at the angle where c0 c1 and c2 areas are greatest.
% However we are interested in knowing wheter the surround responded at any
% angle so we will determine the mean surround response across all angles
% and determine the maximum area trace. Then we will replace the
% condMeans{5} with this trace. This procedure ensures that the surround is
% tested at every angle for response.

% We start by retrieving the surround trials for each angle. The
% roiMap.Values is the cell contatining all angles and all surrounds and
% all trials. From this we will create a cell over angles that holds
% matrices of surround traces. The rows will correspond to data points and
% the columns to trials
surroundMats = cellfun(@(x) cat(2,x{:,5}), (cellfun(@(r) r, ...
                        roiMap.values, 'uniformOut',0)),'uniformOut',0);

% now compute the mean (across trials (i.e. the 2 dim)
meanSurrounds = cellfun(@(f) mean(f,2), surroundMats, 'uniformOut',0);

% now we need to compute the areas below each meanSurround trace during
% visual stimulation
meanAreaSurrounds = cellfun(@(x) trapz(x(startFrame:endFrame)),...
                    meanSurrounds);
                
% calculate the max index of the meanAreaSurrounds
[~,maxSurroundIndex] = max(meanAreaSurrounds);

% obtain the angle of this surround index
maxSurroundAngle =  roiKeys{maxSurroundIndex};

% lastly, replace condMeans{5} with the meanSurrounds{maxSurroundIndex}
condMeans{5} = meanSurrounds{maxSurroundIndex};
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%% COMPUTE SIGMA PRIOR TO VISUAL STIM %%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We now want to compute the satndard deviation of the mean signals prior
% to stimulation. We do this so we can determine the size of the signal
% during stimulation in units of std deviations.

% First calculate the mean of the mean signals across the conditions
condMeanSignal = mean(cell2mat(condMeans),2);

priorStdMean = std(condMeanSignal(1:startFrame));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%% CALCULATE NSIGMA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
nSigma = zeros(1,numConds);
for cond = 1:numConds
    vStimMaxMean = max(condMeans{cond}(startFrame:endFrame));
    nSigma(cond) = vStimMaxMean/priorStdMean;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%% MAKE PUTATIVE CLASSIFICATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We first determine a threshold based on the maximum of nSigmna
threshold = max(nSigma)/mThreshold;
% Now ensure that we at least meet the minimum user defined acceptable
% signal size
if max(nSigma) < minNSigma
    classification = logical([0,0,0,0,0]);
else
classification = logical(nSigma > threshold);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end

