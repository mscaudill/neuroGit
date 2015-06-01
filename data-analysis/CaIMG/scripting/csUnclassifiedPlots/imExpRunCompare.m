function imExpRunCompare(stimVariable,roiList, comparisonCondition)



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
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%% LOAD DIRECTORY INFORMATION %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ImExpDirInformation;
imExpFileLoc = dirInfo.imExpFileLoc;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%% LOAD IMEXP WITH ROIS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Call uigetfile (built-in) to select the imExp and get path to file
[imExpName, PathName] = uigetfile(imExpFileLoc, 'MultiSelect','off');

% now load the imExp using full-file to construct path\fileName
imExp = load(fullfile(PathName,imExpName));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for runState = 0:1
    for roi = 1:numel(roiList)
        roiSet = roiList{roi}(1); % the set number is the first element
        roiNumber = roiList{roi}(2); % the roiNumber is the second
        
        [~, fMap, ~] = fluorMapV2(imExp, stimVariable, 3,...
                          imExp.rois{roiSet}{roiNumber},runState);
                      
        % The values from the map are the df/f signals. Ex. for two files
        % with 13 triggers each and 50 frames per trigger the cell allSigs
        % = {{[50x1] [50x1]},{[50x1] [50x1]}...}
        allSigs = fMap.values;
                      
                      
        % call cellfun within cellfun to concatenate the double arrays of
        % signals along the column dimension (cell with frames/stack x
        % numstimSets doubles) e.g 50 frames x 2 stimulusFiles
        signalMatrices = cellfun(@(y) cat(2,y{1:end}), cellfun(@(x) x,...
                                allSigs, 'UniformOut', 0), 'UniformOut',0);
                      
         % Be sure to remove any empty cells present
         emptyCells = cellfun(@isempty,signalMatrices);
         signalMatrices(emptyCells) = [];
                      
         % Compute the mean of the matrices we just concatenated along the
         % column dimension (cell with frames/stack x 1 double array)
         meanSignals = cellfun(@(r) mean(r,2), signalMatrices,...
                                                'uniformout',0);
                                            
         % calculate the start and end frame of the stimulus epoch
        startFrame = round(imExp.stimulus(1,1).Timing(1)*...
                           imExp.fileInfo(1,1).imageFrameRate);
                       
        endFrame = round((imExp.stimulus(1,1).Timing(1) + ...
                  imExp.stimulus(1,1).Timing(2))*...
                  imExp.fileInfo(1,1).imageFrameRate);
              
        meanSignalAreas = cellfun(@(r) trapz(r(startFrame:endFrame,:)),...
                      meanSignals);
                                            
         % now compute the maximum of meanSignals across angles
         [maxMeanArea{runState+1}{roi}, maxIndex] = max(meanSignalAreas);
         
         % circularly shift the meanSignalAreas by 1/4 the size of the
         % (meansignalAreas array-1) note this assumes we have a blank.
         % Hence the -1 and assumes that we have run angles from 0 to 330
         shiftedMeans = circshift(meanSignalAreas,[2,...
             round((numel(meanSignalAreas)-1)/4)]);
         
         % use the maxindex to compute the orthogonal maximum
         orthoMax{runState+1}{roi} = max(shiftedMeans(maxIndex));
                      
    end
end
assignin('base','maxMeanArea',maxMeanArea)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%% PLOT RUN VS NO RUN CONDITIONS %%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure(1)
scatter([maxMeanArea{1}{:}],[maxMeanArea{2}{:}],50,'k')

% set the labels
xlabel('$\int\frac{\Delta F}{F}dt$','Interpreter','LaTex','FontSize',14);
ylabel('$\int\frac{\Delta F}{F}dt$','Interpreter','LaTex','FontSize',14);

set(gca,'FontSize',12);

figure(2)
scatter([orthoMax{1}{:}],[orthoMax{2}{:}],50,'k')
% set the labels
xlabel('$\int\frac{\Delta F}{F}dt$','Interpreter','LaTex','FontSize',14);
ylabel('$\int\frac{\Delta F}{F}dt$','Interpreter','LaTex','FontSize',14);

set(gca,'FontSize',12);
end

