function  expMakerPlotter( state, varargin )
% expMakerPlotter takes the gui state of the ExpMaker gui and generates a
% plot that is specific to the stage of processing in the gui.
% INPUTS:       State structure passed from gui containing
% Varagin:      parameter value pairs for exp and plotDownSampleFactor
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%copyright (c) 2012  Matthew Caudill
%
%this program is free software: you can redistribute it and/or modify
%it under the terms of the gnu general public license as published by
%the free software foundation, either version 3 of the license, or
%at your option) any later version.

%this program is distributed in the hope that it will be useful,
%but without any warranty; without even the implied warranty of
%merchantability or fitness for a particular purpose.  see the
%gnu general public license for more details.

%you should have received a copy of the gnu general public license
%along with this program.  if not, see <http://www.gnu.org/licenses/>.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%% BUILD INPUT PARSER %%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The input parser will allow us to pass in state and optionally the
% downsaple factor and exp structure. We do this since exp may or may not
% exist in the gui prior to this plotter being called

% Construct parser object
p = inputParser;

% add the required state structure and validate
addRequired(p,'state',@isstruct);

% Add parameters to the input parser object starting with exp and validate
% set default value to be [];
addParamValue(p,'exper',[],@isstruct);

% Add the default downsample factor and parameter value with numeric valid.
defaultDsFactor = 1;
addParamValue(p,'plotDownSampleFactor',defaultDsFactor,@isnumeric);

% now call the parser
parse(p, state, varargin{:})

% get arguments from the parser 
state = p.Results.state;
plotDownSampleFactor = p.Results.plotDownSampleFactor;
exper = p.Results.exper;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%% DIRECTORY INFORMATION %%%%%%%%%%%%%%%%%%%%%%%%%%%
% The state variable passed from the gui only contains the file names of
% the data to be displayed **not** the actual data. So we must tell
% expPlotter where it can find the data and stimulus files
electroExpDirInformation
daqFileLoc = state.dataFileLoc;
stimFileLoc = eDirInfo.StimFileLoc;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%% GET DAQ INFORMATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We start be getting a little information about the daq or abf file. we
% specifically need the samplesPerTrigg and the samplingRate of the data in
% the file. These values are used to construct a time vector to plot our
% data pts against. We can access this information by using the daqread
% function with the optional 'info' argument or the abf load with the info
% option. Note this does not open the data file so is therefore fast. Info
% is an object returned from the daqread/abfloader function so we access
% information in it with structural indexing
switch state.dataType
    case 'daq'
        Info = daqread([daqFileLoc,state.dataFileName], 'info');
        samplesPerTrigg = Info.ObjInfo.SamplesPerTrigger;
        sampleRate = Info.ObjInfo.SampleRate;
    case 'abf'
        [~,~,Info] = abfload([daqFileLoc,state.dataFileName], 'info');
        samplesPerTrigg = Info.sweepLengthInPts;
        sampleRate = 1/(Info.si*10^-6);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%% CONSTRUCT TIME ARRAY %%%%%%%%%%%%%%%%%%%%%%%%%%
% We will need to plot our data against time not samples so we convert our
% samples into time
time = 1/sampleRate:1/sampleRate:samplesPerTrigg/sampleRate;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%% READ IN DATA FILE & DOWNSAMPLE FOR PLOT %%%%%%%%%%%%%%%%%%%%
% We are now ready to read in the data filename and load the file. Note we
% are only loading the channel and trigger specified in the gui state
% structure because we only display one at a time in the gui. This will
% allow the plot to update rapidly
switch state.dataType
    case 'daq'
        [data] = daqread([daqFileLoc,state.dataFileName], 'Channels',...
                                 state.channelToPlot, 'Triggers',...
                                 state.triggerNumber);
    case 'abf'
        [data,~,~] = abfload([daqFileLoc,state.dataFileName]);
        data = data(:,state.channelToPlot,state.triggerNumber);
end
% We need to handle voltage channels differently than other chs becasue
% voltage chs need to be zeromeaned. If the channelName does not contain
% voltage then we will simply plot the downsampled data for that channel.
% However if the user has selected a channel with '*Voltage*' anywhere in
% the name we need to zero mean the data in addition to downsampling. We do
% this only for daq acuired data since it is cell attached
if any(strcmp(state.channelName,'voltage')) && ...
                                        ~strcmp(state.filter,'No Filter')
    data = downsample(zeroMean(data),plotDownSampleFactor);
else
    data = downsample(data, plotDownSampleFactor);
end
% we must also downsample the time vector so that the data and time vectors
% are always the same length
downSampledTime = downsample(time,plotDownSampleFactor);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%% LOAD STIMULI AND GET TIMING INFO %%%%%%%%%%%%%%%%%%%%%
% For the data filename specified in state we also want to load the
% corresponding stim filename passed from state. We will use this file to
% access the stimulus timing information so we can plot a shaded region
% behind the data representing when the stimulus was being shown.
load([stimFileLoc,state.stimFileName])
% Get the timing information of the stimulus 
stimTime = trials(1).Timing;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%% DETERMINE GUI PROCESS STAGE AND DISPLAY PLOT %%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%% DATA SELECT STAGE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% In the dataSelectStage of the gui we simply display a plot of the data.
% We call the wrapper function shadedPlot (found in generalTools dir) to
% construct a plot with the stimulus displayed as a background gray
if strcmp(state.processStage,'dataSelectStage') 
        shadedPlot(downSampledTime, data, stimTime);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%% FILTER DATA FOR ALL OTHER STAGES %%%%%%%%%%%%%%%%%%%
% If the user is in any other stage of processing other than
% dataSelectStage then we will display a plot of filtered data if the user
% has selected to plot a voltage channel. 

