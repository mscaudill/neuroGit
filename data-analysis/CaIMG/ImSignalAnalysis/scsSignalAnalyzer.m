function scsSignalAnalyzer(cellTypeOfInterest, varargin)
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
%scsSignalAnalyzer is a wrapper function for scsClassifier and scsMetrics.
%It opens an imExp with ROIs and analyzes each cell in the experiment,
%classifies the cells and computes the metrics specified in the scsMetrics
%function (i.e. surround orientation index, etc) It autoSaves this analyzed
%imExp or allows the user to specify the save location and fileName.
% INPUTS:                   cellType, cell of interest for analysis
%                           varargin (see parser below)
% OUTPUTS:                  None saves an imExp with anlaysis fields
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%% PARSE INPUT ARGS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The input parser will allow us to designate default values for the input
% arguments in a keyword,value manner. It provides flexibility to the user
% in customizing this function to suit their purposes

% construct a parser object (builtin matlab class)
p = inputParser;
% add required variables
addRequired(p,'cellTypeOfInterest');

% add optional variables with defaults
% If the user has not supplied inputs we will use a minimumNSigma for
% classification of 40 stds of the noise and a threshold divisor of 2.5.
% Please see scsClassifier for more details.
defaultMinNSigma = 17; %40;
addParamValue(p, 'minNSigma',defaultMinNSigma) 
defaultMThreshold = 2; %2.5;
addParamValue(p, 'mThreshold', defaultMThreshold)

defaultFramesDropped = [];
addParamValue(p, 'framesDropped', defaultFramesDropped)

% call the input parser method parse
parse(p, cellTypeOfInterest, varargin{:})

% finally retrieve the variable arguments from the parsed inputs
minNSigma = p.Results.minNSigma;
mThreshold = p.Results.mThreshold;
framesDropped = p.Results.framesDropped;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp(minNSigma)
disp(mThreshold)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%% LOAD DIR INFORMATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We load the ImExpDirInformation file to identify where to load imExps
% from and where to save them to once this function returns
ImExpDirInformation;
% We will be loading imExps_rois and saving to an analyzed file directory
% listed in IMExpDirInformation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%% LOAD IMEXP W/ ROIS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We will no open a dialog box to obtain the imExp-rois name and location
% using uigetfile (built-in)

% call uigetfile to obtain the imExpName and its filePath
[imExpName, PathName] = uigetfile(dirInfo.imExpRoiFileLoc,...
                                            'MultiSelect','off');
                                        
% We will now load an imExp. display a wait message during the loading
loadMsg = msgbox('LOADING SELECTED IMEXP_ROIS: Please Wait...');
                                        
% now load the imExp using full-file to construct path\fileName. We will
% exclude the correctedStacks and the stackExtremas from the loading since
% they are large (>1GB) and are already saved in the imExp_Roi
imExp = load(fullfile(PathName,imExpName),'fileInfo','stimulus','rois',...
                        'SignalRunState','signalMaps','cellTypes');

close(loadMsg)

% Extract variables from the imExp needed for classification and scsMetrics
% functions
signalMaps = imExp.signalMaps;
if numel(signalMaps) < 2
    % This maintains backward compatibility with previous code which
    % assumed signal maps to contain roiSets for non-led only. We here
    % convert signalMaps with only 1 subcell into a 2-subcell cell array.
    signalMaps = {{signalMaps},{}};
end
stimulus = imExp.stimulus;
fileInfo = imExp.fileInfo;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%% CALL AREACALCULATOR, SCSCLASSIFIER, & SCSMETRICS %%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Each signal map contains maps of signals for each roi which is specified
% by an roiSet# and then an roiNumber. We will need to loop throught the
% signal maps and call the areaCalculator, the scsClassifier and the
% scsMetrics

