function varargout = ExpMaker(varargin)
% EXPMAKER M-file for ExpMaker.fig creates an exper structure containing all
% the data files and associated metadata for recording from a single cell.
% It consist of four stages: data selection, filtering, spike detection,
% and results viewing. The gui changes visually as the user progress
% from stage to stage.
%
% Last Modified by GUIDE v2.5 15-Oct-2014 07:42:54
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
%%%%%%%%%%%%%%%%%% INITIALIZATION CODE - DO NOT EDIT %%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ExpMaker_OpeningFcn, ...
                   'gui_OutputFcn',  @ExpMaker_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%% EXECUTES BEFORE EXPMAKER IS VISIBLE %%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ExpMaker_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ExpMaker (see VARARGIN)

% Choose default command line output for ExpMaker
handles.output = hObject;

 dataType = inputdlg('Enter the file type to be loaded (daq or abf):');
 dataType = dataType{1};

%%%%%%%%%%%%%%%%%%%%%%%% LOAD EXPMAKERINITFILE %%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The function ExpMakerInit file contains a structure called state with all
% the initilaization values specific to a given rig needed for the gui to
% start up. To make this gui your own change the expMakerInit file to match
% your rig specific needs. We define state to be global so that it can be
% called outside of the the openingFunction by other functions within this
% gui. The dataType is the kind of file the user will be loading. This
% changes the gui init values.
global state
state = ExpMakerInitFile(dataType);
state.dataType = dataType;

%%%%%%%%%%%%%%%%%%%%%% INITIALIZE HANDLES STRUCT %%%%%%%%%%%%%%%%%%%%%%%%%%
% This gui contains many buttons, tables etc that will appear and disappear
% based on the stage of processing. We initialize those visual parameters
% here.

% The processing stage buttons at the top of the gui need to be
% deactivated. They should do nothing on a user press.
set(handles.dataSelectStage,     'Enable', 'inactive');
set(handles.filteringStage,      'Enable', 'inactive');
set(handles.spikeDetectionStage, 'Enable', 'inactive');
set(handles.resultsStage,        'Enable', 'inactive');

% Set panels and buttons to non-visible that are not part of dataSelection
set(handles.previousStage,         'Visible', 'off');
set(handles.filterOptions,         'Visible', 'Off');
set(handles.spikeDetectionOptions, 'Visible', 'Off');
set(handles.behaviorPanel,         'Visible', 'Off');
set(handles.stimInfoPanel,         'Visible', 'Off');
set(handles.saveExp,               'Visible', 'Off');

% The dataSelect stage and associated button will be highlighted
set(handles.dataSelectStage,     'ForegroundColor', [ 0 0 0])
set(handles.filteringStage,      'ForegroundColor', [ .75 .75 .75])
set(handles.spikeDetectionStage, 'ForegroundColor', [ .75 .75 .75])
set(handles.resultsStage,        'ForegroundColor', [ .75 .75 .75])

%%%%%%%%%%%%%%%%%%%%%%%% SET DATA PROCESSING STAGE %%%%%%%%%%%%%%%%%%%%%%%%
% Define all the tab button options in a cell array
handles.processStages = {'dataSelectStage',...
                  'filteringStage',...
                  'spikeDetectionStage',...
                  'resultsStage'};
handles.processStage = 'dataSelectStage';
              
%%%%%%%%%%%%%%%%%%%%%%%%%%% SET THE CHANNEL NAMES %%%%%%%%%%%%%%%%%%%%%%%%%
set(handles.ChNamesBox,'String', state.chNames);
% Also set the value to the voltage channel
set(handles.ChNamesBox,'Value',state.voltageCh);

%%%%%%%%%%%%%%%% SET SAVE PANEL OPTIONS AND PARAMETERS %%%%%%%%%%%%%%%%%%%%
set(handles.chsToSave,'String', ['[',num2str(state.chsToSave),']'])
set(handles.downSampleCh, 'String', ['[',num2str(state.downSampleChs),']'])
set(handles.downSampleFactors, 'String',...
                                ['[',num2str(state.downSampleFactors),']'])
set(handles.cellType, 'String', state.cellType)
set(handles.cellDepth, 'String', state.cellDepth)
                            
%%%%%%%%%%%%%%%%%%%%%%%%% SET THE FILTER TABLE %%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set the possible filter types
set(handles.filtersListBox,'String',state.allFilters);
% locate the initial filter in state among all filters
filterVal = find(strcmp(state.allFilters,state.filter));
% set the value of the highlighted filter in the list box to be this filter
set(handles.filtersListBox,'Value',filterVal)
%Set the handle to the filterTable object to the new default data table
set(handles.filterTable,'data',state.filterTable);

