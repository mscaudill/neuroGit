function scsSignalAnalyzerII(cellTypeOfInterest, varargin)
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
%                           varargin (uses uiGui to load imExp with ROIs)
% OUTPUTS:                  None saves an imExp with anlaysis fields
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%% PARSE INPUT ARGS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% If the user has not supplied inputs we will use a minimumNSigma for
% classification of 40 stds of the noise and a threshold divisor of 2.5.
% Please see scsClassifier for more details.
if nargin < 2
    minNSigma = 40;
    mThreshold = 2.5;
elseif nargin < 3
    minNSigma = varargin{1};
    mThreshold = 2.5;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
                        'SignalRunState','signalMaps','cellTypes','framesDropped');

close(loadMsg)

% Extract variables from the imExp needed for classification and scsMetrics
% functions
signalMaps = imExp.signalMaps;
stimulus = imExp.stimulus;
fileInfo = imExp.fileInfo;
% We need to check if frames were dropped by the user
if isfield(imExp,'framesDropped')
    framesDropped = imExp.framesDropped;
else
    framesDropped = 0;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%% CALL AREACALCULATOR, SCSCLASSIFIER, & SCSMETRICS %%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The signal maps contains maps of signals for each roi which is specified by an
% roiSet# and then an roiNumber. We will need to loop throught the signal
% maps and call the areaCalculator, the scsClassifier and the scsMetrics

% Loop over maps (cntrl and led)
for map = 1:numel(signalMaps)
    if ~isempty(signalMaps{map})
        % if map is not empty loop over roiSets and rois
        for roiSet = 1:numel(signalMaps{map})
            for roiNum = 1:numel(signalMaps{map}{roiSet})
%%%%%%%%%%%%%%%%%%%%%%%%%%%% CALL AREA CALCULATOR %%%%%%%%%%%%%%%%%%%%%%%%%
        % the area calulator takes the signal map for a specific roi and
        % returns back cell arrays of mean areas and std(areas)
                [meanAreas{map}{roiSet}{roiNum}, ...
                    stdAreas{map}{roiSet}{roiNum},~,areasMatrix{map}] = ...
            areaCalculator(signalMaps{map}, roiSet, roiNum, stimulus,...
                            fileInfo, framesDropped);
        
%%%%%%%%%%%%%%%%%%%%%%%%%%%% CALL SCSCLASSIFIER %%%%%%%%%%%%%%%%%%%%%%%%%%%      
        % call the scsClassifier
        [maxAreaAngle{map}{roiSet}{roiNum},...
            maxSurroundAngle{map}{roiSet}{roiNum},...
            nSigma{map}{roiSet}{roiNum},...
            classification{map}{roiSet}{roiNum} ] = ...
                    scsClassifier(signalMaps{map},cellTypeOfInterest,...
                                  roiSet, roiNum, stimulus, fileInfo,...
                                  minNSigma,mThreshold, framesDropped);
                              
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% CALL SCSMETRICS %%%%%%%%%%%%%%%%%%%%%%%%%%%                              
        [surroundOriIndex{map}{roiSet}{roiNum},...
            surroundGains{map}{roiSet}{roiNum},...
            suppressionIndex{map}{roiSet}{roiNum} ] =...
                        scsMetrics(signalMaps{map},cellTypeOfInterest, roiSet,...
                                   roiNum, maxAreaAngle{map}{roiSet}{roiNum},...
                                   stimulus, fileInfo,framesDropped);
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

assignin('base','imExp_analyzed',imExp)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% SAVE IMEXP %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% call the imExpSaverFunc to save the imExp with the tag _analyzed
imExpSaverFunc([],imExpName, imExp, 'analyzed')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end