if ~strcmp(state.processStage,'dataSelectStage') && ...
                             any(strcmp(state.channelName,...
                             {'voltage','Electrode'}))
    % also note that we will filter data before downSampling to avoid any
    % possible artifacts. We use a switch case to call the filters becasue
    % each filter requires a different number of inputs
    switch state.filter
            case 'No Filter'
                filtData = data;
        
            case 'Butterworth'
                filtData = IIR_Filter(data,...
                                    state.filter, sampleRate,'order',...
                                    state.order, 'cutOffFreq',...
                                    state.cutOffFreq, 'type', state.type); 
            case 'Chebyshev_I'
                filtData = IIR_Filter(data,...
                                    state.filter,sampleRate,'order',...
                                    state.order, 'cutOffFreq',...
                                    state.cutOffFreq, 'type',...
                                    state.type, 'passBandRipple',...
                                    state.passBandRipple);            
                
            case 'Elliptic'
                filtData = IIR_Filter(data,...
                                    state.filter,sampleRate,'order',...
                                    state.order, 'cutOffFreq',...
                                    state.cutOffFreq, 'type',...
                                    state.type, 'passBandRipple',...
                                    state.passBandRipple,...
                                    'stopBandRipple',...
                                    state.stopBandRipple);
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%% CALL STAGE SPECIFIC PLOT %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%% FILTERING STAGE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% If the user is in the filtering stage of the gui and they are looking at
% a channel with voltage in the channel name then plot filtered data
% otherwise just display the non-voltage data channel
if strcmp(state.processStage,'filteringStage') &&...
                             any(strcmp(state.channelName,{'voltage',...
                             'Electrode'}))
    shadedPlot(downSampledTime, filtData, stimTime);
    
elseif  strcmp(state.processStage,'filteringStage') &&...
        ~any(strcmp(state.channelName,{'voltage','Electrode'}))   
    shadedPlot(downSampledTime, data, stimTime);
end

%%%%%%%%%%%%%%%%%%%%%%%%% SPIKE DETECTION STAGE %%%%%%%%%%%%%%%%%%%%%%%%%%%
% If the user is in the spike detection stage of the gui and they are
% looking at a channel with voltage in the channel name then plot filtered
% data otherwise just display the unfiltered data
if strcmp(state.processStage,'spikeDetectionStage') &&...
                             any(strcmp(state.channelName,{'voltage','Electrode'}))
    shadedPlot(downSampledTime, filtData, stimTime);
    hold on
    % Depending on the threshold type the threshold will be plotted as
    % either multiples of standard deviation or a fixed value
    switch state.thresholdType
        case 'Standard Dev'
            plot(get(gca,'XLim'),[state.threshold*std(filtData),...
                                    state.threshold*std(filtData) ],'r-')
        case 'Fixed'
            plot(get(gca,'XLim'),[state.threshold,...
                                    state.threshold ],'r-')
    end
    hold off
    
elseif strcmp(state.processStage,'spikeDetectionStage') &&...
        ~any(strcmp(state.channelName,{'voltage','Electrode'}))
    shadedPlot(downSampledTime, data, stimTime);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%% RESULTS STAGE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% In the results panel we want to display spike information etc that is
% only available in the Exp structure that the gui created in the spike
% detection stage. 
% We check to make sure we are at the results stage and that the user wants
% to see the voltage channel (otherwise we will just plot the data of that
% channel and not spikes, waveforms etc)
if strcmp(state.processStage, 'resultsStage') &&...
        any(strcmp(state.channelName,{'voltage','Electrode'}))

    % the substructs in the exp structure are indexed by file number (along
    % row) and trigger number along column. To get the file number we will
    % use strfind to return the index of state.fileName within
    % state.fileNames. The trigger number is stored directly as
    % state.triggerNumber. These two numbers will allow us to index to the
    % correct array within the exp structure for plotting
    fileNumber = find(~cellfun('isempty',...
        strfind(state.dataFileNames, state.dataFileName)));
    triggerNumber = state.triggerNumber;
    
    %%%%%%%% GET SPIKE INFO TO PASS TO EXPMAKERRESULTSPLOTTER %%%%%%%%%%%%%
    switch state.dataType % We switch due to different naming conventions
        case 'daq'
            spikeIndices = exper.spikeIndices(fileNumber,...
                                                triggerNumber).voltage(:);
        case 'abf'
            spikeIndices = exper.spikeIndices(fileNumber,...
                                               triggerNumber).Electrode(:);
    end
    
    %Now convert to spike times in secs
    spikeTimes = spikeIndices/sampleRate;
    
    % get the spike shapes from exp struct
    switch state.dataType % We switch due to different naming conventions
        case 'daq'
            spikeShapes = {exper.spikeShapes(fileNumber,...
                triggerNumber).voltage{:}};
        case 'abf'
            spikeShapes = {exper.spikeShapes(fileNumber,...
                triggerNumber).Electrode{:}};
    end
    
    %Calculate mean and std(spike)shapes
    meanSpikeShape = mean(cell2mat(spikeShapes),2);
    stdevSpikeShape = std(cell2mat(spikeShapes),0,2);
    
    % Finally call the results plotter to display all the spike info
expMakerResultsPlotter(downSampledTime, filtData, stimTime,...
                                state.threshold,state.filter,...
                                spikeTimes, spikeShapes,...
                                meanSpikeShape, stdevSpikeShape)
                            
elseif strcmp(state.processStage, 'resultsStage')
    % We will resize the plot and just plot the data of the non-voltage
    % channel
    subplot(1,1,1)
    shadedPlot(downSampledTime, data, stimTime);
end