%%%%%%%%%%%%%%%%%% SET THE SPIKE DETECTION PROPERTIES %%%%%%%%%%%%%%%%%%%%%
set(handles.detectOnChs,'String', ['[',num2str(state.detectOnChs),']'])
set(handles.ThresholdType,'String',state.thresholdTypes)
set(handles.ThresholdType,'Value',state.thresholdTypeValue);
set(handles.thresholdBox,'String', num2str(state.threshold))
set(handles.maxSpikeWidthBox,'String',num2str(state.maxSpikeWidth));
set(handles.refractoryBox,'String', num2str(state.refractoryPeriod))
set(handles.spikeWindowBox,'String', ['[',num2str(state.spikeWindow),']']);
set(handles.triggRmBox,'String',state.triggerRemoval);

%%%%%%%%%%%%%%%%%%%%%%%% SET THE ENCODER OPTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%
set(handles.behaviorCheck,'Value',state.behaviorCheck);
set(handles.dc_offset,'String',num2str(state.encoderOffset))
set(handles.encoderThreshold,'String',num2str(state.encoderThreshold))
set(handles.encoderPercentage,'String',num2str(state.encoderPercentage))

%%%%%%%%%%%%%%%% LOAD DIR INFORMATION AND SAVE TO HANDLES %%%%%%%%%%%%%%%%%
% At the start of the gui the user will load their data files. The
% ExpDirInformation contains the location of these files.
electroExpDirInformation;
handles.DaqFileLoc = [eDirInfo.DaqFileLoc,'.daq']; %Show only daq Files

%%%%%%%%%%%%%%%%%%%%%%%%%%%% ADD FIELDS TO STATE %%%%%%%%%%%%%%%%%%%%%%%%%%
% Place the initial stage of processing in the state structure
state.processStage = 'dataSelectStage';
% We don't initially have filenames until the user presses load so
% initialize them as empty
state.dataFileNames = {};
state.stimFileNames = {};
state.dataFileName = '';
state.stimFileName = '';

% Set the trigger to be one and the initial chToPlot as the voltageCh
state.triggerNumber = 1;
state.channelToPlot = state.voltageCh;
state.channelName = state.chNames{state.channelToPlot};

% Update handles structure
guidata(hObject, handles);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%% NO OUTPUTS TO COMMAND LINE (RESERVED) %%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function varargout = ExpMaker_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%% PROCESSING STAGE CALLBACKS RESERVED %%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% These are 'empty callbacks becasue the tabs at the top of the panel are
% all controlled by the next stage callback. These tabs are inactive.  I
% leave them here in case later functionality is desired i.e. RESERVED

% --- Executes on button press in dataSelectStage.
function dataSelectStage_Callback(hObject, eventdata, handles)
% --- Executes on button press in filteringStage.
function filteringStage_Callback(hObject, eventdata, handles)
% --- Executes on button press in spikeDetectionStage.
function spikeDetectionStage_Callback(hObject, eventdata, handles)
% --- Executes on button press in resultsStage.
function resultsStage_Callback(hObject, eventdata, handles)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%% DATA SELECTION STAGE CALLBACKS %%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%% LOAD BUTTON CALLBACK %%%%%%%%%%%%%%%%%%%%%%%%%%
function loadButton_Callback(hObject, eventdata, handles)
% When the user selects the load button, we will perform the following
% operations
% 1. call uigetfile to select datafiles starting a DaqFileLoc stored in
%    handles
% 2. call the stimDataMatcher to locate the the stimulus files associated
%    with the data files 
% 3. plot the data for the voltage channel

% Declare state variable to be global for this function
global state

% Use the uigetfile function (built-in) to select files and add path
[dataFileNames, PathName] = uigetfile(...
    {'*.daq;*.abf' '*.daq & *.abf';'*.daq' 'DAQ';...
    '*.abf' 'ABF'},'Select a file',handles.DaqFileLoc,...
    'MultiSelect','on');
                                        
% uigetfile will return a string or cell array of strings depending
% on whether the user selected one file or many. We must cast single files
% as cell arrays so that they display properly in the dataListBox
if isstr(dataFileNames)
    dataFileNames = {dataFileNames};
end

% Determine the fileType (here we assume user will enter all the same type)
fileParts = strsplit(dataFileNames{1},'.');
fileType = fileParts{2};

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

