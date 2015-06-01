function state = ImExpMakerInit(~)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

% initialize fileNames empty
state.imageFileNames = {};
state.stimFileNames = {};
state.imageFileName = '';
state.stimFileName = '';
state.missingTriggers = {};
% initialize the trigger and channels of interest
state.triggerNumber = 1;
state.chToDisplay = 2;
state.chsToSave = [2];
state.saveEncoder = [];
state.chsToCorrect = [2];
state.scaleFactor = 1;

%initialize the encoder options
state.encoderOffset = 0.2;
state.encoderThreshold = 0.5;
state.encoderPercentage = 75;

% Load directory information to state
ImExpDirInformation;
state.imageFileLoc = dirInfo.imageFileLoc; 
state.stimFileLoc = dirInfo.stimFileLoc;
state.imExpRawFileLoc = dirInfo.imExpRawFileLoc;
end

