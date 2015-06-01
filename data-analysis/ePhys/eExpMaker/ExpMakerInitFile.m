function state = ExpMakerInitFile(dataType)
% This is an initialization file for the ExpMakerGui. It defines
% initialization values for the state structure that is used within the gui
% but are specific to each rig.
% INPUTS:       dataType: The fileType that will be loaded; supports daq
%                         and abf files
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

%%%%%%%%%%%%%%%%%%%%%%% SET THE FILE LOC %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
state.startFileLoc = 'A:\MSC\Data\CSproject\rawData\';

%%%%%%%%%%%%%%%%%%%%%%% ASSIGN THE CELL TYPE AS UNKOWN %%%%%%%%%%%%%%%%%%%%
state.cellType = '?';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%% ASSIGN THE CELL DEPTH AS NaN %%%%%%%%%%%%%%%%%%%%%%
state.cellDepth = 'NaN';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

switch dataType
    case 'daq'
        %%%%%%%%%%%%%%% DEFINE THE CHANNELS COLLECTED %%%%%%%%%%%%%%%%%%%%%
        state.chNames = {'trigger','voltage','photodiode','field',...
                         'encoder'};
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %%%%%%%%%%%%%%%%%%%%%% DEFINE THE VOLTAGE CHANNEL %%%%%%%%%%%%%%%%%
        % Currently, we only support one voltage channel
        state.voltageCh = 2;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%% DEFINE THE CHS TO SAVE %%%%%%%%%%%%%%%
        state.chsToSave = [2]; % i.e. the voltage ch
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %%%%%%%%%%%%%%%%%%%%%%%%%% DEFINE THE CHS TO DOWNSAMPLE %%%%%%%%%%%
        state.downSampleChs = [5]; % Down sample the enocder ch. by 10x
        state.downSampleFactors = [10];
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
    case 'abf'
        %%%%%%%%%%%%%%% DEFINE THE CHANNELS COLLECTED %%%%%%%%%%%%%%%%%%%%%
        state.chNames = {'Electrode','Stimulus','Encoder','Photodiode'};
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %%%%%%%%%%%%%%%%%%%%%% DEFINE THE VOLTAGE CHANNEL %%%%%%%%%%%%%%%%%
        % Currently, we only support one voltage channel
        state.voltageCh = 1;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%% DEFINE THE CHS TO SAVE %%%%%%%%%%%%%%%
        state.chsToSave = [1]; % i.e. the voltage ch
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %%%%%%%%%%%%%%%%%%%%%%%%%% DEFINE THE CHS TO DOWNSAMPLE %%%%%%%%%%%
        state.downSampleChs = [3]; % Down sample the enocder ch. by 10x
        state.downSampleFactors = [10];
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%     
end

%%%%%%%%%%%%%%%%%%%%%%%%%% DEFINE THE INITIAL FILTERING %%%%%%%%%%%%%%%%%%%
state.allFilters = {'No Filter', 'Butterworth', 'Chebyshev_I', 'Elliptic'};
state.filter = state.allFilters{1};
state.filterTable = ExpMakerFilterTable(state.filter, dataType);
state.filterChs = state.filterTable{1,2};
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%% DEFINE THE SPIKE DETECTION PARAMS %%%%%%%%%%%%%%%%%%%
switch dataType
    case 'daq'
        state.detectOnChs = [2];
        state.triggerRemoval = 'true';
    case 'abf'
        state.detectOnChs = [1];
        state.triggerRemoval = 'false';
end
state.threshold = -40;
state.thresholdTypes = {'Standard Dev', 'Fixed'};
state.thresholdTypeValue = 2;
state.thresholdType = state.thresholdTypes{state.thresholdTypeValue};
state.maxSpikeWidth = 2;
state.refractoryPeriod = 10;
state.spikeWindow = [2,2];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%% DEFINE THE ENCODER PARAMS %%%%%%%%%%%%%%%%%%%%
state.behaviorCheck = 0; %i.e. check for running
switch dataType
    case 'daq'
        state.encoderOffset = 6.6; % dc offset of the encoder
    case 'abf'
        state.encoderOffset = 0;
end
state.encoderThreshold = 0.5;
state.encoderPercentage = 75;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%