% remove the data files with missing triggers.
dataFileNames(incompleteDataFileIndices) = [];

% Place the data filenames in the dataFilesBox
set(handles.dataFilesBox,'string', dataFileNames);

% Populate the stimFileNames box calling the stimDataMatcher
stimFileNames = stimDataMatcher(dataFileNames, fileType)';

% Place the updated file list in the stimFilesBox
set(handles.stimFilesBox,'string', stimFileNames);

% Now add the dataFileNames and stimFileNames to the state structure
state.dataFileNames = get(handles.dataFilesBox,'String');
state.dataFileLoc = PathName;

% since the user has not yet pressed a file in the data files box set the
% index of the fileNames to be 1
state.dataFileName = state.dataFileNames{1};

state.stimFileNames = get(handles.stimFilesBox,'String');

% since the user has not yet pressed a file in the stim files box set the
% index of the fileNames to be 1
state.stimFileName = state.stimFileNames{1};

% Now call the expMakerPlotter to plot the voltage data
expMakerPlotter(state)

% Update the handles structure to reflect changes
guidata(hObject, handles);


%%%%%%%%%%%%%%%%%%%%%%%%% REMOVE BUTTON CALLBACK %%%%%%%%%%%%%%%%%%%%%%%%%%
function removeButton_Callback(hObject, eventdata, handles)
global state

%To remove a file, we get the current values for data and stim listboxes
index = get(handles.dataFilesBox,'Value');

% Get the cell array of all strings in the data and stim listboxes
currentDataFiles = get(handles.dataFilesBox,'String');
currentStimFiles = get(handles.stimFilesBox,'String');

%remove the specified file
currentDataFiles(index)=[];
currentStimFiles(index)=[];

%Set the "index" of the file in the list box to new index so that the
%listbox does not try to highlight a nonexistent value string pair.
newIndex=1;
set(handles.dataFilesBox, 'Value', newIndex)
set(handles.stimFilesBox, 'Value', newIndex)

% Place the updated file list in the dataFilesBox and stimFilesBox
set(handles.dataFilesBox,'string', currentDataFiles);
set(handles.stimFilesBox,'string', currentStimFiles);

% Finally, update the state structure
% Save the dataFileNames information to our state structure
state.dataFileNames = get(handles.dataFilesBox,'String');
state.dataFileName = state.dataFileNames{newIndex};

% Save the stimFileNames information to our state structure
state.stimFileNames = get(handles.stimFilesBox,'String');
state.stimFileName = state.stimFileNames{newIndex};

% again call the expPlotter to plot the new highlighted files
expMakerPlotter(state)

% Update the handles structure to reflect changes
guidata(hObject, handles);


%%%%%%%%%%%%%%%%%%%%%%%%%%% DATAFILESBOX CALLBACK %%%%%%%%%%%%%%%%%%%%%%%%%
function dataFilesBox_Callback(hObject, eventdata, handles)
global state
global exper
% When the user selects a dataFile from the list box we need to do the
% following operations
% 1. Get the index of the new fileName and sync the stimFileName box
% 2. update the dataFileName and StimFileName in state
% 3. call the expPlotter whcih will take care of whatever processing stage
%    we are at to generate the correct plot
% 4. if the user is at the results stage we will also display the stimInfo

% Get the index of the choice in the dataFilesBox
index = get(handles.dataFilesBox,'Value');
% Set the 'value' of the stimFilesBox to be this index
set(handles.stimFilesBox,'Value', index);

% Now we add the new data and stim fileName to the state structure
state.dataFileName = state.dataFileNames{index};
state.stimFileName = state.stimFileNames{index};

