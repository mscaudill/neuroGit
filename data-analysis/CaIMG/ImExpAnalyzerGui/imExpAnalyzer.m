function varargout = imExpAnalyzer(varargin)
% IMEXPANALYZER M-file for imExpAnalyzer.fig
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
% imExpAnalyzer loads an imExp saved by the imExpMaker gui. The imExp
% structure contains all stimulus and corrected images for a single cell.
% This gui opens that experiment and calculates the fluorescence of user
% selected regions of interest. It saves the ROIs and the fluorescent
% signals to the imExpStructure.
%
% Last Modified by GUIDE v2.5 06-Jun-2016 15:41:40

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @imExpAnalyzer_OpeningFcn, ...
                   'gui_OutputFcn',  @imExpAnalyzer_OutputFcn, ...
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
% End initialization code - DO NOT EDIT


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%% EXECUTES BEFORE EXPMAKER IS VISIBLE %%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function imExpAnalyzer_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to imExpAnalyzer (see VARARGIN)

% Choose default command line output for imExpAnalyzer
handles.output = hObject;

%%%%%%%%%%%%%%%%%%%%%%% INITIALIZE GUI STATE STRUCTURE %%%%%%%%%%%%%%%%%%%%
% We will call the function imExpInitFile which initializes a state
% strucuture that holds the user selected options for starting the gui.
% Within the gui, we will also add other values to this structure that the
% user can not directly influence from the initialization file. For example
% the current frame number. This structure will hold values from the gui to
% be passed into subfunctions that are called in this gui. It will also
% allow us to save the exact state of the gui without reference to the
% handles structure. This is nice because the handles structure contains
% way more information than we need (eg. handle to the plots or uipanels
% etc...).

% Define the state as a global variable so that it can be shared between
% functions that also declare 'state' to be global
global state

state = imExpInitFile();

