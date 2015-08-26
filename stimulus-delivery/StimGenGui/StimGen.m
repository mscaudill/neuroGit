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
function varargout = StimGen(varargin)
% STIMGEN M-file for StimGen.fig
% StimGen is the control gui for the stimGen package. This package
% currently includes a set of visual stimuli in the folder stimGenStimuli.
% Each stimuli has a corresponding default table that appears in the gui
% when the stimType is changed. In addition to running a stimulus, stimGen
% also calls helper functions that create a stimulus trial structure array
% called trials. Each structure in the array is a trial that is displayed
% to the screen. The trial contains *all* stimulus information and is
% indexed by trial number. Lastly, stimGen triggers a data acquistion PC by
% accessing the parallel port adapter utilizing Matlab's DAQ toolbox.
% 
% Help: TO CREATE AND RUN A STIMULUS
% 1). Make a stand alone stimulus in the StimGenStimuli directory modeled
% after the 'Full-field Drifting Grating'. This stimulus file is heavily
% documented and provides many useful insights into how to program your
% specific stimulus.
% 2). Create a default table in the stimGenDefaultTable file located in
% the stimGenHelperFuncs directory
% 3). Add the Stimulus type to the stimTypeBox of this gui by calling guide
% stimGen and editing the stimTypeBox string (left click and select
% properties)
% 4). Add the stimulus string to the case structure in the run callback
% section of this Gui
%Modified:

% Last Modified by GUIDE v2.5 04-Jun-2012 15:13:38

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%% INITIALIZATION CODE DO NOT EDIT %%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @StimGen_OpeningFcn, ...
                   'gui_OutputFcn',  @StimGen_OutputFcn, ...
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
% Turn off case sensitive match warning
warning('off','MATLAB:dispatcher:InexactCaseMatch')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%% EXECUTES BEFORE STIMGEN GUI IS MADE VISIBLE %%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function StimGen_OpeningFcn(hObject, eventdata, handles, varargin) %#ok<*INUSL>
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to StimGen (see VARARGIN)

% Choose default command line output for StimGen
handles.output = hObject;

% Call the function stimGenInit to initialize the user defined choices in
% the gui
initState = stimGenInit();

% set the user of the rig
set(handles.userBox,'String',initState.user);

%set the default stimulus type
handles.stimType = initState.defaultStimType;

% Set the default stimulus types
set(handles.stimTypeBox,'string', initState.defaultStimTypes);
% locate the default stimulus type among all the types and set the proper
% value of the list
listVal = find(...
        strcmp(initState.defaultStimTypes,initState.defaultStimType));
% now set the value of the stimTypeBox to match the default stimType
set(handles.stimTypeBox,'Value',listVal);

% and set the corresponding default table
set(handles.stimParams,'data',initState.defaultTable);

%set the default tag
set(handles.tagBox,'String',initState.tag)

%set the default save state
set(handles.saveTrials,'Value',1)
handles.saveTrialsState = get(handles.saveTrials, 'Value');

% Update handles structure
guidata(hObject, handles);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%% EXECUTES ON SELECTION CHANGE IN STIMTYPEBOX. %%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function stimTypeBox_Callback(hObject, eventdata, handles) %#ok<*DEFNU>
% When the user selects a new stimulus, we want to update the stimParams 
%object with new fields and default values that are pertinent for the 
%particular stimulus type chosen. These defaults are set by the 
%VisGenDefaultTable function

%First Get the index of the stimulus type that has been chosen in the
%listbox
index = get(handles.stimTypeBox,'Value');
% Get the cell array of all strings in the listbox
stimStrings = get(handles.stimTypeBox,'String');
%Get the string of the particular stimulus chosen
handles.stimType = stimStrings{index};
%Call VisGenDefaultTable to supply a default table for this stimulus
table = StimGenDefaultTable(handles.stimType);
%Set the handle to the stimParams object to the new default data table
set(handles.stimParams,'data',table);
% Update the handlles structure to reflect the above change to stimParams
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function stimTypeBox_CreateFcn(hObject, eventdata, handles) %#ok<*INUSD>
% hObject    handle to stimTypeBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,...
                    'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%% EXECUTES WHEN DATA ENTERED IN EDITABLE CELLS IN STIMPARAMS %%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Executes when entered data in editable cell(s) in stimParams.