for ledCond = 1:2
    if ~isempty(signalMaps{ledCond}) 
        for roiSet = 1:numel(signalMaps{ledCond})
            for roiNum = 1:numel(signalMaps{ledCond}{roiSet})
                
                if ledCond==1 % NON LED TRIALS
                    %%%%%%%%%%%%%%%%% CALL AREA CALCULATOR %%%%%%%%%%%%%%%%
                    % the area calulator takes the signal map for a
                    % specific roi and returns back cell arrays of mean
                    % areas and std(areas)
                    [meanAreas{roiSet}{roiNum},...
                     stdAreas{roiSet}{roiNum},~,...
                     areasMatrix] = areaCalculator(signalMaps{ledCond},... 
                                                   roiSet,roiNum,...
                                                   stimulus, fileInfo,...
                                                   framesDropped);
                                               
                    %%%%%%%%%%%%%%%% CALL CLASSIFIER %%%%%%%%%%%%%%%%%%%%%%
                    % call the scsClassifier to construct binary array of
                    % response classifications
                    [maxAreaAngle{roiSet}{roiNum}, ...
                     maxSurroundAngle{roiSet}{roiNum},...
                     nSigma{roiSet}{roiNum}, ...
                     classification{roiSet}{roiNum},...
                     threshold{roiSet}{roiNum} ,...
                     priorStdMean{roiSet}{roiNum} ] = ...
                                    scsClassifier(signalMaps{ledCond},...
                                                  cellTypeOfInterest,...
                                                  roiSet,...
                                                  roiNum, stimulus,...
                                                  fileInfo,...
                                                  minNSigma, mThreshold,...
                                                  framesDropped);
                                              
                     disp(['Cell ', num2str(roiSet),',',num2str(roiNum),...
                           '  (MAX SIGMA, , THRESHOLD)= ',...
                           num2str(max(nSigma{roiSet}{roiNum})), ' : ',...
                           num2str(threshold{roiSet}{roiNum})])
                     disp(nSigma{roiSet}{roiNum})
                                              
                    %%%%%%%%%%%%%%% CALL SCSMETRICS %%%%%%%%%%%%%%%%%%%%%%%
                    % Compute the surround metrics
                    [surroundOriIndex{roiSet}{roiNum},...
                     surroundGains{roiSet}{roiNum},...
                     suppressionIndex{roiSet}{roiNum} ] =...
                                 scsMetrics(signalMaps{ledCond},...
                                            cellTypeOfInterest,...
                                            roiSet, roiNum,...
                                            maxAreaAngle{roiSet}{roiNum},...
                                            stimulus, fileInfo,...
                                            framesDropped);                           
                
                elseif ledCond==2 % LED TRIALS                              
                    %%%%%%%%%%%%%%%%%%%%% CALL AREA CALCULATOR %%%%%%%%%%%%
                    [meanAreas_led{roiSet}{roiNum},...
                     stdAreas_led{roiSet}{roiNum},~,...
                     areasMatrix_led] = areaCalculator(...
                                             signalMaps{ledCond},... 
                                             roiSet, roiNum,...
                                             stimulus, fileInfo,...
                                             framesDropped);
                                                
                    %%%%%%%%%%%%%%%% CALL CLASSIFIER %%%%%%%%%%%%%%%%%%%%%%
                    % call the scsClassifier to construct binary array of
                    % response classifications. Note we use the
                    % maxAreaAngle from the non-led trials
                    [maxAreaAngle_led{roiSet}{roiNum}, ...
                     maxSurroundAngle_led{roiSet}{roiNum},...
                     nSigma_led{roiSet}{roiNum}, ...
                     classification_led{roiSet}{roiNum} ] = ...
                                    scsClassifier(signalMaps{ledCond},...
                                             cellTypeOfInterest,...
                                             roiSet,...
                                             roiNum, stimulus,...
                                             fileInfo,...
                                             minNSigma,...
                                             mThreshold,...
                                             framesDropped,...
                                             'maxAreaAngle',...
                                             maxAreaAngle{roiSet}{roiNum});
                                              
                    %%%%%%%%%%%%%%% CALL SCSMETRICS %%%%%%%%%%%%%%%%%%%%%%%
                    % Compute the surround metrics, notice we are choosing
                    % to use the max area angle corresponding to the
                    % non-led trials
                    [surroundOriIndex_led{roiSet}{roiNum},...
                     surroundGains_led{roiSet}{roiNum},...
                     suppressionIndex_led{roiSet}{roiNum} ] =...
                                 scsMetrics(signalMaps{ledCond},...
                                            cellTypeOfInterest,...
                                            roiSet, roiNum,...
                                            maxAreaAngle{roiSet}{roiNum},...
                                            stimulus, fileInfo,...
                                            framesDropped);          
                end
            end
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%% SAVE RESULTS TO IMEXP %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We will now save all the results to areaMetrics, signalClassification and
% signalMetrics fields in the imExp
imExp.cellTypeOfInterest = cellTypeOfInterest;
imExp.areaMetrics.meanAreas = meanAreas;
imExp.areaMetrics.stdAreas = stdAreas;
imExp.areaMetrics.areasMatrix = areasMatrix;
imExp.signalClassification.classification = classification;
imExp.signalClassification.maxAreaAngle = maxAreaAngle;
imExp.signalClassification.maxSurroundAngle = maxSurroundAngle;
imExp.signalClassification.nSigma = nSigma;
% Now save the metrics results to signalMetrics field in the imExp
imExp.signalMetrics.surroundOriIndex = surroundOriIndex;
imExp.signalMetrics.surroundGains = surroundGains;
imExp.signalMetrics.suppressionIndex = suppressionIndex;

imExp.areaMetrics.meanAreas_led = meanAreas_led;
imExp.areaMetrics.stdAreas_led = stdAreas_led;
imExp.areaMetrics.areasMatrix_led = areasMatrix_led;
imExp.signalClassification.classification_led = classification_led;
imExp.signalClassification.maxAreaAngle_led = maxAreaAngle_led;
imExp.signalClassification.maxSurroundAngle_led = maxSurroundAngle_led;
imExp.signalClassification.nSigma_led = nSigma_led;
% Now save the metrics results to signalMetrics field in the imExp
imExp.signalMetrics.surroundOriIndex_led = surroundOriIndex_led;
imExp.signalMetrics.surroundGains_led = surroundGains_led;
imExp.signalMetrics.suppressionIndex_led = suppressionIndex_led;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

assignin('base','imExp_analyzed',imExp)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% SAVE IMEXP %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% call the imExpSaverFunc to save the imExp with the tag _analyzed
imExpSaverFunc([],imExpName, imExp, 'analyzed')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end