% To the state strucutre we will add the following parameters that are
% internal to the gui (i.e. the user can not manipulate them from the
% iniitalization file.

% Here we will initialize  the state variables that will be used
% throughout the gui. When the gui is first opened all list are initialized
% as empty.
state.imExpName = '';
state.stimFileName = '';
% This cell will hald all the stimulus set names associated with our imExp
state.stimFileNames = {};
state.imagePath = '';
% The image stack name associated with a particular stimulus file, trigger 
% number and ch to display will be stored to state.imageStackName
state.imageStackName = '';
% the stack extrema contains the min/max pairs for the image stack to be
% used in plotting to ensure the image is scaled visible to the user
state.stackExtrema = {};

state.trigNumber = 1;
state.frameNumber = 1;

%%%%%%%%%%%%% FILL IN GUI OPTIONS BEFORE GUI IS VISIBLE %%%%%%%%%%%%%%%%%%%
% We are now ready to set all of the optional values in the gui. For
% example if the user specified in the init file to draw Rois freehand then
% we initialize the box to be freehand.

set(handles.chToDisplayBox, 'String', num2str(state.chToDisplay));

set(handles.scaleFactorBox, 'String', num2str(state.scaleFactor));

% Draw Method
% The draw Methods have been set in guide so we extract those methods and
% check to see if the user selected method is one of them
allMethods = cellstr(get(handles.drawMethodBox,'String'));
% locate the users init file choice in all methods (if exist)
index = find(ismember(allMethods,state.drawMethod));
% If the user has selected an invalid drawMethod we will default to
% freehand
if ~isempty(index)
    set(handles.drawMethodBox,'Value',index)
else
    disp(['Invalid Draw Method in initFile,', char(10),...
                    'defaulting drawMethod to Free Hand']);
    % locate free hand index and set the drawMethod box to this value            
    index = find(ismember(allMethods,'Free Hand'));
    set(handles.drawMethodBox,'Value',index)
    % overwrite users invalid choice
    state.drawMethod = 'Free Hand';
end


set(handles.editCellType,'String',state.initCellType);

%Stimulus Variable
% The stimVariables have been set in guide so we extract those variables
% from the handles structure and check that the user selected variable is
% valid
allVariables = cellstr(get(handles.stimVariableMenu,'String'));
% locate the users init file choice of stimVariable in all variables
% (if exist)
index = find(ismember(allVariables,state.stimVariable));

% if the user has selected a valid choice
if ~isempty(index)
    set(handles.stimVariableMenu, 'Value', index)
else
    disp(['Invalid stimVariable in initFile', char(10),...
            'defaulting to Orientation']);
        % locate the orientation index in the stimVariable menu
        index = find(ismember(allVariables, 'Orientation'));
        set(handles.stimVariableMenu,'Value',index);
        
        % overwrite users invalid choice
        state.stimVariable = 'Orientation';
end
    
set(handles.runStateBox, 'String', num2str(state.runState));

set(handles.neuropilFactor,'String', num2str(state.neuropilRatio));

set(handles.LedChkBox,'Value',state.Led{1})

set(handles.ledTrialsBox,'String', state.Led{2});

set(handles.noLedBaselineFrames, 'String',...
    num2str(state.noLedBaseline))

set(handles.ledBaselineFrames, 'String',...
    num2str(state.ledBaseline))

set(handles.notesBox,'String', state.notes);

% Update handles structure
guidata(hObject, handles);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%% RETURN HANDLES STRUCTURE OUTPUT ARGS (GUIDE AUTOCODE) %%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function varargout = imExpAnalyzer_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
%$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
%$$$$$$$$$$$$$$$$$$$$$$ BEGIN CALLBACKS $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
%$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
%$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%% LOAD BUTTON CALLBACK %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Executes on button press in loadButton.
function loadButton_Callback(hObject, eventdata, handles)
% Declare state and imExp to be global to this function and all functions
global state
global imExp

% When the presses the load button we:
% 1-Obtain and Load an imExp. Note imExp may already have been analyzed 
%   (i.e. rois have already been drawn) so we need to potentially populate 
%   listboxes and roi cell arrays 
% 2-Display stimulus information and timing for the first stimulus in the
%   imExp
% 3-Display images and set slider controls
% 4-Populate roiNamesBoxes and cellTypes boxes

%%%%%%%%%%%%%%%%%%%%%%%% OBTAIN IMEXP NAME AND LOCATION %%%%%%%%%%%%%%%%%%%
% Call uigetfile (built-in) to select the imExp and get path to file
[imExpName, PathName] = uigetfile(state.imExpRawFileLoc,...
                                            'MultiSelect','off');
% Update state imExp name
state.imExpName = imExpName;
% set the string of the imExpBox to be state.imExpName
set(handles.imExpBox, 'string', state.imExpName);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%% LOAD IMEXP %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Now perform the loading and open a dialog box to relay to user whats
% happening
loadMsg = msgbox('LOADING IMEXP: Please Wait...');

% now load the imExp using full-file to construct path\fileName
imExp = load(fullfile(PathName,imExpName));

close(loadMsg)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%% POPULATE STIMULUS/IMAGE FILENAME LISTBOXES %%%%%%%%%%%%%%%
% now collect all the stimulus fileNames that are present in the imExp
state.stimFileNames = {imExp.fileInfo(:,:).stimFileName};

% get the first stimulus filename and save to state
state.stimFileName = state.stimFileNames{1};

% place the stimFileNames in the stimFileNames box
set(handles.stimFileNamesBox,'string', state.stimFileNames);

% obtain the image stack name for the first trigger of the first stimulus
state.imageStackName = imExp.fileInfo(1,1).imageFileNames{1};

% place the imageFileName in the imageStackName
set(handles.imStackNameBox,'string',state.imageStackName);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%% DISPLAY STIMULUS INFO %%%%%%%%%%%%%%%%%%%%%%%%%%%%
% call dispStimInfo to display stimulus text info. The stimInfo is also
% saved to the imExp but we will reuse the dispStimInfo function which
% requires a fileName and trigger number
stimInfoStr = dispImStimInfo(state.stimFileName, state.trigNumber);
% display the string to the stimInfoBox
set(handles.stimInfoBox,'string', stimInfoStr);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%% DISPLAY STIMULUS TIMING %%%%%%%%%%%%%%%%%%%%%%%%%%
% call dispStimTiming to display a plot of the stimulus and frame timing
% get the sstimulus axis
stimAxes = handles.stimDisplay;
%call stimImage matcher to match stimFileNames to imags and return
%imagePath
[~, ~, state.imagePath] = stimImageMatcher({state.stimFileName});

% call dispStimTiming to show the time course of the stimulus
dispStimTiming(state.stimFileName, state.imageStackName,...
                state.frameNumber,state.imagePath, stimAxes);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
%%%%%%%%%%%%%%%%%%%%%%%%% DISPLAY TIFF IMAGES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%            
% call dispTiff to display the first image. We need an axes to plot to, the
% imageStack, the stack extrema and the image number = 1;
imageAxes = handles.imageData;

% We need to gracefully handle the case in which the user has selected to
% display a channel in the init file that is not in the loaded imExp. To do
% this we will check the channels in the loaded imExp against the init file
% requested channel. If there is a mismatch then we will load the first
% channel in the imExp that was loaded so analysis can proceed.

% Check whether the channel requested in the init file to be displayed in
% the one in the imExp

% use structfun to locate the non-empty channels in the imExp
 chsInImExp = find(~structfun(@isempty, imExp.stackExtremas(1,1)));
 % cross check against the user selected channels using intersect
 commonChs = intersect(state.chToDisplay, chsInImExp);
 
 % if the intersection is empty we need to set the channel to a valid
 % channel and let the user know what is happening with a message
 if isempty(commonChs)
     hTiffMsg =  msgbox(['The init file chToDisplay is not in this imExp,',...
                        char(10),'Setting the chToDisplay as channel ',...
                        num2str(chsInImExp(1))]);
    state.chToDisplay = chsInImExp(1);
    
    % get the stack associated with the first stimulus and first trigger.
     state.imageStack = ...
         imExp.correctedStacks(1,1).(['Ch',num2str(state.chToDisplay)]);
     % get the stack Extrema associated with the first stimulus and trigger
     state.stackExtrema =...
         imExp.stackExtremas(1,1).(['Ch',num2str(state.chToDisplay)]);
     % make call to DispTiff
     dispTiff(imageAxes, state.imageStack, state.stackExtrema,...
         state.frameNumber, state.scaleFactor);
     % Don't forget we need to update the channel number in the chToDisplay
     % box
     set(handles.chToDisplayBox,'String',num2str(state.chToDisplay));
     
 % if the channel the user requested is in the loaded imExp then we are
 % cleared to proceed with loading the tiff images for that channel
 else
     % get the stack associated with the first stimulus and first trigger.
     state.imageStack = ...
         imExp.correctedStacks(1,1).(['Ch',num2str(state.chToDisplay)]);
     % get the stack Extrema associated with the first stimulus and trigger
     state.stackExtrema =...
         imExp.stackExtremas(1,1).(['Ch',num2str(state.chToDisplay)]);
     % make call to DispTiff
     dispTiff(imageAxes, state.imageStack, state.stackExtrema,...
         state.frameNumber, state.scaleFactor);
 end
        
% now set the frame text string
totalNumFrames = num2str(size(state.imageStack,3));
% construct the frame text string
frameText = [num2str(state.frameNumber), '/', totalNumFrames];
% set the frame text handles
set(handles.frameNumStr, 'String', frameText);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%% SLIDER CONTROLS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Now we will set the slider controls for this image stack displayed. We
% will need the slider min, max and step size. These are calculated from
% the size of the image stack
sliderMin = 1;
% The slider max will be the total num of images
sliderMax = size(state.imageStack,3);
% Now we set the major and minor steps of the slider
sliderStep = ([1,1]/(sliderMax-sliderMin));

% update the slider gui controls by setting handles
set(handles.imageSlider,'Min',sliderMin);
set(handles.imageSlider,'Max', sliderMax);
set(handles.imageSlider,'SliderStep', sliderStep);
set(handles.imageSlider, 'Value', sliderMin);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%% GENERATE ROISET/ROINAMES AND POPULATE LISTBOXES %%%%%%%%%%
% Generate a set of roiSet numbers that match the number of stimulus files
% and place these into the roiSet box
% create the base name (i.e. the name preceeding the index number we attach
% below
roiBaseName = {'RoiSet'};
% make the base sets a cell array the same size as the number of stimulus
% files since we will create an roi set for each stimulus file
roiBaseNames = repmat(roiBaseName, 1, numel(state.stimFileNames)+1);
% use genvarname to get an indexed number behind the base name (i.e.
% roiSet3 etc.)
roiBaseSet = genvarname(roiBaseNames);
% the first string is roiSet so remove it since it has no index
roiBaseSet(1)=[];
% set the roiSetList box to the created cell of roiSet strings
set(handles.roiSetListBox, 'String', roiBaseSet);

% Initialize the roiSets cell array which will later hold the roi objects
% creted by imfreehand (see drawRoi and addRoi callbacks below)
state.roiSets = cell(1,numel(state.stimFileNames));

% Now we want to check whether the user is loading an imExp with presaved
% rois and if so, we will load them to state and display them to the
% roiNames box
if ~isempty(strfind(state.imExpName,'ROI'))
    state.roiSets = imExp.rois;
    %Set the index of the roi set to be the first one
    set(handles.roiSetListBox,'Value',1);
    roiSetIndex = get(handles.roiSetListBox,'Value');
    
    % We now are ready to construct the names to appear in the
    % roiNamesListBox. We make these names based on the number of elements
    % of roiSets{roiSetIndex) (i.e. the currently selected set). use repmat
    % and genvarname to construct names such as roi1, roi2,... construct
    % string names for the roi names list box
    numStrings = numel(state.roiSets{roiSetIndex});
    % construct the base of the roi name as a cell string
    roiBaseName = {'Roi'};
    % use repmat to copy the base name numStrings times
    roiBaseNames = repmat(roiBaseName, 1, numStrings+1);
    % use genvarname to add the roi number to the end of the base name
    roiNames = genvarname(roiBaseNames);
    %remove the base name from the set of roi names
    roiNames(1)=[];
    % place these roi names into the roiNamesListBox
    set(handles.roiNamesListBox, 'String', roiNames);
    
    % Check that the first roiSet contains rois if not leave blank
    if numel(state.roiSets{1}) > 1;
        % set state.currentRoi to the first roi for roiSetIndex
        state.currentRoi = state.roiSets{roiSetIndex}{1};
    
        % Now we call roiPlotter to plot the current roi to  image stack
        roiPlotter(state.currentRoi, 'y', imageAxes);
    else
        state.currentRoi = [];
    end
    
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%% POPULATE CELLTYPE NAMES  LISTBOX %%%%%%%%%%%%%%%%%%%%%%
% we will now construct a cell array the size of the stim fileNames that
% will later hold the user inputted cellTypes
state.cellTypes = cell(1,numel(state.stimFileNames));

% Check whether we are loading an imExp with predrawn rois. If so load the
% cell types 
if ~isempty(strfind(state.imExpName,'ROI'))
    if isfield(imExp,'cellTypes') %old imExps may not have cellTypes so chk
        state.cellTypes = imExp.cellTypes;
        if numel(state.roiSets{1}) > 1;
            set(handles.cellTypeListBox, 'String',...
                state.cellTypes{roiSetIndex});
        else 
        set(handles.cellTypeListBox, 'String','');
        end
    else
        set(handles.cellTypeListBox, 'String','');
    end
end

% HAS PROBLEMS IF LOADING AN IMEXP WITHOUT CELL TYPES BUT HAS ROIS FIXME!!
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%% POPULATE NOTES LISTBOX %%%%%%%%%%%%%%%%%%%%%%%%%%
% We will now determine if the loaded imExp already has notes associated
% with it and if true then we will load the notes to the notesBox
if isfield(imExp,'notes')
    state.notes = imExp.notes;
    set(handles.notesBox,'String',state.notes)
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% update the handles structure to reflect these changes in the gui
guidata(hObject,handles);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%% STIMFILENAMES CALLBACK %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function stimFileNamesBox_Callback(hObject, eventdata, handles)
% Declare state and imExp to be global to this function and all functions
global state
global imExp
% When the user selects a new stimulus file we need to:
% 1. Get the stimFileName and its index in the listbox
% 2. Update the trigger number to one
% 3. Update the frameNumber to one
% 4. Update the imageStackNameBox to the name associated with this 
%    stimFileName and trigger one
% 5. Update the stimInfo box with stimulus information assoc. with trig 1
% 6. Update the stimTiming plot with timing associated with trigger 1
% 7. Update the image stack and the image stack extrema to match selected
%    stimFileName
% 8. Update the imageStack imageData to the first image for trigger 1
% 9. Update the frame text string
% 10. Update the slider controls to match min max of the new image stack
% 11. Update the index of the roiSet to match the stimulus file selected
% 12. Clear the roi names box and place names of pre existing rois for the
%     set if they already exist
% 13. If rois exist, then we want to redraw the rois for the selected
%     stimulus set

% obtain the stimFileName and index in the list box
% get the index of the user selected stimulus
index = get(handles.stimFileNamesBox,'Value');
% set the value of the list box to the new index
set(handles.stimFileNamesBox, 'Value',index);
% obtain the stimFileName and update state
state.stimFileName = state.stimFileNames{index};


% update the trigger number
state.trigNumber = 1;
set(handles.triggNumBox,'String',1);

% update the frame number to one
state.frameNumber = 1;


% update the imageStack namebox and state element to match the index of the
% stimfile in the list box and supplying 1 as the trigger
state.imageStackName =...
    imExp.fileInfo(index,1).imageFileNames{state.trigNumber};
% set the imStackNameBox to the new image stack name
set(handles.imStackNameBox,'string',state.imageStackName);


% call dispStimInfo to display stimulus text info for the new stimulus file
% and using trigNumber 1
stimInfoStr = dispImStimInfo(state.stimFileName, state.trigNumber);
% display the string to the stimInfoBox
set(handles.stimInfoBox,'string', stimInfoStr);


% call dispStimTiming to display a plot of the stimulus and frame timing
stimAxes = handles.stimDisplay;
%state.imagePath = imExp.fileInfo(index,1).imagePath;
dispStimTiming(state.stimFileName, state.imageStackName,...
                state.frameNumber,state.imagePath, stimAxes)
       
            
% Get the image and extrema data and call dispTiff for plotting new image
% data associated swith the new stimulus choice
% set the new image stack to the stack associated with the stimFileName
% index choice and trigger number one 
state.imageStack =...
    imExp.correctedStacks(index,state.trigNumber).(['Ch',num2str(...
                                                    state.chToDisplay)]);
% get the stack Extrema associated with this stimulus choice and trigger 1
state.stackExtrema =...
    imExp.stackExtremas(index,1).(['Ch',num2str(state.chToDisplay)]);
% set the axes for plotting just in case
imageAxes = handles.imageData;
% update the imageData by calling to DispTiff
dispTiff(imageAxes, state.imageStack, state.stackExtrema,...
            state.frameNumber, state.scaleFactor);


% now set the frame text string
totalNumFrames = num2str(size(state.imageStack,3));
% construct the frame text string
frameText = [num2str(state.frameNumber), '/', totalNumFrames];
% set the frame text handles
set(handles.frameNumStr, 'String', frameText);

% Now we will set the slider controls for this image stack displayed. We
% will need the slider min, max and step size. These are calculated from
% the size of the image stack
sliderMin = 1;

% Note we can only calculate the slider max if the trigger was not missed,
% otherwise, we must hide the slider to avoid the user clicking it
if ~strcmp(state.imageStackName,'missedTrigger')
    sliderMax = size(state.imageStack,3);
    set(handles.imageSlider,'Visible','on')
else
    sliderMax = 2; % a dummy max has no meaning since we will hide slider
    set(handles.imageSlider,'Visible','off')
end

% Now we set the major and minor steps of the slider
sliderStep = ([1,1]/(sliderMax-sliderMin));

% update the slider gui controls by setting handles
set(handles.imageSlider,'Min',sliderMin);
set(handles.imageSlider,'Max', sliderMax);
set(handles.imageSlider,'SliderStep', sliderStep);
set(handles.imageSlider, 'Value', sliderMin);

% update the roiSet index to match the stimulus file selected
set(handles.roiSetListBox, 'Value', index);


% Now we check whether the user has entered any rois into the roiSets
% first get the current roiSet that is active in the gui
roiSetIndex = get(handles.roiSetListBox, 'Value');
% check whether the set is empty
if ~isempty(state.roiSets{roiSetIndex})
    % now obtain the number of elements in the cell corresponding to this
    % roiSet to construct our string names for the roiNamesListBox
    numStrings = numel(state.roiSets{roiSetIndex});
    % construct the base of the roi name as a cell string
    roiBaseName = {'Roi'};
    % use repmat to copy the base name numStrings times
    roiBaseNames = repmat(roiBaseName, 1, numStrings+1);
    % use genvarname to add the roi number to the end of the base name
    roiNames = genvarname(roiBaseNames);
    %remove the base name from the set of roi names
    roiNames(1)=[];
    % place these roi names into the roiNamesListBox
    set(handles.roiNamesListBox, 'String', roiNames)
    set(handles.roiNamesListBox, 'Value', 1)
    
    % if rois have been drawn then we also need to update the cellTypes box
    % with the correct cell type for the first roi
    set(handles.cellTypeListBox, 'String',...
            state.cellTypes{roiSetIndex});
    set(handles.cellTypeListBox, 'Value',1);
else
    % if the roiSet contains no Rois we set the string to '' and value to 1
    set(handles.roiNamesListBox, 'String', '')
    set(handles.roiNamesListBox, 'Value', 1)
    % also remember to update the current roi in state.
    state.currentRoi = [];
    % and we also set the cellType to empty and the value to one
    set(handles.cellTypeListBox, 'String','');
    set(handles.cellTypeListBox, 'Value', 1)
end

% We will also need to plot all the previously drawn rois so the user can
% see all of them and not redraw on top of old ones
for roiSet = 1:numel(state.roiSets)
    if ~isempty(state.roiSets{roiSet})
        % if the set is not empty, then we will draw each of the roi polygons
        for roi = 1:numel(state.roiSets{roiSet})
            roiPlotter(state.roiSets{roiSet}{roi}, 'b', imageAxes)
        end
    end
end

% We now check whether the stimulus variable is present and if so we update
% the stimValsListBox

if isfield(imExp.stimulus(1,1), state.stimVariable)
    % if so obtain all the values of this stim parameter and store to cell
    stimValsCell = num2cell(...
                    [imExp.stimulus(index,:).(state.stimVariable)]);
    % convert to strings
    stimVals = cellfun(@(e) num2str(e), stimValsCell,...
                              'UniformOut',0);
                          
    % now add the string trigger # to each string in stimVals
    for i = 1:numel(stimVals)
        stimVals{i} = ['Trigger  ', num2str(i),'  ', stimVals{i}];
    end
    
    % set the stimValsListBox to these stimVals
    set(handles.stimValsListBox,'string',stimVals)

    %if the stimulus variable is not in the experiment (i.e. 
    % Simple Center/Surround) then we have a two variable experiment 
    % consisting of angles and surround conditions we will show these to
    % the user as pairs (angle,surround cond)
    
elseif strcmp(state.stimVariable,'Simple Center/Surround')
    % Get the center angles and the surround conditions from the imexp
    centerAngles = num2cell([imExp.stimulus(index,:).Center_Orientation]);
    surroundConds = num2cell([imExp.stimulus(index,:).Surround_Condition]);
    
    % create the stimVal pairs
    stimVals = strcat(centerAngles,surroundConds);
    % convert the pairs to strings in a cell array
    stimVals = cellfun(@(f) num2str(f), stimVals, 'UniformOut',0);
    
    % now add the string trigger # to each string in stimVals
    for i = 1:numel(stimVals)
        stimVals{i} = ['Trigger  ', num2str(i),'  ', stimVals{i}];
    end
    
    % set the stimConds box to these stimVals
    set(handles.stimValsListBox, 'String', stimVals)
else
    
    msgbox(['The Stimulus Variable ',state.stimVariable,...
             ' is not present'])
end

% update the handles structure to reflect these changes in the gui
guidata(hObject,handles);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%% TRIGGER NUMBER CALLBACK %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function triggNumBox_Callback(hObject, eventdata, handles)
% Declare state and imExp to be global to this function and all functions
global state
global imExp
% 1. When the user selects a new trigger number we need to:
% 2. Set the triggerNumber to new value entered
% 3. Update the state.frameNumber
% 4. Obtain the index of the current stimFile in the stimFileBox
% 5. Obtain the imageStack name using the stim index and new trigg Number
% 6. Update the image stack name in state and the imageStackNameBox
% 7. Update the stimInfo string to match the stimulus for this trigger
% 8. Update the stimTiming box to make sure timing for trigger is updated
% 9. Update the imageData to show the corrrect stack for this trigg choice
% 10. Update the frame text string
% 11. update the slider controls so min, max, steps match this particular
%     stack
% 12. draw rois if the user has already entered rois to the roiSet

% update the trigger number and set frame number to one
state.trigNumber = str2double(get(handles.triggNumBox,'String'));
state.frameNumber = 1;

% set the imageStackName by locating the stimIndex in the imExp struct
stimIndex = get(handles.stimFileNamesBox,'Value');
state.imageStackName =...
    imExp.fileInfo(stimIndex,1).imageFileNames{state.trigNumber};
% set the imStackNameBox to the new image stack name
set(handles.imStackNameBox,'string',state.imageStackName);


% call dispStimInfo to display stimulus text info for the new trigger num
stimInfoStr = dispImStimInfo(state.stimFileName, state.trigNumber);
% display the string to the stimInfoBox
set(handles.stimInfoBox,'string', stimInfoStr);


% call dispStimTiming to display a plot of the stimulus and frame timing
stimAxes = handles.stimDisplay;
%state.imagePath = imExp.fileInfo(stimIndex,1).imagePath;
% We can only display the stimTiming if the trigger is not a missed trigger
% case
if ~strcmp(state.imageStackName,'missedTrigger')
    dispStimTiming(state.stimFileName, state.imageStackName,...
                state.frameNumber,state.imagePath, stimAxes)
else
    cla(stimAxes)
end
            

% Get the image and extrema data and call dispTiff for plotting new image
% data associated swith the new trigger choice

% set the new image stack to the stack associated with the trigg Num
state.imageStack =...
    imExp.correctedStacks(stimIndex, state.trigNumber).(['Ch',num2str(...
                                                    state.chToDisplay)]);
% get the stack Extrema associated with this stimulus choice and trigger 1
state.stackExtrema =...
    imExp.stackExtremas(stimIndex, 1).(['Ch',num2str(state.chToDisplay)]);
% set the axes for plotting just in case
imageAxes = handles.imageData;
% update the imageData by calling to DispTiff. Note we can only display a
% tiff if the trigger was not missed. If it was missed we need to clear the
% axis
if ~strcmp(state.imageStackName,'missedTrigger')
    dispTiff(imageAxes, state.imageStack, state.stackExtrema,...
            state.frameNumber,state.scaleFactor);
else
    cla(imageAxes)
end       

if ~strcmp(state.imageStackName,'missedTrigger')
    % now set the frame text string
    totalNumFrames = num2str(size(state.imageStack,3));
    % construct the frame text string
    frameText = [num2str(state.frameNumber), '/', totalNumFrames];
else 
    frameText = 'Missed Trigger';
end
% set the frame text handles
set(handles.frameNumStr, 'String', frameText);


% Now we will set the slider controls for this image stack displayed. We
% will need the slider min, max and step size. These are calculated from
% the size of the image stack
sliderMin = 1;
% The slider max will be the total num of images ( again only if trigger
% was not missed)
if ~strcmp(state.imageStackName,'missedTrigger')
    sliderMax = size(state.imageStack,3);
    set(handles.imageSlider,'Visible','on')
else
    sliderMax = 2;
    set(handles.imageSlider,'Visible','off')
end

% Now we set the major and minor steps of the slider
sliderStep = ([1,1]/(sliderMax-sliderMin));
% update the slider gui controls by setting handles
set(handles.imageSlider,'Min',sliderMin);
set(handles.imageSlider,'Max', sliderMax);
set(handles.imageSlider,'SliderStep', sliderStep);
set(handles.imageSlider, 'Value', sliderMin);

% Now we check whether the user has entered any rois into the roiSets
% if so then we will call the roi plotter to draw any previous rois
% check whether the set is empty
for roiSet = 1:numel(state.roiSets)
    if ~isempty(state.roiSets{roiSet})
        % if the set is not empty, then we will draw each of the roi polygons
        for roi = 1:numel(state.roiSets{roiSet})
            roiPlotter(state.roiSets{roiSet}{roi}, 'b', imageAxes)
        end
    end
end

% update the handles structure to reflect these changes in the gui
guidata(hObject,handles)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%% CHANNEL TO DISPLAY CALLBACK %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function chToDisplayBox_Callback(hObject, eventdata, handles)
% Declare state and imExp to be global to this function and all functions
global state
global imExp
% When the user selects a new channel to display, we need to 
% Check that the channel is in the imExp
% set the trigger number to one
% set the frame number to one
% update the imageData to match the new channel choice
% set the slider controls back to minimum

% Perform check that channel requested is present in the imExp
% get the string of the chToDisplay box
chToDispStr = get(handles.chToDisplayBox,'String');
% use arrayfun to determine if the channel is present in the corrected
% stacks substructure of the imExp
if sum(sum(arrayfun(@(s) isempty(s.(['Ch',chToDispStr])),...
                    imExp.correctedStacks))) > 1;
    errordlg(['CHANNEL ',chToDispStr,...
                ' NOT PRESENT IN MOTION CORRECTED DATA'])
else
    state.chToDisplay = str2double(chToDispStr);
    state.trigNumber = 1;
    state.frameNumber = 1;
    
    % Get the image and extrema data and call dispTiff for plotting new
    % image data associated swith the new trigger choice
    
    % get the stimIndex
    stimIndex = get(handles.stimFileNamesBox,'Value');
    % set the new image stack to the stack associated with the new ch
    state.imageStack =...
    imExp.correctedStacks(stimIndex, state.trigNumber).(['Ch',num2str(...
                                                    state.chToDisplay)]);
    % get the stack Extrema associated with the new chToDisplay and trig=1
    state.stackExtrema =...
    imExp.stackExtremas(stimIndex, 1).(['Ch',num2str(state.chToDisplay)]);
    % set the axes for plotting just in case
    imageAxes = handles.imageData;
    % update the imageData by calling to DispTiff
    dispTiff(imageAxes, state.imageStack, state.stackExtrema,...
             state.frameNumber, state.scaleFactor);
         
         
    % now set the frame text string
    totalNumFrames = num2str(size(state.imageStack,3));
    % construct the frame text string
    frameText = [num2str(state.frameNumber), '/', totalNumFrames];
    % set the frame text handles
    set(handles.frameNumStr, 'String', frameText);
    
    %Now we will set the slider controls for this image stack displayed. We
    % will need the slider min, max and step size. These are calculated
    % from the size of the image stack
    sliderMin = 1;
    % The slider max will be the total num of images
    sliderMax = size(state.imageStack,3);
    % Now we set the major and minor steps of the slider
    sliderStep = ([1,1]/(sliderMax-sliderMin));
    % update the slider gui controls by setting handles
    set(handles.imageSlider,'Min',sliderMin);
    set(handles.imageSlider,'Max', sliderMax);
    set(handles.imageSlider,'SliderStep', sliderStep);
    set(handles.imageSlider, 'Value', sliderMin);
    
    % update the handles structure to reflect these changes in the gui
    guidata(hObject,handles)
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%% IMAGE SLIDER CALLBACK %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%      
function imageSlider_Callback(hObject, eventdata, handles)
% Declare state and imExp to be global to this function and all functions
global state

% We need to give the program time to update itself as it loads new images
% in the slider callback because the user can select slider increments
% faster than the gui can update (potetnially). We'll take care of this by
% deactivating the slider control until execution is complete + 250 ms
% safegaurd
set(handles.imageSlider,'enable','inactive')

% When the image slider is pressed, we need to
% 1. update the frame number and frame text string
% 2. update the image to the next image in the image stack
% 3. update the frame box in the dispStimTiming plot
% 4. check if there are any rois and redraw rois for the current set if
%    present

% obtain the frame number from the slider value
state.frameNumber = round(get(handles.imageSlider,'Value'));

% now set the frame text string
totalNumFrames = num2str(size(state.imageStack,3));
% construct the frame text string
frameText = [num2str(state.frameNumber), '/', totalNumFrames];
% set the frame text handles
set(handles.frameNumStr, 'String', frameText);

% update the imageData by calling to DispTiff
imageAxes = handles.imageData;
dispTiff(imageAxes, state.imageStack, state.stackExtrema,...
             state.frameNumber, state.scaleFactor); 
         
% call dispStimTiming to display a plot of the stimulus and frame timing
stimAxes = handles.stimDisplay;
dispStimTiming(state.stimFileName, state.imageStackName,...
                state.frameNumber,state.imagePath, stimAxes)
            
% Now we check whether the user has entered any rois into the roiSets
% if so then we will call the roi plotter and draw all the rois

for roiSet = 1:numel(state.roiSets)
    if ~isempty(state.roiSets{roiSet})
        % if the set is not empty, then we will draw each of the roi polygons
        for roi = 1:numel(state.roiSets{roiSet})
            roiPlotter(state.roiSets{roiSet}{roi}, 'b', imageAxes)
        end
    end
end
% update the handles structure to reflect these changes in the gui
guidata(hObject,handles)

% add safegaurd of 250 ms of deactivated slider control
pause(.25)
set(handles.imageSlider,'enable','on')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%% SCALE FACTOR CALLBACK %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function scaleFactorBox_Callback(hObject, eventdata, handles)
global state
% When the user selects a new scale factor to display images with, we need
% to do the following
% 1. call dispTiff to update the imageData
state.scaleFactor = str2double(get(handles.scaleFactorBox,'String'));

% update the imageData by calling to DispTiff
imageAxes = handles.imageData;
dispTiff(imageAxes, state.imageStack, state.stackExtrema,...
             state.frameNumber, state.scaleFactor); 
         
% update the handles structure to reflect these changes in the gui
guidata(hObject,handles)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%% FRAMES/SEC CALLBACK %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function framesPerSec_Callback(hObject, eventdata, handles)
% We simply update handles with the new frame rate to play movie with. No
% need to save to state
% update the handles structure to reflect these changes in the gui
guidata(hObject,handles)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%% REPEATS CALLBACK %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function repeatsBox_Callback(hObject, eventdata, handles)
% We simply update handles with the new repeat to play movie with. No
% need to save to state
% update the handles structure to reflect these changes in the gui
guidata(hObject,handles)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%% PLAYSTACK CALLBACK %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function playStack_Callback(hObject, eventdata, handles)
global state
global imExp
% When the user selects the playStack button, we need to open a new figure
% and display a movie of the currently selected stack

framesPerSec = str2double(get(handles.framesPerSec,'String'));
repeats = str2double(get(handles.repeatsBox,'String'));

runMovieStack(state.imageStack, imExp.stimulus(1,1).Timing,...
                           imExp.fileInfo(1,1).imageFrameRate,...
                           state.scaleFactor, framesPerSec, repeats);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%% EVOKEDSTACK CALLBACK %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function evokedStack_Callback(hObject, eventdata, handles)
global state
global imExp
% When the user selects the playStack button, we need to open a new figure
% and display a movie of the currently selected stack 
framesPerSec = str2double(get(handles.framesPerSec,'String'));
repeats = str2double(get(handles.repeatsBox,'String'));

evokedMovieStack(state.imageStack, imExp.stimulus(1,1).Timing,...
                           imExp.fileInfo(1,1).imageFrameRate,...
                           state.scaleFactor, framesPerSec, repeats );
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                       
                       
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%% MAP BUTTON CALLBACK %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Declare state and imExp to be global to this function and all functions
function mapButton_Callback(hObject, eventdata, handles)
global state
global imExp
% When the user presses the map button we want to get the current value of
% the scale factor and call the function RetinoMapper with a run state of
% 2. This will return a matrix map of retinotopic responses
[matrixMap] = RetinoMapper( imExp, state.chToDisplay, state.runState);

% create a new figure to display to 
mapFigure = figure;
imshow(matrixMap, [0,max(max(matrixMap)/state.scaleFactor)])

% update the handles structure to reflect these changes in the gui
guidata(hObject,handles)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%% DRAW METHOD CALLBACK %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function drawMethodBox_Callback(hObject, eventdata, handles)
% Declare state to be global to this function and all functions
global state
% Obtain the cell array of all the methods in the list box
allMethods = cellstr(get(hObject,'String'));
% set the drawMethod in state to be the currently selected method from the
% listbox
state.drawMethod = allMethods{get(hObject,'Value')};
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%% DRAW ROI CALLBACK %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function drawButton_Callback(hObject, eventdata, handles)
% Declare state to be global to this function and all functions
global state
% When the user presses the drawButton, we allow the user to drag the mouse
% to the image data axis to construct an roi according to draw method
% (Currently only free hand drawing is available). We then return the
% drawing object called an roi. To do this we call the roiDrawer function
% in the helper directory
imageAxes = handles.imageData;
state.currentRoi = roiDrawer(state.drawMethod,imageAxes);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%% CELL TYPE CALLBACK %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function cellTypeEdit_Callback(hObject, eventdata, handles)
global state
% When the cellTypeEdit is changed, we need to add the new text to state.
state.currentCellType = get(handles.cellTypeEdit,'string');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%% ADD ROI CALLBACK %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function addRoiButton_Callback(hObject, eventdata, handles)
% Declare state to be global to this function and all functions
global state
% 1. When the user presses the addRoi button, we need to get the current
%    roiSet index and place the roi object into a cell within the roiSets
%    cell. 
% 2. After adding the Roi to the roi sets cell, we need to update the roi
%    names listbox. 
% 3. For the new roi we need to add the cell type currently supplied in the
%    cellType edit box to the cellTypes cell array


roiSetIndex = get(handles.roiSetListBox, 'Value');

% We now need to add the cell type supplied in the cellType edit box to the
% cellTypes cell. The cellType cell array is the same size as the roiSets
% cell array so we just use the roiSets index to determine the position of
% the string

%case if there are no rois present in the roiSet
if isempty(state.roiSets{roiSetIndex})
    state.cellTypes{roiSetIndex}{1} = state.initCellType;
    % else if there is already an roi object (or multiple objects),
    % determine the cell element to place our new roi object to by 1 more
    % than the number of roi objects currently occupying the cell
else
    state.cellTypes{roiSetIndex}{numel(state.roiSets{roiSetIndex}) + 1} =...
        state.initCellType;
end


% To add the newly drawn roi to our cell array of rois called the roiSet,
% we get the index of the currently selected roi set. We then place the roi
% object created in draw callback into a cell within the roiSets. If the
% cell we are placing the object into is empty our roi object will occupy
% position 1. If the cell already contains previously drawn roi objects we
% will place the new roi object at the end

% case if the cell within roiSets is empty place our first roi in position
% one
if isempty(state.roiSets{roiSetIndex})
    state.roiSets{roiSetIndex}{1} = state.currentRoi;
    % else if there is already an roi object (or multiple objects),
    % determine the cell element to place our new roi object to by 1 more
    % than the number of roi objects currently occupying the cell
else
    state.roiSets{roiSetIndex}{numel(state.roiSets{roiSetIndex}) + 1} =...
        state.currentRoi;
end

% We now are ready to construct the names to appear in the roiNamesListBox.
% We make these names based on the number of elements of
% roiSets{roiSetIndex) (i.e. the currently selected set). We proceed as we
% did in the load callback using repmat and genvarname to construct names
% such as roi1, roi2,...
% construct sting names for the roi names list box
numStrings = numel(state.roiSets{roiSetIndex});
% construct the base of the roi name as a cell string
roiBaseName = {'Roi'};
% use repmat to copy the base name numStrings times
roiBaseNames = repmat(roiBaseName, 1, numStrings+1);
% use genvarname to add the roi number to the end of the base name
roiNames = genvarname(roiBaseNames);
%remove the base name from the set of roi names
roiNames(1)=[];
% place these roi names into the roiNamesListBox
set(handles.roiNamesListBox, 'String', roiNames)
% set the value to the last string
set(handles.roiNamesListBox, 'Value', max(1,numel(roiNames)))

% Set the cellTypesListBox to the new cell array of cell types now
% including the new unassigned cell and set the value to be the last
% roiValue
set(handles.cellTypeListBox,'String',state.cellTypes{roiSetIndex})
set(handles.cellTypeListBox,'Value', max(1,numel(roiNames)))

% update the handles structure to reflect these changes in the gui
guidata(hObject,handles)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%% ROI SETS LISTBOX CALLBACK %%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function roiSetListBox_Callback(hObject, eventdata, handles)
% Declare state and imExp to be global to this function and all functions
global state
global imExp
% When the user selects one of the roiSets, we need to:
% 1. update the stimulus file that this roiSet belongs to in the
%    stimFilesBox
% 2. reset the trigger number and frameNumber to one 
% 3. update image stack name
% 4. update the stimulus information
% 5. update stimTiming plot
% 6. update the image to the first image of the stack of the stimulus set
%    and set the frame number on the image to be 1
% 7. update the slider to the min value
% 7. get the number of elements in the roiSets{setIndex} and create the
%    corresponding number of roi Names and add them to the roiNames box
% 8. set the roi to the first roi in the names box and highlight this roi
%    on the image if it exist
% 9. if roiSets already contains user drawn rois then we must draw this to
%    image data on callback

% obtain the setIndex from the roiSetsListBox
roiSetIndex = get(handles.roiSetListBox, 'Value');
% update the stimFileNames box
set(handles.stimFileNamesBox,'Value',roiSetIndex)
% update the state structure
state.stimFileName = state.stimFileNames{roiSetIndex};


% update the trigger number
state.trigNumber = 1;
set(handles.triggNumBox,'String',1);
% update the frame number to one
state.frameNumber = 1;


% update the imageStack namebox and state element to match the index of the
% stimfile in the list box and supplying 1 as the trigger
state.imageStackName =...
    imExp.fileInfo(roiSetIndex,1).imageFileNames{state.trigNumber};
% set the imStackNameBox to the new image stack name
set(handles.imStackNameBox,'string',state.imageStackName);


% call dispStimInfo to display stimulus text info for the new stimulus file
% and using trigNumber 1
stimInfoStr = dispImStimInfo(state.stimFileName, state.trigNumber);
% display the string to the stimInfoBox
set(handles.stimInfoBox,'string', stimInfoStr);


% call dispStimTiming to display a plot of the stimulus and frame timing
stimAxes = handles.stimDisplay;
%state.imagePath = imExp.fileInfo(roiSetIndex,1).imagePath;
dispStimTiming(state.stimFileName, state.imageStackName,...
                state.frameNumber,state.imagePath, stimAxes)
            

% Get the image and extrema data and call dispTiff for plotting new image
% data associated swith the new stimulus choice
% set the new image stack to the stack associated with the stimFileName
% index choice and trigger number one 
state.imageStack =...
    imExp.correctedStacks(roiSetIndex,state.trigNumber).(['Ch',num2str(...
                                                    state.chToDisplay)]);
% get the stack Extrema associated with this stimulus choice and trigger 1
state.stackExtrema =...
    imExp.stackExtremas(roiSetIndex,1).(['Ch',num2str(state.chToDisplay)]);
% set the axes for plotting just in case
imageAxes = handles.imageData;
% update the imageData by calling to DispTiff
dispTiff(imageAxes, state.imageStack, state.stackExtrema,...
            state.frameNumber, state.scaleFactor);
  
        
 % now set the frame text string
totalNumFrames = num2str(size(state.imageStack,3));
% construct the frame text string
frameText = [num2str(state.frameNumber), '/', totalNumFrames];
% set the frame text handles
set(handles.frameNumStr, 'String', frameText);           
   

% Now we will set the slider controls for this image stack displayed. We
% will need the slider min, max and step size. These are calculated from
% the size of the image stack
sliderMin = 1;
% The slider max will be the total num of images
sliderMax = size(state.imageStack,3);
% Now we set the major and minor steps of the slider
sliderStep = ([1,1]/(sliderMax-sliderMin));

% update the slider gui controls by setting handles
set(handles.imageSlider,'Min',sliderMin);
set(handles.imageSlider,'Max', sliderMax);
set(handles.imageSlider,'SliderStep', sliderStep);
set(handles.imageSlider, 'Value', sliderMin);            
            
                        
% now obtain the number of elements in the cell corresponding to this
% roiSet to construct our string names for the roiNamesListBox
numStrings = numel(state.roiSets{roiSetIndex});
% construct the base of the roi name as a cell string
roiBaseName = {'Roi'};
% use repmat to copy the base name numStrings times
roiBaseNames = repmat(roiBaseName, 1, numStrings+1);
% use genvarname to add the roi number to the end of the base name
roiNames = genvarname(roiBaseNames);
%remove the base name from the set of roi names
roiNames(1)=[];
% place these roi names into the roiNamesListBox
set(handles.roiNamesListBox, 'String', roiNames)
% set the value to the last string
set(handles.roiNamesListBox, 'Value', max(1,numel(roiNames)))

% and set the cellTypeList box to the cellType cell array
if ~isempty(state.roiSets{roiSetIndex})
    set(handles.cellTypeListBox, 'String',...
        state.cellTypes{roiSetIndex})
    % also set the value to be the max number of rois for this set to match
    % the last roi from above
    set(handles.cellTypeListBox, 'Value',max(1,numel(roiNames)))
else
   set(handles.cellTypeListBox, 'String','')
   set(handles.cellTypeListBox, 'Value',1)
end

% also make sure we update the roi in state
if ~isempty(state.roiSets{roiSetIndex})
    state.currentRoi = state.roiSets{roiSetIndex}{max(1,numel(roiNames))};
else
    state.currentRoi = [];
end

% Now we check whether the user has entered any rois into the roiSets
% check whether the set is empty
for roiSet = 1:numel(state.roiSets)
if ~isempty(state.roiSets{roiSet})
    % if the set is not empty, then we will draw each of the roi polygons
    for roi = 1:numel(state.roiSets{roiSet})
        roiPlotter(state.roiSets{roiSet}{roi}, 'b', imageAxes)
    end
end
end

if isfield(imExp.stimulus(1,1), state.stimVariable)
    % if so obtain all the values of this stim parameter and store to cell
    stimValsCell = num2cell(...
                    [imExp.stimulus(roiSetIndex,:).(state.stimVariable)]);
                
                
    % convert stimVals to strings
    stimVals = cellfun(@(e) num2str(e), stimValsCell,...
                              'UniformOut',0);
    
    % now add the string trigger # to each string in stimVals
    for i = 1:numel(stimVals)
        stimVals{i} = ['Trigger  ', num2str(i),'  ',stimVals{i}];
    end
    
    % set the stimValsListBox to these stimVals
    set(handles.stimValsListBox,'string',stimVals)

    %if the stimulus variable is not in the experiment (i.e. 
    % Simple Center/Surround) then we have a two variable experiment 
    % consisting of angles and surround conditions we will show these to
    % the user as pairs (angle,surround cond)
    
elseif strcmp(state.stimVariable,'Simple Center/Surround')
    % Get the center angles and the surround conditions from the imexp
    centerAngles = num2cell(...
                    [imExp.stimulus(roiSetIndex,:).Center_Orientation]);
    surroundConds = num2cell(...
                    [imExp.stimulus(roiSetIndex,:).Surround_Condition]);
    
    % create the stimVal pairs
    stimVals = strcat(centerAngles,surroundConds);
    % convert the pairs to strings in a cell array
    stimVals = cellfun(@(f) num2str(f), stimVals, 'UniformOut',0);
    
    % now add the string trigger # to each string in stimVals
    for i = 1:numel(stimVals)
        stimVals{i} = ['Trigger  ', num2str(i),'  ', stimVals{i}];
    end
    
    % set the stimConds box to these stimVals
    set(handles.stimValsListBox, 'String', stimVals)
else
    
    stimMsgErr = msgbox(['The Stimulus Variable ',state.stimVariable,...
             ' is not present']);
         
    pause(5)
    if ishandle(stimMsgErr)
        close(stimMsgErr)
    end
end

% update the handles structure to reflect these changes in the gui
guidata(hObject,handles)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%% ROINAMES LISTBOX CALLBACK %%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function roiNamesListBox_Callback(hObject, eventdata, handles)
% When the user selects an roi name from the roi names list box, we want to
% 1. Briefly alternate the color of the roi region to signfy this roi as
% the selected one to the user
% Declare state to be global to this function and all functions
global state
% Obtain the roi index and the set that the roi belongs to 
roiIndex = get(handles.roiNamesListBox,'Value');
roiSet = get(handles.roiSetListBox, 'Value');
% retrieve this roi from state.roiSets
state.currentRoi = state.roiSets{roiSet}{roiIndex};

% set the cell type in state and the cellTypeEdit
state.currentCellType = state.cellTypes{roiSet}{roiIndex};
set(handles.cellTypeListBox, 'Value', roiIndex);

% be sure we plot to the imaging axes
axes = handles.imageData;
hold(axes, 'on');
% This is a clumsy but effective way to quickly alternate colors
colors = {'r','y','r','y'};
for iter = 1:4
    h1 = plot(state.currentRoi(:,1),state.currentRoi(:,2), colors{iter},...
    'LineWidth', 3, 'Parent', axes);  
pause(0.1)
delete(h1)
end
hold(axes, 'off');

% update the handles structure to reflect these changes in the gui
guidata(hObject,handles)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%% REMOVE ROI CALLBACK %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function removeRoiButton_Callback(hObject, eventdata, handles)
global state
% if the user has selected to remove an roi, then we must do the following:
% 1. get the index of the roi to remove from the roiNames box
% 2. delete this roi from the roi sets and the celltype from cellTypes
% 3. generate new names for the roiNames box so that the number of names
%    matches the number of rois in the roiSet
% when the user updates the slider the roi will then be deleted

% get the index of the roi to be removed and the roiSet index
roiIndex = get(handles.roiNamesListBox,'Value');
roiSet = get(handles.roiSetListBox, 'Value');

% delete this roi from state.roiSets
state.roiSets{roiSet}(roiIndex) = [];

% delete the cell type 
state.cellTypes{roiSet}(roiIndex) = [];

% update the cell type box and the currentCellType in state
if roiIndex > 1
    set(handles.cellTypeListBox,'String', state.cellTypes{roiSet})
    set(handles.cellTypeListBox, 'Value', roiIndex-1)
    state.currentCellType = state.cellTypes{roiSet}{roiIndex-1};
else
    set(handles.cellTypeListBox,'String', '')
    set(handles.cellTypeListBox,'Value',1)
    state.currentCellType = '';
end

% now obtain the number of elements in the cell corresponding to this
% roiSet to construct our string names for the roiNamesListBox
numStrings = numel(state.roiSets{roiSet});
% construct the base of the roi name as a cell string
roiBaseName = {'Roi'};
% use repmat to copy the base name numStrings times
roiBaseNames = repmat(roiBaseName, 1, numStrings+1);
% use genvarname to add the roi number to the end of the base name
roiNames = genvarname(roiBaseNames);
%remove the base name from the set of roi names
roiNames(1)=[];
% place these roi names into the roiNamesListBox
set(handles.roiNamesListBox, 'String', roiNames)
% We are removing an roi so in the case where only one roi existed prior to
% deletion, the list box becomes value 0 which is not allowed so we test
% this and set to listbox value of one if needed
if roiIndex > 1
    set(handles.roiNamesListBox, 'Value', roiIndex-1)
    state.currentRoi = state.roiSets{roiSet}(roiIndex-1);
else
    set(handles.roiNamesListBox, 'Value', 1)
    state.currentRoi = [];
end

% update the handles structure to reflect these changes in the gui
guidata(hObject,handles)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%% EDIT CELLTYPE CALLBACK %%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function editCellType_Callback(hObject, eventdata, handles)
% We are going to change one of the elements of the cellTypes cell arrray
% We start by getting the current roiSet and roiIndex since this tells us
% which element will be changed
global state

% get the index of the roi to be removed and the roiSet index
roiIndex = get(handles.roiNamesListBox,'Value');
roiSet = get(handles.roiSetListBox, 'Value');

% now get the current string in the edit box
newCellType = get(handles.editCellType, 'String');

% and set the newCellType into the cellType array stored in state
state.cellTypes{roiSet}{roiIndex} = newCellType;

% last make update to cellTypeListBox
set(handles.cellTypeListBox, 'String', state.cellTypes{roiSet})

% update gui
guidata(hObject,handles)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%% TOOLBAR SAVE CALLBACK %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function saveButton_ClickedCallback(hObject, eventdata, handles)
% When the user clicks the S toolbar button we will callback here. This
% function will copy whatever is in imageData axis to a new figure where it
% can be saved or printed

% get the number of open figures
numFigs=length(findall(0,'type','figure'));
% create a figure one greater than the number of open figures
saveFig = figure(numFigs+1);

% We need to get the original colormap
colmap  = colormap(handles.imageData);

% create the new object and set to old colormap
saveObj = copyobj(handles.imageData,saveFig);
colormap(saveObj,colmap)

set(saveFig, 'Position', [462 278 539 591])
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%% CELLIDENTIFIER CALLBACK %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function cellIdentifier_Callback(hObject, eventdata, handles)
global state
global imExp
% when the user presses the cell identifier button we will call
% cellImageIdentifier which will open a new figure window with a fused
% image of the red and green chs for easy identification of cell types
trialIndex = get(handles.stimFileNamesBox,'Value');
cellImageIdentifier(imExp.fileInfo, state.imagePath, trialIndex, ...
                    state.trigNumber, state.frameNumber, [2,3],...
                    state.scaleFactor, [2,1])
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%% AVERAGE ALL STACKS CALLBACK %%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Executes on button press in averageStacks.
function averageStacks_Callback(hObject, eventdata, handles)
global state
global imExp
% when the user presses the average stacks button we need to get all of the
% image stacks and perform an average and return this to our imaging axis
% so they can draw rois to it. We will set the current roi set to be the
% first roi set, meaning all rois drawn on the average image will be added
% to roiSet 1.
[Image] = multiStackMaxIntensity({imExp.correctedStacks(4,:).(['Ch',...
                            num2str(state.chToDisplay)])},'uint16');

%assignin('base','Image',Image)
% set the axes for plotting just in case
imageAxes = handles.imageData;
Image = imadjust(Image);
imshow(Image, ...
    [min(Image(:))/state.scaleFactor,max(Image(:))/state.scaleFactor],...
        'Parent', imageAxes);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                        
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%% STIMVARIABLE CALLBACK %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function stimVariableMenu_Callback(hObject, eventdata, handles)
% When the user selects a stimulus variable, we will show them the stimulus
% parameters for all the triggers for the particular stimulus file selected
% in the stimFileNames box. We will then display the parameters to the
% stimValsListBox. Note we need to handle the case in which the stimulus
% parameter is a singleton (i.e. like orientation) or a doubleton (such as
% centerOrientation, surroundCondition). Right now the program only allows
% display of single and two variable stimuli but can be extended later. We
% currently only have simpleCenterSurround as the two variable stimuli. All
% other stimuli is single variable. We will separate based on whether the
% user has chosen simple Center-Surround as the stimulus.
global state
global imExp

% obtain the stimFileName and index in the list box
% get the index of the user selected stimulus
index = get(handles.stimFileNamesBox,'Value');

% get the cellstr of all the stimVariables in the box
allStimVariables = cellstr(get(handles.stimVariableMenu,'String'));

% set the stimVariable in state
state.stimVariable = ...
    allStimVariables{get(handles.stimVariableMenu,'Value')};

% if the stimVariable is a single stimulus parameter exp such as
% orientation, we will first confirm that the variable is present in the
% experiment
if isfield(imExp.stimulus(1,1), state.stimVariable)
    % if so obtain all the values of this stim parameter and store to cell
    stimValsCell = num2cell(...
                    [imExp.stimulus(index,:).(state.stimVariable)]);
                
    % convert stimVals to strings
    stimVals = cellfun(@(e) num2str(e), stimValsCell,...
                              'UniformOut',0);
    
    % now add the string trigger # to each string in stimVals
    for i = 1:numel(stimVals)
        stimVals{i} = ['Trigger  ', num2str(i),'  ', stimVals{i}];
    end
    
    % set the stimValsListBox to these stimVals
    set(handles.stimValsListBox,'string',stimVals)

    %if the stimulus variable is not in the experiment (i.e. 
    % Simple Center/Surround) then we have a two variable experiment 
    % consisting of angles and surround conditions we will show these to
    % the user as pairs (angle,surround cond)
    
elseif strcmp(state.stimVariable,'Simple Center/Surround')
    % Get the center angles and the surround conditions from the imexp
    centerAngles = num2cell([imExp.stimulus(index,:).Center_Orientation]);
    surroundConds = num2cell([imExp.stimulus(index,:).Surround_Condition]);
    
    % create the stimVal pairs
    stimVals = strcat(centerAngles,surroundConds);
    % convert the pairs to strings in a cell array
    stimVals = cellfun(@(f) num2str(f), stimVals, 'UniformOut',0);
    
    % if the user has saved the running condition to the imExp then a field
    % called behavior is present and we will display which triggers the
    % animal was running in the stimVals box (trigger information)
    
    if isfield(imExp,'behavior')
    % obtain the running state
    runValsCell = num2cell(...
                    [imExp.behavior(index,:).Running]);
                
    % convert runVals to strings
    runVals = cellfun(@(e) num2str(e), runValsCell,...
                              'UniformOut',0);
    
    % now add the string trigger # to each string in stimVals and the
    % runValue
        for i = 1:numel(stimVals)
            stimVals{i} = ['Trigger  ', num2str(i),'  ', stimVals{i},...
                '  Running  ', runVals{i}];
        end
    else
        for i = 1:numel(stimVals)
            stimVals{i} = ['Trigger  ', num2str(i),'  ', stimVals{i}];
        end
    end
    
    % set the stimConds box to these stimVals
    set(handles.stimValsListBox, 'String', stimVals)
else
    
    stimMsgErr = msgbox(['The Stimulus Variable ',state.stimVariable,...
             ' is not present']);
    pause(5)
    % If user has not already closed msg close it now.
    if ishandle(stimMsgErr)
        close(stimMsgErr)
    end
end

% update the handles structure to reflect these changes in the gui
guidata(hObject,handles)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%% RUNSTATE CALLBACK %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function runStateBox_Callback(hObject, eventdata, handles)
% When the user selects a runState, we need to save this choice to the
% state variable to be passed to the fluorMap to construct a map of
% fluorescent signals based on the runningState choice
global state
state.runState = str2double(get(handles.runStateBox,'String'));
% update the handles structure to reflect these changes in the gui
guidata(hObject,handles)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%% STIMVALSLISTBOX CALLBACK %%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function stimValsListBox_Callback(hObject, eventdata, handles)
% When the user selects a stimulus file we want to display to this box the
% stimulus variables in the order in which they were shown in the exp
% update the handles structure to reflect these changes in the gui
guidata(hObject,handles)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%% NEUROPIL RATIO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function neuropilFactor_Callback(hObject, eventdata, handles)
% When the user enters a new neuropil ratio we need to save that value into
% state
global state
state.neuropilRatio = str2double(get(handles.neuropilFactor,'String'));
% and update the handles structure
guidata(hObject,handles)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%% LED CHECKBOX AND TRIALS %%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function LedChkBox_Callback(hObject, eventdata, handles)
% When the user changes whether leds were used, we need to update state
global state
state.Led{1} = logical(get(handles.LedChkBox,'Value'));
% and update the handles structure
guidata(hObject,handles)

function ledTrialsBox_Callback(hObject, eventdata, handles)
% When the user changes which trials the led was shown on 'odd' or 'even',
% we need to check that it is a valid entry and then update the state.
global state
userReqString = get(handles.ledTrialsBox,'String');
% Perform an error handling check to ensure the user has entered 'even' or
% 'odd'
if ~any(ismember({'odd','even'},userReqString))
    LedMsgErr = msgbox(['Led trials can only be odd or even:', char(10),...
                        'Defaulting to even']);
    pause(5)
    % If user has not already closed msg close it now.
    if ishandle(LedMsgErr)
        close(LedMsgErr)
    end
    
    set(handles.LedTrialsBox,'String','even')
else
    state.Led{2} = get(handles.ledTrialsBox, 'String');
end

function plotLedResponse_Callback(hObject, eventdata, handles)
% When the user presses the plotLedResponse button we call the function
% optoResponse to plot the laser/led trials response only if dropped frames
% are present in the imExp
global state
global imExp
if isfield(imExp,'droppedStacks')
    % use only the first two frames to compute (note this needs
    % generalization at some point
    optoResponse(imExp.droppedStacks, state.chToDisplay,...
                 state.currentRoi, [1,2], state.neuropilRatio)
else
    hmsg = msgbox(...
        'This experiment does not contain the dropped Laser/Led stacks');
    wait(2)
    close(hmsg)
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%% LED AND NO LED BASELINE FRAMES CALLBACK %%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The baseline frames determines what frames will be used for the baseline
% in the no led and led conditions. We get those frames for passing to the
% the signal mapper which ultimately constructs our df/f plots.

function noLedBaselineFrames_Callback(hObject, eventdata, handles)
global state
% When the user enters a new set of frames we need to get that and store to
% state
state.noLedBaseline = str2num(get(handles.noLedBaselineFrames,'String'));
                                
function ledBaselineFrames_Callback(hObject, eventdata, handles)
global state
state.ledBaseline = str2num(get(...
                                    handles.ledBaselineFrames,'String'));                          
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%% MEAN DF/F CALLBACK %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Executes on button press in meanDFbyFButton.
function meanDFbyFButton_Callback(hObject, eventdata, handles)

global imExp
global state
%assignin('base','analyzerState',state)
% When the user selects to plot the mean df/f, we need to perform the
% following
% call the signalMapper which will create the proper map object for the
% given stimVariable
% use the outputted plotterType to call the correct plotting function

% Display a message to let the user know what is happening and warning them
% the plot is an approximation becasue overlapping rois have yet to be
% calculated
hmsg = msgbox(['Plot Being Generated: Please Note', char(10), ...
        'The Plot is an Approximation until', char(10),...
        'all Rois have been drawn']);

% Get the current roi number 
roiIndex = get(handles.roiNamesListBox,'Value');
roiSet = get(handles.roiSetListBox, 'Value');

[signalMaps, plotterType, framesDropped] = SignalMapper(imExp,...
                                    state.stimVariable,...
                                    state.roiSets, state.currentRoi,...
                                    state.chToDisplay,...
                                    state.runState, state.Led,...
                                    state.neuropilRatio,...
                                    state.noLedBaseline,...
                                    state.ledBaseline);
    
% get the number of open figures
numFigs=length(findall(0,'type','figure'));
% create a figure one greater than the number of open figures
hfig = figure(numFigs+1);
    
% Call the correct plotting routine
switch plotterType
        
    case 'fluorPlotter'
        fluorPlotter2(signalMaps, state.stimVariable, imExp.stimulus,...
            imExp.fileInfo, framesDropped, hfig,roiSet, roiIndex,...
            state.imExpName);
        close(hmsg)
        
    case 'csPlotter'
        csPlotter(signalMaps,state.cellTypes{roiSet}{roiIndex},'all',...
                  imExp.stimulus, imExp.fileInfo, framesDropped, hfig,...
                  roiSet, roiIndex, state.imExpName)
        
        close(hmsg)
        
    otherwise
        close(hmsg)
        % Throw message error
        hmsgErr = msgbox(['The selected stimulus variable', ...
            'is not present in the imExp OR no Roi selected']);
        pause(5)
        % If user has not already closed msg close it now.
        if ishandle(hmsgErr)
            close(hmsgErr)
        end
            
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%% MULTICELL VIEWER CALLBACK %%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function multiCellViewer_Callback(hObject, eventdata, handles)
% hObject    handle to multiCellViewer (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global state
global imExp
% When the user presses the multicell viewer button we need to get all of
% the rois in roiSets, the cellTypes, the maxIntensity image,
% and call the signal mapper and return all of the signals for plotting

%%%%%%%%%%%%%%%%%%%%%%%%%%%% OPEN A NEW FIGURE %%%%%%%%%%%%%%%%%%%%%%%%%%%%
numFigs = length(findall(0,'type','figure'));
hMultiCellViewerFig = figure(numFigs+1);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%% DISPLAY A MESSAGE TO FIGURE %%%%%%%%%%%%%%%%%%%%%%%%%%%
hmsgBox = uicontrol('style','text','Fontsize',12,'Fontweight','Bold');
set(hmsgBox,'String','Performing Fluorescence calculation on all rois')
% get the figures position
multiCellViewerFigPos = get(hMultiCellViewerFig,'Position');
mBoxWidth = 200;
mBoxHeight = 50;
set(hmsgBox,'Position',...
    [multiCellViewerFigPos(3)/2-0.5*mBoxWidth,...
    multiCellViewerFigPos(4)/2, mBoxWidth, mBoxHeight])

% We introduce a 500 msec pause becasue matlab begins allocating memory for
% the signal maps before the figure is displayed so that the figure does
% not appear until the calculation below is completed. By introducing this
% pause we prevent this.
pause(0.5);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%% CALCULATE SIGNAL MAPS FOR ALL ROIS %%%%%%%%%%%%%%%%%%%%%
% we call the signal mapper function in the helper functions directory
% which calls the appropriate fluorescence map (i.e. fluorMap or csFluorMap
% and returns back a cell arrray of all signal maps, one for each led 
% condition, and each roi orgainzed by roiSets.

signalMaps = SignalMapper(imExp, state.stimVariable, state.roiSets,[],...
                          state.chToDisplay, state.runState,state.Led,...
                          state.neuropilRatio);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% calculate MIP
[mip] = multiStackMaxIntensity({imExp.correctedStacks(:,:).(['Ch',...
                            num2str(state.chToDisplay)])},'uint16');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
set(hmsgBox,'Visible','off')
% call the multiCellFluorplotter to create figure with uicontrols to scroll
% through signal maps for all drawn rois.
multiCellFluorPlotter(hMultiCellViewerFig,signalMaps,state.roiSets,...
                      state.stimVariable, imExp.stimulus,...
                      imExp.fileInfo, mip, state.drawMethod)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%% NOTESBOX CALLBACK %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function notesBox_Callback(hObject, eventdata, handles)
global state
% When the user enters a set of notes for this experiment we need to update
% these notes in state
state.notes =  get(handles.notesBox, 'String');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% SAVE CALLBACK %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function save_Callback(hObject, eventdata, handles)
global state
global imExp
% When the user selects the save button we need to obtain the roiSets from
% the state structure and place the cell array into the imExp then resave
% imExp with the string 'rois' in the filename to indicate rois have been
% added to imExp. This is accomplished by the imExpSaver func. with the
% imExpAnalyzer gui option
imExp.rois = state.roiSets;
% We also need to save the cellTypes
imExp.cellTypes = state.cellTypes;
% We also need to relay back whether the user has selected run/no run
% trials for the imExp signal maps below.
imExp.SignalRunState = state.runState;
% We also need to calculate the signals for each trial for each roi. We use
% signalMapper in the helper funcs to accomplish and save these to the
% imExp structure
imExp.signalMaps = SignalMapper( imExp, state.stimVariable,...
                                 state.roiSets, [], state.chToDisplay,...
                                 state.runState,state.Led,...
                                 state.neuropilRatio,state.noLedBaseline,...
                                 state.ledBaseline);
                             
imExp.noLedBaselineFrames = state.noLedBaseline;
imExp.ledBaselineFrames = state.ledBaseline;

% We will now add the users notes to the imExp                             
imExp.notes = state.notes;

imExpSaverFunc([], state.imExpName, imExp, 'roi')

% update the handles structure to reflect these changes in the gui
guidata(hObject,handles)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
%$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
%$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
%$$$$$$$$$$$$$$$$$$$$$$ END OF USED CALLBACKS $$$$$$$$$$$$$$$$$$$$$$$$$$$$$
%$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
%$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
%$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$



% --- Executes during object creation, after setting all properties.
function triggNumBox_CreateFcn(hObject, ~, handles)
if ispc && isequal(get(hObject,'BackgroundColor'),...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function imStackNameBox_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function imStackNameBox_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'),...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function stimInfoBox_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function stimInfoBox_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'),...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function imExpBox_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function imExpBox_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'),...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function stimFileNamesBox_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'),...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in removeButton.
function removeButton_Callback(hObject, eventdata, handles)
% hObject    handle to removeButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --- Executes during object creation, after setting all properties.
function imageSlider_CreateFcn(hObject, eventdata, handles)
% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'),...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

% --- Executes during object creation, after setting all properties.
function chToDisplayBox_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'),...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function drawMethodBox_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'),...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function roiSetListBox_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'),...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function roiNamesListBox_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'),...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function scaleFactorBox_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'),...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function stimVariableMenu_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'),...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function runStateBox_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'),...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function framesPerSec_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'),...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function stimValsListBox_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'),...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function repeatsBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to repeatsBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'),...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function notesBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to notesBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'),...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function cellTypeEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to cellTypeEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'),...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function neuropilFactor_CreateFcn(hObject, eventdata, handles)
% hObject    handle to neuropilFactor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'),...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on selection change in cellTypeListBox.
function cellTypeListBox_Callback(hObject, eventdata, handles)
% hObject    handle to cellTypeListBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --- Executes during object creation, after setting all properties.
function cellTypeListBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to cellTypeListBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'),...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function editCellType_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editCellType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'),...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function ledTrialsBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ledTrialsBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --------------------------------------------------------------------
function Untitled_1_Callback(hObject, eventdata, handles)
% hObject    handle to Untitled_1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --- Executes during object creation, after setting all properties.
function noLedBaselineFrames_CreateFcn(hObject, eventdata, handles)
% hObject    handle to noLedBaselineFrames (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function ledBaselineFrames_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ledBaselineFrames (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


