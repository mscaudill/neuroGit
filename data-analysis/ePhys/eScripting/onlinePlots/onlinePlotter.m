function onlinePlotter(expType,stimVariable, varargin)
%onlinePlotter takes a set of data files and autolocates associated
%stimFiles, makes an experiment using scripted defaults and constructs a
%plot of responses.
% INPUTS:           expType: either ca (cell-attached) or wc (whole-cell)
%       VARARGIN
%                   fileType: type of data file acquired (abf/daq). If not
%                             selected defaults to abf type
%                   removeSpikes: logical as to wheter to remove spikes
%                             from wc data
%                   spikeThreshold: fixed spike threshold value, defaults
%                             to -40 mV
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
%%%%%%%%%%%%%%%%%%%%%%%%% BUILD AN INPUT PARSER %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We will now build an input parser to allow the user to pass variable
% arguments to this function.

% construct an object from the parser class
p = inputParser;

addRequired(p,'expType',@isstr)

%%%%%%%%%%%%%%%%%%%%% Add fileType input to parser %%%%%%%%%%%%%%%%%%%%%%%%
% Define the possible fileTypes this function can handle
allFileTypes = {'daq','abf'};
% define the default fileType
defaultFileType = 'abf';
% add the fileType to the parser checking that fileType matches one of
% allFileTypes
addParamValue(p,'fileType',defaultFileType,...
    @(types) all(ismember(type,allFileTypes)));


%%%%%%%%%%%%%%%%%%%%%% Add the remove spikes logical %%%%%%%%%%%%%%%%%%%%%%
defaultRemoveSpikes = true;
addParamValue(p,'removeSpikes',defaultRemoveSpikes,@islogical);

%%%%%%%%%%%%%%%%%%% Add the spike threshold to the parser %%%%%%%%%%%%%%%%%
defaultSpikeThresh = -40;
addParamValue(p, 'spikeThreshold', defaultSpikeThresh, @isnumeric)

% call the method parse on the parser to add parameters to parse object p %
parse(p, expType, varargin{:})

%%%%%%%%%%%%%%%%%%%% Retrieve varargin from parse object p %%%%%%%%%%%%%%%%
fileType = p.Results.fileType;
removeSpikes = p.Results.removeSpikes;
spikeThreshold = p.Results.spikeThreshold;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%% CALL EXPMAKER INIT FUNC TO INSTATIATE STATE VARIABLE %%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We will now call ExpMakerInit file which makes a state variable with all
% the options present in the ExpMaker gui such as spike detection options
% etc.
state = ExpMakerInitFile(fileType);
% We now need to overwrite the states default values for spikeThreshold
state.threshold = spikeThreshold;
state.dataType = fileType;

%also overwrite the filter options if the user selected ca data. We
%will only support a 5th order butterworth of type high pass at 300hz
%cutoff for now becasue these options work well on all cell-attached data.
%If the user wishes to select other options they must make the exp using
%the gui and select from there and call the appropraite plotters. This is a
%fast script to be run during an experiment thus bypassing the gui.
if strcmp(expType,'ca')
    state.thresholdType = 'Standard Dev';
    state.threshold = 10;
    state.filter = 'Butterworth';
	state.filterTable = ExpMakerFilterTable(state.filter, fileType);
    state.filterChs = state.filterTable{1,2};
    state.order = state.filterTable{2,2};
    state.type = state.filterTable{3,2};
    state.cutOffFreq = state.filterTable{4,2};
end
% If the expType is wc then the init file defaults to no filter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%% UIGETFILE THE DATA FILES TO PLOT %%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Use the uigetfile function (built-in) to select files and add path
[dataFileNames, PathName] = uigetfile(...
    {'*.daq;*.abf' '*.daq & *.abf';'*.daq' 'DAQ';...
    '*.abf' 'ABF'},'Select a file',state.startFileLoc,...
    'MultiSelect','on');

% call the function checkNumTriggs to identify dataFiles with missing
% triggers
[incompleteDataFileNames, incompleteDataFileIndices] = checkNumTriggs(...
                            PathName, dataFileNames,fileType);
% Display to the user the fileNames with missing triggers and get
% confirmation before proceeding
if ~isempty(incompleteDataFileIndices)
    waitfor(msgbox(['The following dataFiles are missing',...
                        'triggers and will be discarded: ',char(10),...
                        incompleteDataFileNames]));
end

% remove the data file names with missing triggers.
dataFileNames(incompleteDataFileIndices) = [];

% Obtain the stimFileNames calling the stimDataMatcher
stimFileNames = stimDataMatcher(dataFileNames, fileType)';

% save the dataFileNames and stimFileNames to state
state.dataFileLoc = PathName;
state.dataFileNames = dataFileNames;
state.stimFileNames = stimFileNames;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%% CREATE THE EXP STRUCTURE AND CALL ONEDIMEPHYSPLOTTER %%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create Exp Structure
Exp = electroExpCreateFunc(state);

if strcmp(expType,'ca')
    oneDimFiringRatePlot(Exp)
end

if strcmp(expType,'wc')
    % call oneDimEphysPlotter
    oneDimEPhysPlotter(Exp,stimVariable,'removeSpikes',removeSpikes)
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

end