function stimParams_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to stimParams (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. 
%   Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate 
%   value for Data
%   handles    structure with handles and user data (see GUIDATA)
get(handles.stimParams,'data');
guidata(hObject,handles);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%% EXECUTES ON LOAD BUTTON %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function loadbutton_Callback(hObject, eventdata, handles)
% hObject    handle to loadbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Use the uigetfile function (built-in) to select files and add path
[FileName, PathName] = uigetfile('*.*','MultiSelect','off');
% Load the selected file
load(fullfile(PathName,FileName))
% Set the stimParams table array to the new table and the index of the
% stimTypeBox to the values stored in the previously saved state structure
set(handles.stimParams,'data', state.table);
set(handles.stimTypeBox, 'Value', state.stimTypeIndex);
% Update the handles structure to reflect changes
guidata(hObject, handles);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%% EXECUTES ON SAVE BUTTON PRESS %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function savebutton_Callback(hObject, eventdata, handles)
% hObject    handle to savebutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Use uiputfile to open a dialog box to determine user selected file
% location and name
[FileName,PathName] = uiputfile('*.mat', 'SAVE FILE AS');
if any(FileName)
    % Construct a fullfile path
    filename=fullfile(PathName,FileName);
    % Get the current stimParams table and the value of the index of
    % stimTypeBox. Stores these to a state structure
    state.table = get(handles.stimParams,'data');
    state.stimTypeIndex = get(handles.stimTypeBox,'Value');
    % Save the structure to the filename entered
    save(filename,'state')
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%% EXECUTES ON CHANGE IN USERBOX BOX %%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function userBox_Callback(hObject, eventdata, handles)
% hObject    handle to userBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of userBox as text
%str2double(get(hObject,'String')) returns contents of userBox as a double
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function userBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to userBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'),...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%% EXECUTES ON CHANGE IN TAGBOX BOX %%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function tagBox_Callback(hObject, eventdata, handles)
% hObject    handle to tagBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of tagBox as text
%        str2double(get(hObject,'String')) retrn conts of tagBox as double
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function tagBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tagBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,...
            'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%% EXECUTES ON SAVETRIALS BUTTON PRESS %%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The user will select whether they would like to save the trials stucture
% or not. Note, initialized in opening function to save by default
function saveTrials_Callback(hObject, eventdata, handles)
% hObject    handle to saveTrials (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of saveTrials
handles.saveTrialsState = get(handles.saveTrials, 'Value');
if handles.saveTrialsState == 1;
    set(handles.saveTrials, 'BackgroundColor', 'blue')
    set(handles.saveTrials, 'ForegroundColor', 'white')
    set(handles.saveTrials, 'String', 'Saving Trials')
else
    set(handles.saveTrials, 'String', 'NOT Saving Trials')
    set(handles.saveTrials, 'ForegroundColor', 'black')
    set(handles.saveTrials, 'BackgroundColor', [.941 .941 .941])
end
% update the handles structure
guidata(hObject,handles);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%% EXECUTES ON RUN BUTTON PRESS %%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function runstim_Callback(hObject, eventdata, handles)
% hObject    handle to runstim (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% When the run button is pressed we collect the stimType, stimParams, user,
% and tag. From these we make a trial struct array (trialStruct func). We
% attempt to save the trials to the data directory specified by 
% dirInformation.m. If a file by that name exist we prompt the user if 
% overwrite is ok. Lastly we run the stimulus.

% Get the current stimulus type
stimType = handles.stimType;
%Get the stimParams table
table = get(handles.stimParams,'data');
% Get the current user string
user=get(handles.userBox,'String');
% Get the current tag string
tag=get(handles.tagBox,'String');
% Get the saveTrialsState
saveTrialsState = handles.saveTrialsState;

%%%%%%%%%%%%%%%%%%%%%%%%%% MOUSE CONTROLLED STIMULUS %%%%%%%%%%%%%%%%%%%%%%
% We first need to determine whether the stimulus type is a mouse control
% stimulus. If it is then we don't create a trial structure we just call
% the appropriate stimulus function and pass in the gui table directly
% since the parameters will not be saved
if strfind(stimType, 'Mouse Control')
    switch stimType
        case 'Mouse Controlled Dot'
            MouseControlledDot(table);
        case 'Mouse Controlled Grating'
            MouseControlledGrating(table);
    end
    
%%%%%%%%%%%%%%%%%%%%%%%%%% DAQ TRIGGERED STIMULUS %%%%%%%%%%%%%%%%%%%%%%%%%
else % We have a triggered stimulus and need to save the trials structure
    % We check whether the stimlulus is a single angle CS because this
    % special stiimulus requires a different trials constructor named
    % singleAngleCSTrialsStruct
    if ~strcmp(stimType, 'Single Angle CS')
     % Construct the trials struct to be passed to the stimuli after saving
        trials=trialStruct(stimType,table);
    else
        trials = singleAngleCSTrialsStruct(stimType, table);
    end
    
    % assign it to the base workspace for saving
    assignin('base','trials',trials);
    
    if saveTrialsState == 1; % Check if user wants to save trialsStruct
        % save trialStruct with current time in filename(see 
        % trialStructSave.m)
        trialStructSave(trials, user, tag);
    end

    switch stimType
        case 'Full-field Flash'
            FullFieldFlash(trials);
        case 'Radially Moving Bar'
            RadiallyMovingBar(trials);
        case 'Full-field Drifting Grating'
            FullFieldGrating(trials);
        case 'Masked Grating'
            MaskedGrating(trials);
        case 'Simple Center-surround Grating'
            SimpleCenterSurround(trials)
        case 'Gridded Grating'
            GriddedGrating(trials)
        case 'Gauss Simple Center-surround Grating'
            GaussSimpleCenterSurround(trials)
        case 'Single Angle CS'
            SingleAngleCS(trials)
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



% --- Outputs from this function are returned to the command line.
function varargout = StimGen_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
