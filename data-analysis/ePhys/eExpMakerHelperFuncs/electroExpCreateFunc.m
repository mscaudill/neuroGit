function [Exp] = electroExpCreateFunc(state)
%electroExpCreateFunc creates an array of structures called an exp that
%contains all raw data and spike information form an listing of data files
%imported into the expMaker gui.
% INPUTS:                       state: a structure containin data and
%                                stimulus file names, recorded channel 
%                                information, filterOptions, and detection
%                                options. It is passed directly from gui.
%                                For a complete listing of all the
%                                parameters, please see ExpMakerInitFile.m
% OUTPUTS:                      electroExp: a 2-D array of structures
%                                ordered by file name and trigger number
%                                containing all the rawData, beavior, spike
%                                Information and all associated metadata
%                                such as filter options etc.
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
%TESTING INPUTS
% state.dataFileNames = {'MSC_2012-06-29_n1ffgrating_3.daq',...
%                        'MSC_2012-06-29_n1ffgrating_4.daq',...
%                        'MSC_2012-06-29_n1ffgrating_5.daq',...
%                        'MSC_2012-06-29_n1ffgrating_6.daq'};
% state.stimFileNames = {'MSC_2012-6-29_n1ffgrating_3_TrialsStruct',...
%                         'MSC_2012-6-29_n1ffgrating_4_TrialsStruct',...
%                         'MSC_2012-6-29_n1ffgrating_5_TrialsStruct',...
%                         'MSC_2012-6-29_n1ffgrating_6_TrialsStruct'};
% state.chsToSave = [2];
% state.downSampleChs = [5];
% state.downSampleFactor = 1000;
% state.chNames ={'trigger','voltage','photodiode','field','encoder'};
% state.filterChs=[2];
% 
% state.behaviorCheck = 1; %i.e. check for running
% state.encoderOffset = 6.6; % dc offset of the encoder
% state.encoderThreshold = 0.5;
% state.encoderPercentage = 75;
% 
% state.filter = 'Elliptic';
% state.order = 5;
% state.stopBandRipple = 40;
% state.passBandRipple = 3;
% state.type = 'high';
% state.cutOffFreq = 300;
% 
% state.detectOnChs = [2];
% state.threshold = -7;
% state.thresholdType = 'Standard Dev';
% state.maxSpikeWidth = 3;
% state.spikeWindow = [2,2];
% state.refractoryPeriod = 10;
% state.triggerRemoval = 'true';
% 
% state.cellType = 'som';
% state.cellDepth = 250;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%% DIRECTORY INFORMATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Tell electroExpCreator where to start search for .daq and stimulus files
electroExpDirInformation
daqFileLoc = state.dataFileLoc;
stimFileLoc = eDirInfo.StimFileLoc;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%% CONSTRUCT FIELDNAMES FOR ELECTROEXP %%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We are first going to construct fieldNames for the fields that we will
% create in electroExp.data . These fieldNames arrived here from the state
% structure passed from the ExpMaker gui.
fieldNames = {state.chNames{state.chsToSave}};
% initialize a structure to hold all the stimulus information
stimulusStruct = struct([]);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Start a timer so the user knows how long it takes to execute this fun.
tic

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%% EXTRACT METADATA, CONDITION DATA %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We perform a switch based on the data fileType stored in state
switch state.dataType
    case 'daq'
        %%%%%%%%%%%%%%%%%%%%%%%%%% GET DAQINFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %For each file we want to get a little ino about the file such as
        %the sampling rate etc so we can save these variables to exp for
        %later use. We will use daqInfo function of the daq toolbox to
        %accomplish this. (Note we assume that all files contain the same
        %number of triffers and that the sampling rate is constant) If this
        %is incorrect, then you must move these commands into the for loop
        %below and extract for each file!)
        daqinfo = daqread([daqFileLoc,state.dataFileNames{1}],'info');
        
        % number of triggers is stored in the following struct returned
        % from the above function daqinfo
        numTriggers = daqinfo.ObjInfo.TriggersExecuted;
        
        % we also want to include the sampling rate in the exp for later
        % reconstructing time series
        samplingFrequency = daqinfo.ObjInfo.SampleRate;
        samplesPerTrigg = daqinfo.ObjInfo.SamplesPerTrigger;
    case 'abf'
        %%%%%%%%%%%%%%%%%%%% GET ABF INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % For each file we will open the abf header file and extract the
        % number of triggers, the sampling frequency and the samples in
        % each trigger
        [~,~,Info] = abfload([daqFileLoc,state.dataFileNames{1}], 'info');
        numTriggers = Info.lActualEpisodes;
        samplesPerTrigg = Info.sweepLengthInPts;
        samplingFrequency = 1/(Info.si*10^-6);