% call the plotter (Note if we are at the results stage we pass in the exper
% structure as well. If not only state is passed for plotting
if strcmp(state.processStage,'resultsStage')
    expMakerPlotter(state,'exper',exper)
else
    expMakerPlotter(state)
end

% if the user is at the results stage we also want to display stimulus info
% to the gui stimulus info panel. We call the function dispStimInfo (see
% gui helper funcs) to display this to the gui
if strcmp(state.processStage,'resultsStage')
    trial = dispStimInfo(exper,state.dataFileNames, state.dataFileName,...
        state.triggerNumber);
    set(handles.stimInfoText,'String', trial)
end
% Update the handles structure to reflect changes
guidata(hObject, handles);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%% STIMFILESBOX CALLBACK %%%%%%%%%%%%%%%%%%%%%%%%%
function stimFilesBox_Callback(hObject, eventdata, handles)
global state
global exper
% When the user selects a stimFile from the list box we need to do the
% following operations
% 1. Get the index of the new fileName and sync the dataFileName box
% 2. update the dataFileName and StimFileName in state
% 3. call the expPlotter whcih will take care of whatever processing stage
%    we are at to generate the correct plot
% 4. if the user is at the results stage we will also display the stimInfo

% Get the index of the choice in the stimFilesBox
index = get(handles.stimFilesBox,'Value');
% Set the 'value' of the dataFilesBox to be this index
set(handles.dataFilesBox,'Value', index);

% Now we add the new data and stim fileName to the state structure
state.dataFileName = state.dataFileNames{index};
state.stimFileName = state.stimFileNames{index};

% call the plotter (Note if we are at the results stage we pass in the
% exper structure as well. If not only state is passed for plotting
if strcmp(state.processStage,'resultsStage')
    expMakerPlotter(state,'exper',exper)
else
    expMakerPlotter(state)
end

 % if the user is at the results stage we also want to display stimulus info
% to the gui stimulus info panel. We call the function dispStimInfo (see
% gui helper funcs) to display this to the gui
if strcmp(state.processStage,'resultsStage')
    trial = dispStimInfo(exper,state.dataFileNames, state.dataFileName,...
        state.triggerNumber);
    set(handles.stimInfoText,'String', trial)
end
 
% Update the handles structure to reflect changes
guidata(hObject, handles);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%% CHANNEL INFO PANEL CALLBACKS %%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%% CHANNEL NAMES CALLBACK %%%%%%%%%%%%%%%%%%%%%%%%%%%
function ChNamesBox_Callback(hObject, eventdata, handles)
global state
global exper
% When the user selects a channel name, we will get the current
% dataFileName, stimFileName, chName, and trigger number from the gui and
% make a plot of the corresponding data

%Get the index of the string in the data ans stimulus files boxes
index = get(handles.ChNamesBox, 'Value');

% update the state structure
state.channelName = state.chNames{index};
state.channelToPlot = index;

% call the plotter (Note if we are at the results stage we pass in the exper
% structure as well. If not, only state is passed for plotting
if strcmp(state.processStage,'resultsStage')
    expMakerPlotter(state,'exper',exper)
else
    expMakerPlotter(state)
end

%update the handles structure of the gui to reflect changes
guidata(hObject, handles);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%% DATA PREVIEW PANEL CALLBACKS %%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%% TRIGGER NUMBER CALLBACK %%%%%%%%%%%%%%%%%%%%%%%%%
function triggerNum_Callback(hObject, eventdata, handles)
% When the user enters a trigger number we want to update the plot by
% getting the current dataFileName, stimFileName, chName, and trigger
% number from the gui and make a plot of the corresponding data

global state
global exper

% Update state structure
state.triggerNumber = str2num(get(handles.triggerNum,'String'));

% call the plotter (Note if we are at the results stage we pass in the exper
% structure as well. If not only state is passed for plotting
if strcmp(state.processStage,'resultsStage')
    expMakerPlotter(state,'exper',exper)
else
    expMakerPlotter(state)
end

% if the user is at the results stage we also want to display stimulus info
% to the gui stimulus info panel. We call the function dispStimInfo (see
% gui helper funcs) to display this to the gui
if strcmp(state.processStage,'resultsStage')
    trial = dispStimInfo(exper,state.dataFileNames, state.dataFileName,...
        state.triggerNumber);
    set(handles.stimInfoText,'String', trial)
end

%update the handles structure of the gui to reflect changes
guidata(hObject, handles);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%% SAVE INFORMATION PANEL CALLBACKS %%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%% CELL TYPE CALLBACK %%%%%%%%%%%%%%%%%%%%%%%%%%
function cellType_Callback(hObject, eventdata, handles)
% We place the cellType into state on change
global state
state.cellType = get(handles.cellType,'string');
%update the handles structure of the gui to reflect changes
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%% CELL DEPTH CALLBACK %%%%%%%%%%%%%%%%%%%%%%%%%%%
function cellDepth_Callback(hObject, eventdata, handles)
% We place the cellDepth into state on change
global state
state.cellDepth = str2num(get(handles.cellDepth,'string'));
%update the handles structure of the gui to reflect changes
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%% CHS TO SAVE CALLBACK %%%%%%%%%%%%%%%%%%%%%%%%
function chsToSave_Callback(hObject, eventdata, handles)
% We get the chsToSave and place in state
global state
state.chsToSave = str2num(get(handles.chsToSave,'string'));
%update the handles structure of the gui to reflect changes
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%% DOWNSAMPLE CHS CALLBACK %%%%%%%%%%%%%%%%%%%%%%%%
function downSampleCh_Callback(hObject, eventdata, handles)
% Get the chsToDownSample and place in state
global state
state.downSampleChs = str2num(get(handles.downSampleCh,'string'));
%update the handles structure of the gui to reflect changes
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%% DOWNSAMPLE FACTORS CALLBACK %%%%%%%%%%%%%%%%%%%%%
function downSampleFactors_Callback(hObject, eventdata, handles)
% Get the downsample factors and place in state
global state
state.downSampleFactors = str2num(get(handles.downSampleFactors,'string'));
%update the handles structure of the gui to reflect changes
guidata(hObject, handles);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%% FILTER PANEL CALLBACKS %%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%% FILTERS LISTBOX LISTBOX CALLBACK %%%%%%%%%%%%%%%%%%%%%%%%
function filtersListBox_Callback(hObject, eventdata, handles)
global state
% We wil change the filter type and call the default table for the specific
% filter chosen

% Get the index of the filter that has been chosen in the listbox
index = get(handles.filtersListBox,'Value');

% Get the cell array of all possible filters in the listbox
filterStrings = get(handles.filtersListBox,'String');

%Get the string of the particular filter chosen and save to state
state.filter = filterStrings{index};

%Call ExpMakerFilterTable to supply a default table for this filter 
table = ExpMakerFilterTable(state.filter,state.dataType);

state.filterTable = table;

%Set the handle to the filterTable object to the new default data table
set(handles.filterTable,'data',table);

% Update the handlles structure to reflect the above change to filter table
guidata(hObject, handles);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes when entered data in editable cell(s) in filterTable.
function filterTable_CellEditCallback(hObject, eventdata, handles)
% User must hit apply filter button for changes to state to take affect no
% callbacks issued when table vals are changed

%%%%%%%%%%%%%%%%%%%%%%% APPLY FILTER CALLBACK %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function applyFilterButton_Callback(hObject, eventdata, handles)
% When the user presses the apply filter button we want to set the table in
% both the handles and state structures to be the current table and then
% call the expMakerPlotter to show the filtered trace

global state
table = state.filterTable;
%%%%%%%%%%%%%%%%%%% SET FILTER PARAMS IN THE STATE STRUCT %%%%%%%%%%%%%%%%%
switch state.filter
    
    case 'No Filter'
        state.filterChs = table{1,2};
        
    case 'Butterworth'
        state.filterChs = table{1,2};
        state.order = table{2,2};
        state.type = table{3,2};
        % Depending on the filter type then we must prepare to take one or
        % two inputs depending on low, high or bandpass options
        if strcmp(state.type, 'bandpass')
            state.cutOffFreq = [table{4,2}, table{4,3}];
        else
            state.cutOffFreq = table{4,2};
        end
    
    case 'Chebyshev_I'
        state.filterChs = table{1,2};
        state.order = table{2,2};
        state.type = table{3,2};
        % Depending on the filter type then we must prepare to take one or
        % two inputs depending on low, high or bandpass options
        if strcmp(state.type, 'bandpass')
            state.cutOffFreq = [table{4,2}, table{4,3}];
        else
            state.cutOffFreq = table{4,2};
        end
        % Chebyshev_I needs the pass band ripple
        if strcmp(state.filter,'Chebyshev_I')
            state.passBandRipple = table{5,2};
        end

    case 'Elliptic'
        state.filterChs = table{1,2};
        state.order = table{2,2};
        state.type = table{3,2};
        % Depending on the filter type then we must prepare to take one or
        % two inputs depending on low, high or bandpass options
        if strcmp(state.type, 'bandpass')
            state.cutOffFreq = [table{4,2}, table{4,3}];
        else
            state.cutOffFreq = table{4,2};
        end
        % Elliptic needs the pass band ripple
        if strcmp(state.filter,'Chebyshev_I')
            state.passBandRipple = table{5,2};
        end
        % Elliptic needs both pass and stop band ripples
        if strcmp(state.filter,'Elliptic')
            state.passBandRipple = table{5,2};
            state.stopBandRipple = table{6,2};
        end
end
assignin('base','state',state)
% now call the expMakerPlotter
expMakerPlotter(state)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%% SPIKE DETECTION PANEL CALLBACKS %%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%% DETECT ON CHS CALLBACK %%%%%%%%%%%%%%%%%%%%%%%%%%
function detectOnChs_Callback(hObject, eventdata, handles)
global state
% Get the channels to detect on and save to state
state.detectOnChannels = str2num(get(handles.detectOnChs));

%update the handles structure of the gui to reflect changes
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%% THRESHOLDTYPE CALLBACK %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Executes on selection change in ThresholdType.
function ThresholdType_Callback(hObject, eventdata, handles)
global state
% Get the type of threshold the user has selected
state.thresholdType = ...
    state.thresholdTypes{get(handles.ThresholdType,'Value')};

%update the handles structure of the gui to reflect changes
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%%%% THRESHOLD BOX CALLBACK %%%%%%%%%%%%%%%%%%%%%%%%
function thresholdBox_Callback(hObject, eventdata, handles)
global state
% obtain the users threshold choice and cell expMaker plotter to display
state.threshold = str2num(get(handles.thresholdBox,'string'));

% call expMakerPlotter to update the plot
expMakerPlotter(state)

%update the handles structure of the gui to reflect changes
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%% MAX SPIKE WIDTH CALLBACK %%%%%%%%%%%%%%%%%%%%%%%%%
function maxSpikeWidthBox_Callback(hObject, eventdata, handles)
global state
% get the max allowable spike width
state.maxSpikeWidth = str2num(get(handles.maxSpikeWidthBox,'string'));
%update the handles structure of the gui to reflect changes
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%% REFRACTORY PERIOD CALLBACK %%%%%%%%%%%%%%%%%%%%%%%
function refractoryBox_Callback(hObject, eventdata, handles)
global state
% get the minimum refractory period
state.refractoryPeriod = str2num(get(handles.refractoryBox,'string'));
%update the handles structure of the gui to reflect changes
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%%%%% SPIKE WINDOW BOX CALLBACK %%%%%%%%%%%%%%%%%%%%%%%
function spikeWindowBox_Callback(hObject, eventdata, handles)
global state
% get the viewing window around each spike
state.spikeWindow = str2num(get(handles.spikeWindowBox,'string'));
%update the handles structure of the gui to reflect changes
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%%%%% REMOVE TRIGGER CALLBACK %%%%%%%%%%%%%%%%%%%%%%%%%%%%
function triggRmBox_Callback(hObject, eventdata, handles)
global state
% get the boolean for trigger removal so that trigger pulse is not counted
% as a spike event
state.triggerRemoval = get(handles.triggRmBox,'string');
% update the gui handles
guidata(hObject,handles);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%% BEHAVIOR PANEL CALLBACKS %%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function behaviorCheck_Callback(hObject, eventdata, handles)
global state
% determine whehter to check for running
state.behaviorCheck = get(handles.behaviorCheck, 'Value');
%update the handles structure of the gui to reflect changes
guidata(hObject, handles);


function dc_offset_Callback(hObject, eventdata, handles)
global state
% get the rig specific encoder offset
state.encoderOffset = str2num(get(handles.dc_offset, 'string'));
%update the handles structure of the gui to reflect changes
guidata(hObject, handles);

function encoderThreshold_Callback(hObject, eventdata, handles)
global state
% get the users selected encoder threshold
state.encoderThreshold = str2num(get(handles.encoderThreshold, 'string'));
%update the handles structure of the gui to reflect changes
guidata(hObject, handles);

function encoderPercentage_Callback(hObject, eventdata, handles)
global state
% get the minimum percentage to count as running during a trial
state.encoderPercentage = str2num(get(handles.encoderPercentage,...
    'string'));
%update the handles structure of the gui to reflect changes
guidata(hObject, handles);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%% NEXT STAGE CALLBACK %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function nextStageButton_Callback(hObject, eventdata, handles)
% When the user presses the next stage button we need to
% 1. Get the current processing stage
% 2. Update the tabbed stage button at the top of the gui
% 3. Depending on the what stage is next plot the appropriate plot
% 4. If we are in the spike Detection stage when the next stage is selected
%    we create an exper structure to be passed to expMakerPlotter

% set global variables
global state
global exper 

%%%%%%%%%%%%%%%%%%%%%%%% GET THE CURRENT STAGE %%%%%%%%%%%%%%%%%%%%%%%%%%%%
currentStage = handles.processStage;

%%%%%%%%%%%%%%%%%%%%%%% CREATE exper ARRAY OF STRUCTS %%%%%%%%%%%%%%%%%%%%%%%
% If the current stage is the spikeDetection stage then we need to
% calculate the exper structure for the resultsStage
if strcmp(currentStage, 'spikeDetectionStage');
    % calculating an exper may take some time so relay what is happening
    % with a message box
    hmsg = msgbox('Performing Detection: Please Wait',...
                    'Operation in progress');
                assignin('base','state',state)
    % Now call electroExpCreate function passing in each of the  variables
    exper = electroExpCreateFunc(state);
    % be sure to close msgBox
    close(hmsg)
end

%%%%%%%%%%%%%%%%%%%% UPDATE TABBED STAGE BUTTON %%%%%%%%%%%%%%%%%%%%%%%%%%%
% get the cell of all stages from the initialization section
allStages = handles.processStages;

% find the current stage in our allStages cell array
stageIndex=find(strcmp(currentStage,allStages));

% set the foreground color of the old stage back to gray
set(handles.(currentStage), 'ForegroundColor', [.75 .75 .75])

% increment the stage in both handles and state
handles.processStage = allStages{stageIndex+1};
state.processStage = allStages{stageIndex+1};
newStage = state.processStage;

%set the foreground color of the new stage
set(handles.(newStage),'ForegroundColor',[0 0 0]);

%%%%%%%%%%%%%%%%%%%% UPDATE THE GUI PANELS AND BUTTONS %%%%%%%%%%%%%%%%%%%%
% Once the user has decided to move on to the next stage then we must
% update the panels and the buttons in the gui.

switch newStage
    case 'filteringStage'
        
        % if new stage is filtering, we hide 'Load' and 'Remove' buttons 
        % and SaveInfo panel (hiding all child objects of the panel)
        set(handles.loadButton,'Visible','Off');
        set(handles.removeButton,'Visible','Off');
        set(handles.saveInfoPanel, 'Visible', 'Off');
        
        % Clear the old plot
        cla;
        % Display new plot
        expMakerPlotter(state)
        
        % Make the previous stage button visible
        set(handles.previousStage, 'Visible', 'On');
        % Make the filtering panel visible
        set(handles.filterOptions, 'Visible', 'On');
        
    case 'spikeDetectionStage'
        
        % if new stage is spikeDetection, we hide the filtering options
        % panel (hiding all child objects within panel) and display the 
        % spikeDetectionOptions panel
        set(handles.filterOptions, 'Visible', 'Off')
        
        % Clear old plot
        cla;
        % Display new plot
        expMakerPlotter(state)
        
        % Make the spike detection panel visible
        set(handles.spikeDetectionOptions, 'Visible', 'On')
        set(handles.behaviorPanel, 'Visible', 'On')
        
    case 'resultsStage'
        
        %if entering the results stage we  hide the spikeDetection Panel,
        %the next stage button and the behavior panel and show the stimInfo
        %panel
        set(handles.spikeDetectionOptions, 'Visible', 'Off');
        set(handles.behaviorPanel, 'Visible', 'Off');
        set(handles.nextStageButton, 'Visible', 'Off');
        set(handles.stimInfoPanel, 'Visible', 'On');
        
        % Clear the current axis
        cla; 
        % Display the new plot with exper paramter option
        expMakerPlotter(state, 'exper', exper)
        
        % set the stimuInfoText
        trial = dispStimInfo(exper,state.dataFileNames,...
                             state.dataFileName,state.triggerNumber);
        set(handles.stimInfoText,'String', trial)
        
        % Set the expSave button to be visible
        set(handles.saveExp, 'Visible', 'On');
end

% update handles struct to reflect changes
guidata(hObject,handles)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%% PREVIOUS STAGE CALLBACK %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function previousStage_Callback(hObject, eventdata, handles)
% When the user selects previous stage we need to:
% 1. get the current stage
% 2. update the tabbed stage button to the previous stage
% 3. Plot the previous stage plot
% 4. If we are in the spike Detection stage when the next stage is selected
%    we need to delete the exper variable

global state

%%%%%%%%%%%%%%%%%%%%%%%% GET THE CURRENT STAGE %%%%%%%%%%%%%%%%%%%%%%%%%%%%
currentStage = handles.processStage;

%%%%%%%%%%%%%%%%%% RESTORE  TO PRIOR STAGE BUTTON %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%% UPDATE TABBED STAGE BUTTON %%%%%%%%%%%%%%%%%%%%%%%%%%%
% get the cell of all stages from the initialization section
allStages = handles.processStages;

% find the current stage in our allStages cell array
stageIndex=find(strcmp(currentStage,allStages));

% set the foreground color of the old stage back to gray
set(handles.(currentStage), 'ForegroundColor', [.75 .75 .75])

% decrement the stage in both handles and state
handles.processStage = allStages{stageIndex-1};
state.processStage = allStages{stageIndex-1};
newStage = state.processStage;

%set the foreground color of the new stage
set(handles.(newStage),'ForegroundColor',[0 0 0]);

%%%%%%%%%%%%%%%%%%%% UPDATE THE GUI PANELS AND BUTTONS %%%%%%%%%%%%%%%%%%%%
% Once the user has decided to move back to the previous stage then we must
% update the panels and the buttons in the gui. We need to know what the
% current tab is to decide what should be hidden from the user. We use a
% switch-case structure to accomplis this
% Get the current tab
switch newStage
    case 'dataSelectStage'
        
        % if the user is moving to the dataSelection we show the 'Load',
        % 'Remove' buttons, Save Info panel (this shows all child objects) 
        set(handles.loadButton,'Visible','On');
        set(handles.removeButton,'Visible','On');
        set(handles.saveInfoPanel, 'Visible', 'On');
        
        % Clear the current plot
        cla
        % Display the new plot
        expMakerPlotter(state)
        
        % we make the previous stage button invisible
        set(handles.previousStage, 'Visible', 'Off');
        set(handles.filterOptions, 'Visible', 'Off');
        
    case 'filteringStage'
        
        % if moving to the filtering stage we hide the spikeDetection
        % behvior panels(hiding all child objects) and display 
        %filterDetectionOptions panel
        set(handles.spikeDetectionOptions, 'Visible', 'Off')
        set(handles.behaviorPanel, 'Visible', 'Off')
        
        % Clear the current plot
        cla;
        % Display new plot
        expMakerPlotter(state)
        
        % Make the filterOptions panel visible
        set(handles.filterOptions, 'Visible', 'On')
        
    case 'spikeDetectionStage'
        % if  moving to the spike detection stage we  make the spike 
        % detection panel, behavior panel, and next stage visible and turn
        % off stimInfo panel
        set(handles.spikeDetectionOptions, 'Visible', 'On')
        set(handles.nextStageButton, 'Visible', 'On');
        set(handles.behaviorPanel, 'Visible', 'On');
        set(handles.stimInfoPanel, 'Visible', 'Off');
        
        % Clear the current axis
        cla;
        % we also must reset the data preview plot back to size(1,1,1)
        subplot(1,1,1)
        
        % Display to plot
        expMakerPlotter(state)
        
        % Set the expSave button to be invisible
        set(handles.saveExp, 'Visible', 'Off');
        
        % Last, we delete the exper variable to avoid overwrite problems as
        % we next stage again
        clear exper
end

% update handles struct to reflect changes
guidata(hObject,handles)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%% SAVE EXPER CALLBACK %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function saveExp_Callback(hObject, eventdata, handles)
global state
global exper
% call expSaverFunc to save the exper as type raw (see expSaverFunc.m in
% fileUtils) Note we do not know if expType is cell-attached or whole-cell
% so we use 'not specified' this could be improved upon by having the user
% enter this into the gui.
%%% CHECK THAT I WORK 10/20/2015
expSaverFunc(state.stimFileNames, '', exper, 'not specified','raw')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%% END OF ALL CALLBACKS %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%__________________________________________________________________________
%__________________________________________________________________________
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%% CREATE FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes during object creation, after setting all properties.
function dataFilesBox_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,...
    'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function stimFilesBox_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,...
        'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function ChNamesBox_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,...
        'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function cellType_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'),...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function cellDepth_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'),...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function chsToSave_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,...
        'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function downSampleCh_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,...
        'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function downSampleFactors_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,...
        'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function triggerNum_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,...
        'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function dataPreviewPlot_CreateFcn(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function filtersListBox_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,...
        'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function thresholdBox_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,...
        'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function maxSpikeWidthBox_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,...
        'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function refractoryBox_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,...
        'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function spikeWindowBox_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,...
        'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function detectOnChs_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,...
        'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function dc_offset_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,...
        'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function encoderThreshold_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,...
        'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function encoderPercentage_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,...
        'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function stimInfoBox_Callback(hObject, eventdata, handles)


% --- Executes during object creation, after setting all properties.
function stimInfoBox_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,...
        'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function triggRmBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to triggRmBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function ThresholdType_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ThresholdType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