end

%%%%%%%%%%%%%%%%%%%% DATA EXTRACTION AND CONDITIONING %%%%%%%%%%%%%%%%%%%%%
% The for loop below over each fileName will load the corresponding
% stimulus file to stimulusStruct, read in the data file and condition the
% data by removing NaNs separating triggers and reshape the data to a cell
% array of data matrices for rapid conversion to a data structure to be
% added to the exp structure.

for name=1:numel(state.dataFileNames)
    %%%%%%%%%%%%%%%%%% ADD METADATA TO EXP.FILEINFO FIELD %%%%%%%%%%%%%%%%%     
    Exp.fileInfo(name,1).samplingFreq = samplingFrequency;
    Exp.fileInfo(name,1).samplesPerTrigg = samplesPerTrigg;
    Exp.fileInfo(name,1).dataFileName = state.dataFileNames{name};
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %%%%%%%%%%%%%%%%%%%%% LOAD STIMULUS TRIALS STRUCT %%%%%%%%%%%%%%%%%%%%%
    load([stimFileLoc,state.stimFileNames{name}])
    stimulusStruct = [stimulusStruct, trials];
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%%%%%%%%%%%%%%%%%%% READ IN DATA FILE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % If behavior check is requested, we will load the encoder data in as
    % well independent of whether the user selected to save the encoder ch.
    if state.behaviorCheck == 1;
        % find whcih index the encoder ch is among the state.chNames
        encoderChIndex = find(strcmpi(state.chNames,'encoder'));
        % make a union between the chsToSave and encoder ch.
        chsToLoad = union(state.chsToSave, encoderChIndex);
    else
        % if no behavior check requested, load only the state.chsToSave
        chsToLoad = state.chsToSave;
    end
    
    % Depending on whether the incoming data file is type 'daq' or 'abf' we
    % will use a different file loader. Perform a switch to accomplish
    switch state.dataType
        case 'daq'
            % For each dataFileName, we read in the chsToLoad using daqRead
            % (see daqToolbox Matlab add-on)
            data = daqread([daqFileLoc,state.dataFileNames{name}],...
                            'Channels', chsToLoad);
                        
            %%%%%%%%%%%%%% CONDITION AND RESHAPE OF DATA %%%%%%%%%%%%%%%%%%
            % Triggers are denoted by NaN's in daq acquired data so we
            % remove these
            data(isnan(data(:,1)),:)=[]; 
    
            % We reshape the data to be a three dimensional array where
            % rows are data points, columns are triggers and 'depth' is
            % chsToLoad
             allData(:,:,:) = ...
                       reshape(data,[],numTriggers,numel(chsToLoad));
        case 'abf'
            % for each data file we will call the abf loader. The abfloaded
            % data is three-dim and contains all chs. (it does not allw
            % specific channel loading). The shape of the loaded data is
            % numDataPts x numChs x numTriggers. We will reshape this to be
            % numDataPts x numTriggers x numChs
            [data,~,~] = abfload([daqFileLoc,state.dataFileNames{name}]);
            
            % now perform the reshape using permute on the 2nd and 3rd dim
            allData = permute(data,[1,3,2]);
            
            % now the user may not have requested all chs so we will remove
            % the chs that they did not ask for (recall abfloader loads
            % all)
            allData = allData(:,:,chsToLoad);
            assignin('base','allData',allData);
    end
            
    
    
    % allData contains the data the user would like to save and if selected
    % also the encoder data. We need to know if enoder data is present and
    % pull that data out to a new array called behaviorData since the user
    % may want to perform a behavior check without saving the encoder
    % channel
    
    % CASE 1: Do behavior check and Do NOT SAVE encoder ch
    if state.behaviorCheck == 1 && ...
            sum(state.chsToSave==encoderChIndex)==0
        
        % Find the slice in the array (i.e. depth) that corresponds to the
        % encoder channel
        encoderSlice = find(chsToLoad==encoderChIndex);
        
        % Get the indices of all the slices by making a linearly spaced
        % array.
        allSlices = linspace(1,numel(chsToLoad),numel(chsToLoad));
        
        % Extract the encoder slice to behavior data array for this file
        behaviorData(:,:,name) = allData(:,:,encoderSlice);
        
        % make an array of exp data that excludes the encoder slice using
        % setDiff logical
        expData(:,:,:) = allData(:,:,setdiff(allSlices,encoderSlice));
        
        % CASE 2: Do behavior check and  SAVE encoder
    elseif state.behaviorCheck == 1 && ...
                            sum(state.chsToSave==encoderChIndex)>0
                        
        % Find the slice in the array (i.e. depth) that corresponds to the
        % encoder channel
        encoderSlice = (chsToLoad==encoderChIndex);
        
        % Extract the encoder slice to behavior data array for this file
        behaviorData(:,:,name) = allData(:,:,encoderSlice);  
        
        % Since we are saving the encoder ch in this case, expData is all
        % the data
        expData = allData;
        
        % CASE 3: DO NOT perform behavior check
    elseif state.behaviorCheck ~= 1
        % If no behavior check requested simply save allData (which may or
        % may not include encoder to expData
        expData = allData;
        
    end

    % We ultimatley want the data to be a stucture so we will first convert
    % into a cell array using the row dimension (i.e. data pts) as the
    % length of each array in the cell array. Note this collapses the first
    % dim (i.e. data pts dim of allData) of expData. We also ensure that
    % the cell array is numTriggers along the row dim and num(chsToSave
    % along the column dim) for each filename. The end result is a cell
    % array  numTriggers X numChsToSave X numFiles and each element is the
    % data pts for that (trigger, ch, fileNumber)
    dataCell(:,:,name) = reshape(num2cell(expData,1),numTriggers,...
        numel(state.chsToSave));
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% DOWNSAMPLE DATA %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% If the user has requested to downSample chs we do this here using cellFun
% obtain the indices of the chs to be downsampled (Remember chs are columns
% in dataCell
if sum(state.chsToSave==state.downSampleChs) > 0;
    downSampleIndices = (state.chsToSave == state.downSampleChs);

    % use cellfun and logical downSampleIndices in cols to downsample the
    % requested chs by the amount downSampleFactor
    dataCell(:,downSampleIndices,:) = ...
                        cellfun(@(t) t(1:state.downSampleFactors:end),...
                           dataCell(:,downSampleIndices,:),'UniformOut',0);
end
% IMPORTANT NOTE: Downsampling occurs before filtering and spike detection
% so if the user decides to downsample a ch to detect (i.e. a voltage ch be
% aware that the spike times will change depending on how aggressive the
% downSampling is. It is therefore NOT recomended to downsample the
% chsToDetect on.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%% PERFORM RUN DETECTION %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% It the user request a behaviorCheck then we will call runDetect on the
% behavior data array
if state.behaviorCheck
    for name = 1:numel(state.dataFileNames)
        for trigger = 1:numTriggers
            boolean{name,trigger} = ...
                            runDetect(behaviorData(:,trigger,name),...
                            state.encoderOffset, state.encoderThreshold,...
                            state.encoderPercentage);
        end
    end
    
    % convert boolean cell array to structure using the third dim (i.e. the
    % logical value as the elements of each struct.
    booleanStruct(:,:) = cell2struct(boolean,'Running',3);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
    %%%%%%%%%%%%%% ADD BEHAVIOR TO EXP STRUCTURE %%%%%%%%%%%%%%%%%%%%%
    Exp.behavior = booleanStruct;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
% If the user selects not to do a behavior check we still create a behavior
% field but fill it with 2's meaning the user does not care about running
else
    Exp.behavior = cell2struct(...
                    mat2cell(2*ones(size(stimulusStruct,1),...
                    size(stimulusStruct,2)),...
                    ones(1,size(stimulusStruct,1)),...
                    ones(1,size(stimulusStruct,2))),...
                    'Running',3);
end

%%%%%%%%%%%%%%%%%%%%%%%% PLACE DATA INTO EXP STRUCTURE %%%%%%%%%%%%%%%%%%%%
% our data is now stored in a cell array that is numTriggers x num
% chsToSave x numFiles so we are now ready to convert the cell array to a
% dataStruct.  The data structure will  will contain the fields specified
% by the second dimension in the cell array (i.e. the chsTo save).
dataStruct(:,:) = cell2struct(dataCell,fieldNames,2);

% Since it is more common to refernce the fileName first then the trigger
% number we transpose the whole structure
dataStruct = dataStruct';

% Add this structure to the Exp structure
Exp.data = dataStruct;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%% PLACE STIMULI INTO EXP STRUCTURE %%%%%%%%%%%%%%%%%%%%%
% Add the stimuli structure the the Exp struct
stimulusStruct = stimulusStruct';
Exp.stimulus = stimulusStruct;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%% FILTER & SPIKE DETECTION %%%%%%%%%%%%%%%%%%%%%%%%%%
% We start by reading in the filter options in state
% Obtain the filter type to be applied
filter = state.filter;

% We will loop through files, triggers and chs to filter and call the
% IIR_filters with options passed from state, call the spikeDetection
% slgorithm and call the spikeEnvelope algorithm
for fileName = 1:size(dataStruct,1)
    for trigger = 1:size(dataStruct,2)
        for filterChIndex = 1:numel(state.filterChs)
            % Perform a switch over the filter types since each filter
            % requires different numbers of input args
            switch filter
                case 'No Filter'
                    % In this case, we only need the signal, filterType and
                    % samplingFrequency
                    FiltSignal = IIR_Filter(...
                        dataStruct(fileName,trigger).(state.chNames{...
                        state.filterChs(filterChIndex)}), state.filter,...
                        samplingFrequency);
                    
                case 'Butterworth'
                    % In this case, we need signal, filter,sampingFrequency
                    % order, type and cutoff freq
                    FiltSignal = IIR_Filter(...
                        dataStruct(fileName,trigger).(state.chNames{...
                        state.filterChs(filterChIndex)}),state.filter,...
                        samplingFrequency, 'order',state.order,'type',...
                        state.type, 'cutOffFreq', state.cutOffFreq);
                   
                case 'Chebyshev_I'
                    % In this case, we need signal, filter, 
                    % samplingFrequencyorder, type and
                    % cutoff freq, pass-band Ripple
                    FiltSignal = IIR_Filter(...
                        dataStruct(fileName,trigger).(state.chNames{...
                        state.filterChs(filterChIndex)}),...
                        state.filter,samplingFrequency, 'order',...
                        state.order,'type', state.type, 'cutOffFreq',...
                        state.cutOffFreq,'passBandRipple',...
                        state.passBandRipple);
                                    
                case 'Elliptic'
                    % In this case, we need signal, filter, 
                    % samplingFrequency order, type, cutoff freq,
                    % pass-band Ripple, stopBand ripple
                    FiltSignal = IIR_Filter(...
                        dataStruct(fileName,trigger).(state.chNames{...
                        state.filterChs(filterChIndex)}),state.filter,...
                        samplingFrequency, 'order',state.order,'type',...
                        state.type,'cutOffFreq', state.cutOffFreq,...
                        'passBandRipple', state.passBandRipple,...
                        'stopBandRipple', state.stopBandRipple);
            end
                                    
            % obtain the spikeIndices by calling spikeDetect.m       
            spikeIndices{fileName,trigger,filterChIndex} = spikeDetect(...
                                   FiltSignal,...
                                   samplingFrequency,state.thresholdType,...
                                   state.threshold, state.maxSpikeWidth,...
                                   state.refractoryPeriod,...
                                   state.triggerRemoval);
                               
            % obtain the spikeSahpes by calling spikeShapes.m
            spikeShapes{fileName,trigger,filterChIndex} = spikeEnvelope(...
                                  FiltSignal,...
                                  Exp.fileInfo(fileName,1).samplingFreq,...
                                  spikeIndices{fileName,trigger,...
                                  filterChIndex}, state.spikeWindow);
            
        end            
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%% PLACE SPIKE INDICES IN EXP STRUCTURE %%%%%%%%%%%%%%%%% 
% Get the names of the chs to be filtered
spikeFieldNames={state.chNames{state.filterChs}};
%construct spike indices struct using the tird dim (i.e. chs as the
%fieldNames)
spikeIndicesStruct(:,:) = cell2struct(spikeIndices,spikeFieldNames,3);
%Add the spikeIndices struct to the Exp struct
Exp.spikeIndices = spikeIndicesStruct;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%% PLACE FILTER OPTIONS IN EXP STRUCTURE %%%%%%%%%%%%%%%%%%%%
% add the filter options that went in to making the spike indices struct
Exp.filterOptions.filterChs = state.filterChs;
Exp.filterOptions.filter = state.filter;

if strcmp(state.filter,'Butterworth')
Exp.filterOptions.order = state.order;
Exp.filterOptions.cutoff = state.cutOffFreq;
end

if strcmp(state.filter,'Chebyshev_I')
    Exp.filterOptions.order = state.order;
    Exp.filterOptions.cutoff = state.cutOffFreq;
    Exp.filterOptions.passBandRipple = state.passBandRipple;
end

if strcmp(state.filter,'Elliptic')
    Exp.filterOptions.order = state.order;
    Exp.filterOptions.cutoff = state.cutOffFreq;
    Exp.filterOptions.passBandRipple = state.passBandRipple;
    Exp.filterOptions.stopBandRipple = state.stopBandRipple;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%% PLACE SPIKE DETECTION OPTIONS IN EXP STRUCTURE %%%%%%%%%%%%%%
% add all the spike detection options that went into detecting the spikes
% in the spike Indices struct
Exp.detectionOptions.detectOnChs = state.detectOnChs;
Exp.detectionOptions.spikeThresholdType = state.thresholdType;
Exp.detectionOptions.spikeThreshold = state.threshold;
Exp.detectionOptions.maxSpikeWidth = state.maxSpikeWidth;
Exp.detectionOptions.refractoryPeriod = state.refractoryPeriod;
Exp.detectionOptions.spikeWindow = state.spikeWindow;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%% PLACE SPIKE SHAPES INTO EXP STRUCTURE %%%%%%%%%%%%%%%%%%%%
spikeShapeFieldNames={state.chNames{state.filterChs}};
%construct spike shapes struct
spikeShapesStruct(:,:) = cell2struct(spikeShapes,spikeShapeFieldNames,3);
%Add the spike shapes struct to the Exp struct
Exp.spikeShapes = spikeShapesStruct;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%% PLACE CELL INFORMATION INTO EXP STRUCTURE %%%%%%%%%%%%%%%%
Exp.cellInformation.cellType = state.cellType;
Exp.cellInformation.cellDepth = state.cellDepth;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%End timer
toc

assignin('base','Exp',Exp)







end

