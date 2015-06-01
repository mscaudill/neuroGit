function varargout = ImExpMaker(varargin)
% IMEXPMAKER M-file for ImExpMaker.fig
% Last Modified by GUIDE v2.5 06-Dec-2013 15:52:40
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
% ImExpMaker creates an imExp structure with fields correctedStacks,
% stimulus, fileInfo, stackExtremas and possibly runningInfo. These
% substructures contain all the stimulus and recorded data. The user can
% elect to analyze the running and perform motion correction to the data
% prior to saving to the imExp structure.

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ImExpMaker_OpeningFcn, ...
                   'gui_OutputFcn',  @ImExpMaker_OutputFcn, ...
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
function ImExpMaker_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ImExpMaker (see VARARGIN)

% Choose default command line output for ImExpMaker
handles.output = hObject;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%% CREATE A GUI STATE STRUCTURE %%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Define the state as a global variable so that it can be shared between
% functions that also declare 'state' to be global
global state

% Call the ImExpMakerInit function to instatiate the state structure
state = ImExpMakerInit();

%%%%%%%%%%%%%%%% SET USER DEFINED INIT FILE GUI OPTIONS %%%%%%%%%%%%%%%%%%%
% Set the channel to display
set(handles.chToDisplayBox,'String',num2str(state.chToDisplay));
% set the initial scale factor
set(handles.scaleFactor,'string', num2str(state.scaleFactor));
%set the channels to be saved
set(handles.chsToSaveBox,'String', num2str(state.chsToSave));
% set the channels to motion correct
set(handles.chsToCorrectBox,'String',mat2str(state.chsToCorrect));
% set the channel of the encoder to save
set(handles.saveEncoderBox,'String',mat2str(state.saveEncoder));
% set the encoder offset
set(handles.encoderOffset,'String',num2str(state.encoderOffset));
% set the encoder threshold
set(handles.encoderThreshold,'String',num2str(state.encoderThreshold));
% set the encoder percentage
set(handles.encoderPercentage,'String',num2str(state.encoderPercentage));

% Update handles structure
guidata(hObject, handles);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%% RETURN HANDLES STRUCTURE OUTPUT ARGS (GUIDE AUTOCODE) %%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function varargout = ImExpMaker_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.guiFigure = hObject;
% Get default command line output from handles structure
varargout{1} = handles.output;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%% LOAD BUTTON CALLBACK %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function loadButton_Callback(hObject, eventdata, handles)
% Declare state variable to be global for this function
global state
% When the user selects the load button we need to perform the following
% operations
% 1. call uigetfile to allow the user to select a set of stimulus files and
%    places these names into the stimFileNames box
% 2. call stimImageMatcher to autoLocate the corresponding tiff files and
%    place the names of these tiff files in the imageStacks box
% 3. If the tiff Files were successfully loaded then we will display the
%    first image in the tiff stack for trigger one of the 1st stimulus file
% 4. draw the stimTiming information to the stimTiming axis
% 5. fill out the stimInformation box with the trigger information
% 6. update the frameNumber of the image to one
% 7. update the slider controls

% call uigetFile to load user selected stimulus files and return back
% stimulus path
[stimFileNames, PathName] = uigetfile(state.stimFileLoc,...
                                            'MultiSelect','on');
                                        
% uigetfile will return a string or cell array of strings depending
% on whether the user selected one file or many. We must cast single files
% as cell arrays so that they display properly in the imageFileNamesBox
if isstr(stimFileNames)
    stimFileNames = {stimFileNames};
end

% Place the stimFileNames in the stimFileNames box
set(handles.stimFileNamesBox,'string', stimFileNames);

% call the stimImageMatcher to locate and the corresponding image files and
% pathNames
[imageFileNames,missingStacks,imagePath] = stimImageMatcher(stimFileNames);

% If missingStacks is empty (i.e. all files located) then display to
% imageFileNames box
if isempty(missingStacks)
    set(handles.imageFileNamesBox,'string', imageFileNames);
else error('Halting execution: Tiff Files Not Found')
end

% add the image and stimFileNames to the state structure
state.imageFileNames = get(handles.imageFileNamesBox,'String');
state.stimFileNames = get(handles.stimFileNamesBox,'String');

% now set the missing triggers to be a cell of 0's the size of
% stimFileNames
missingTriggers = cell(1,numel(state.stimFileNames));
state.missingTriggers = cellfun(@(t) [0], missingTriggers,'UniformOut',0);
assignin('base','state',state)

% set the current stimFile active to be the first one in the stimFileNames
% list box
state.stimFileName = state.stimFileNames{1};
% and the same for the current image file
state.imageFileName = state.imageFileNames{1};

% place the image path into state
state.imagePath = imagePath;

% fill out the stimInformation box with stimulus particualars os
% state.stimFileName by calling dispStimInfo and set the handles to the
% stimInfoText box
stimInfoString = dispImStimInfo(state.stimFileName,...
    state.triggerNumber);
set(handles.stimInfoText,'String', stimInfoString)

% Call tiffLoader to load the first tiff file and display to the tiff image
% axis using dispTiff
[state.stackExtrema, state.tiffCell] =  tiffLoader(state.imagePath,...
                                                   state.imageFileName,...
                                                   state.chToDisplay);

% call dispTiff and make sure we get the right axes
% to display to.
axes = handles.tiffImage;
% call dispTiff to this axes
dispTiff(axes, state.tiffCell{state.chToDisplay},...
    state.stackExtrema{state.chToDisplay}, 1, state.scaleFactor);

% Now that we have a tiff stack loaded we can set
% all the slider controls that will allow us to step through each image
% of the stack. We will need to calculate the sliders min, max, and
% stepSize
sliderMin = 1;
%The slider maximum will be the number of images in the current tiff
%stack
sliderMax = size(state.tiffCell{state.chToDisplay},3);
% We set the major and minor steps of the slider to be equal
sliderStep = ([1,1]/(sliderMax-sliderMin));

% update the slider gui controls by setting handles
set(handles.slider1,'Min',sliderMin);
set(handles.slider1,'Max', sliderMax);
set(handles.slider1,'SliderStep', sliderStep);
set(handles.slider1, 'Value', sliderMin);
state.frameNum = get(handles.slider1,'Value');

% Now display the stimulus timing information to the stimDisp axes
% display to correct axes
axes2 = handles.stimDisp;
dispStimTiming( state.stimFileName, state.imageFileName,...
    state.frameNum, state.imagePath, axes2);

% SET FRAME NUMBER TEXT TO FRAMENUM/NUMFRAMES calculate the total num
% of frames
numFrames = num2str(size(state.tiffCell{state.chToDisplay},3));
% set the frame text
frameText = [num2str(state.frameNum), '/', numFrames];
% set the frame text handles
set(handles.frameNumText, 'String', frameText);

% UPDATE THE HANDLES STRUCTURE TO REFLECT CHANGES
guidata(hObject, handles);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%% REMOVE BUTTON CALLBACK %%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function removeButton_Callback(hObject, eventdata, handles)
% hObject    handle to removeButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%% STIMFILENAMESBOX CALLBACK %%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function stimFileNamesBox_Callback(hObject, eventdata, handles)

global state

% When the user selects a particular stimulus file we need to do the
% following:
% 1. Call stimImageMatcher to locate all tiff files corresponding to the
% stimulus file chosen
% 2. Set the image stack to be the first stack returned from
% stimImageMatcher (i.e. the stack corresponding to trigger 1)
% 3. Set the trigger number field to one
% 4. Call dispStimInfo to display the stimulus information for trigger 1 to
% display back to the user
% 5. Call tiffLoader to load the image stack corresponding to trigger one
% with the specific channel supplied by chToDisplayBox
% 6. Call dispTiff to display this image stack to our axis
% 7. Set the slider controls to match the number of images in the stack
% 8. Call dispStimTiming to generate a plot of the stimulus and current
% frame
% 9. Set the frame number text box on the image to be the current frame

% get the index of the user selected stimulus
index = get(handles.stimFileNamesBox,'Value');
set(handles.stimFileNamesBox, 'Value',index);

% change the state structure
state.stimFileName = state.stimFileNames{index};

% Call the stimImageMatcher func. to locate all
% the image stacks corresponding to the stimulus file chosen
[imageSet, ~, imagePath] = stimImageMatcher({state.stimFileName});

% update the state structure
state.imagePath = imagePath;

% Search the listbox of all image files for imageSet{1}, the first
% image stack for the particular stimulus file chosen. Note the strfind
% call below returns back a cell of length numel(state.imageFileNames
% with a single position occuppied by a 1 (i.e. the string match) the
% rest are empty
logicCell = strfind(state.imageFileNames,imageSet{1});

% Locate the cell which is not empty (i.e. the cell with the str match)
imageListIndex = find(cellfun(@(w) ~isempty(w), logicCell));

% Set the image stack to be the stack corresponding to the first trigger
% set the handles to the imageListIndex updating the listbox value and set
% the state.imageFileName to the strmatch we found
set(handles.imageFileNamesBox,'Value',imageListIndex)
state.imageFileName = state.imageFileNames{imageListIndex};

% Now retrieve the missing triggers for this stimulus set 
 set(handles.missingTriggs,'String',num2str(state.missingTriggers{index}))


% Set the trigger to one. Because we have taken the first image
% stack from the set of stacks matching our stimulus file name, we set
% the trigger number to one
set(handles.TrigNum,'String','1')
state.triggerNumber = 1;

% Now fill the stimulus information
% text box by calling dispStimInfo and set the handles to the
% stimInfoText box
stimInfoString = dispImStimInfo(state.stimFileName,...
    state.triggerNumber);
set(handles.stimInfoText,'String', stimInfoString)

% Now that we have the 1st tiff stack that corresponds to our stimulus
% file, we are ready to load this tiff file. tiffLoader loads the
% deinterleaved images into a cell arranged by ch number 1 to 4. Only 4 chs
% are currently supported by scan image. We also return the extrema for
% each channel for later plotting
[state.stackExtrema, state.tiffCell] = ...
    tiffLoader(state.imagePath,...
    state.imageFileName,...
    state.chToDisplay);

% We will now display the tiff stack loaded in the prior line by
% calling dispTiff passing in state.channelToDisplay and asking for the
% first image in the stack (i.e. the trailing one input arg)

% Call dispTiff and make sure we get the right axes
% to display to.
axes = handles.tiffImage;
% call dispTiff to this axes
dispTiff(axes, state.tiffCell{state.chToDisplay},...
    state.stackExtrema{state.chToDisplay}, 1, state.scaleFactor);

% Now that we have a tiff stack loaded we can set
% all the slider controls that will allow us to step through each image
% of the stack. We will need to calculate the sliders min, max, and
% stepSize
sliderMin = 1;
%The slider maximum will be the number of images in the current tiff
%stack
sliderMax = size(state.tiffCell{state.chToDisplay},3);
% We set the major and minor steps of the slider to be equal
sliderStep = ([1,1]/(sliderMax-sliderMin));

% update the slider gui controls by setting handles
set(handles.slider1,'Min',sliderMin);
set(handles.slider1,'Max', sliderMax);
set(handles.slider1,'SliderStep', sliderStep);
set(handles.slider1, 'Value', sliderMin);
state.frameNum = get(handles.slider1,'Value');

% We now call dispStimTiming to show a plot of the
% visual stimulus timing and the timing of the current frame

% display to correct axes
axes2 = handles.stimDisp;
dispStimTiming( state.stimFileName, state.imageFileName,...
    state.frameNum, state.imagePath, axes2);

% Set the frame number
% calculate the total num of frames
numFrames = num2str(size(state.tiffCell{state.chToDisplay},3));
% set the frame text
frameText = [num2str(state.frameNum), '/', numFrames];
% set the frame text handles
set(handles.frameNumText, 'String', frameText);
                  
guidata(hObject, handles);
%%%%%%%%%%%%%%%%%%%%%%%%%% END STIMFILENAMES CALLBACK %%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%% IMAGEFILENAMESBOX CALLBACK %%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function imageFileNamesBox_Callback(hObject, eventdata, handles)
% The imageFileNamesBox is 'inactive' to the user becasue the tiff stack is
% determined by the stimulus and the trigger number uniquely so no choice
% is left available to the user
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%% MISSING TRIGGERS CALLBACK %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function missingTriggs_Callback(hObject, eventdata, handles)
global state
% We will have the user enter the missing triggers and save them to state
% variable so that later analysis can occur with this info in hand
missedOfThisStim = str2num(get(handles.missingTriggs,'String'));
% now we will convert the missed triggers for this stimulus set to a cell
% array
stimIndex = get(handles.stimFileNamesBox,'Value');
state.missingTriggers{stimIndex} = missedOfThisStim;
assignin('base','state',state)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%% TRIGGER NUMBER CALLBACK %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function TrigNum_Callback(hObject, eventdata, handles)
global state

% When the user enters a new trigger number, we need to do the following
% 1. Locate the corresponding image stack for the trigger and update
% 2. Call dispStimInfo to update the stimulus information passed to user
% 3. Call tiffLoader to load the selected image stack
% 4. Call dispTiff to display the image stack to the figure
% 5. Call dispStimTiming to display the stimulus for the trigger

% Save the new trigger to state
state.triggerNumber = str2double(get(handles.TrigNum,'String'));


% call displayStimInfo to display the stimulus information for this trigger
stimInfoString = dispImStimInfo(state.stimFileName, state.triggerNumber);
    set(handles.stimInfoText,'String', stimInfoString)
    
% Use stimImageMatcher to locate the corresponding stack
imageStacks = stimImageMatcher({state.stimFileName});
% now get the stack for the trigger selected
imageStack = imageStacks{state.triggerNumber};

% use strfind to locate imageSet{1} amongst all the image fileNames in the
% list box. Note this returns back a cell
logicCell = strfind(state.imageFileNames, imageStack);

% locate the index of the logic cell where this image stack is located
imageListIndex = find(cellfun(@(w) ~isempty(w), logicCell));

% set the handles and update the state strutcture
set(handles.imageFileNamesBox,'Value',imageListIndex)
state.imageFileName = state.imageFileNames{imageListIndex};

% Call tiffLoader to load the image stack for the specified channel
% we save the tiffCell to the state sttructure so other callbacks such as
% the slider1 callback have access to it without reloading the tiffs again
[state.stackExtrema, state.tiffCell] = tiffLoader(state.imagePath,...
                                         state.imageFileName,...
                                         state.chToDisplay);

% make sure we get the right axes to imshow to
axes = handles.tiffImage;

% Call dispTiff to display the stack for the specified channel and scale
% factor
dispTiff(axes, state.tiffCell{state.chToDisplay}, ...
         state.stackExtrema{state.chToDisplay}, 1, state.scaleFactor);

% Set the slider control to the first image in the new stack
set(handles.slider1, 'Value', 1);

% Set the frame number to one
state.frameNum = 1;

% Call dispStimTiming to show the stimulus timing for the new trigger entry 
axes2 = handles.stimDisp;
dispStimTiming( state.stimFileName, state.imageFileName, state.frameNum,...
                         state.imagePath, axes2)
                     
% Set the frame number as frameNum/numFrames                   
numFrames = num2str(size(state.tiffCell{state.chToDisplay},3));
frameText = [num2str(state.frameNum), '/', numFrames];          
set(handles.frameNumText, 'String', frameText);

% Update the handles to reflect all changes to gui
guidata(hObject, handles);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%% SLIDER CALLBACK %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function slider1_Callback(hObject, eventdata, handles)

global state
% When the slider is pressed, we want to perform three operations.
% 1. Call DispTiff to show the new image in the stack
% 2. Call dispStimTiming with a new frameNumber argument to update position
%    of frame in the plot
% 3. Update the frame text number

% make sure we get the right axes to imshow to
axes = handles.tiffImage;

% get the new frameNumnber and save to state round here to make sure the
% frame number is an integer since it wil be a subsript of the image stack
state.frameNum = round(get(handles.slider1,'Value'));

% Call dispTiff to display the image for this frame number and scaleFactor
dispTiff(axes, state.tiffCell{state.chToDisplay},...
            state.stackExtrema{state.chToDisplay},...
            state.frameNum, state.scaleFactor);
                    
% Call dispStimTiming to update the frame position in the plot
axes2 = handles.stimDisp;
dispStimTiming( state.stimFileName, state.imageFileName, state.frameNum,...
                         state.imagePath, axes2);

% Update the frame Text string
numFrames = num2str(size(state.tiffCell{state.chToDisplay},3));
frameText = [num2str(state.frameNum), '/', numFrames];          
set(handles.frameNumText, 'String', frameText);
                     
% update handles to reflect all changes to the gui
guidata(hObject, handles);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%% CH TO DISPLAY CALLBACK %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function chToDisplayBox_Callback(hObject, eventdata, handles)
global state
% When the chToSisplay is changed, we need to do the following
% 1. Call tiffLoader to create a new tiffCell for the new channel selected
% 2. Call dispTiff to show the first image in the stack for this new ch
% 3. Update the frame number text to one
% 4. Update the dispStimTiming so that the frame shadow snaps to frame one
% 5. Update the value of the slider to one

% get the new channel and save to state
state.chToDisplay = str2double(get(handles.chToDisplayBox,'String'));
                                     
% When we change the ch to display, we must call tiffLoader again because
% it only calls 1 ch to display at a time so it the tiff cell only contains
% one ch.
[state.stackExtrema, state.tiffCell] = tiffLoader(state.imagePath,...
                                         state.imageFileName,...
                                         state.chToDisplay);
                                     
% make sure we get the right axes to imshow to
axes = handles.tiffImage;

% Call dispTiff to show the first image of the stack for the new chaanel
dispTiff(axes, state.tiffCell{state.chToDisplay},...
         state.stackExtrema{state.chToDisplay}, 1, state.scaleFactor)
                    
% Set the slider value to one
set(handles.slider1, 'Value', 1);

% Set the frame number to one
state.frameNum = 1;
numFrames = num2str(size(state.tiffCell{state.chToDisplay},3));
frameText = [num2str(state.frameNum), '/', numFrames];          
set(handles.frameNumText, 'String', frameText);


% Call dispStimTiming to display the first frame on the stim Plot
axes2 = handles.stimDisp;
dispStimTiming( state.stimFileName, state.imageFileName, state.frameNum,...
                         state.imagePath, axes2)

                     
% Update handles to reflect all changes made to the gui
guidata(hObject, handles);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%% SCALE FACTOR CALLBACK %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function scaleFactor_Callback(hObject, eventdata, handles)
global state
% When the user selects a new scale factor for the display of images we
% need to do the following
% 1. save the new scale Factor to state
% 2. call dispTiff to redisplay the current image with the new scale factor 
state.scaleFactor = str2double(get(handles.scaleFactor,'string'));
% make sure we get the right axes to imshow to
axes = handles.tiffImage;
% redisplay the current image with new scaleFactor
dispTiff(axes, state.tiffCell{state.chToDisplay},...
         state.stackExtrema{state.chToDisplay}, state.frameNum,...
         state.scaleFactor)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%% CHS TO SAVE CALLBACK %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function chsToSaveBox_Callback(hObject, eventdata, handles)
global state
% When the user changes the chsToSave, we simply need to get the new value
% for passing to imExpMaker, the function that will create our imExp
state.chsToSave = str2num(get(hObject,'String'));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%% SAVE ENCODER CALLBACK %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function saveEncoderBox_Callback(hObject, eventdata, handles)
global state
state.saveEncoder = str2num(get(hObject,'String'));
% When the user changes the SaveEncoder, we need to get the new value
% for passing to imExpMaker, the function that will create our imExp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%% CHS TO CORRECT CALLBACK %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function chsToCorrectBox_Callback(hObject, eventdata, handles)
global state
% When the user changes the chsToCorrect, we need to get the new value
% for passing to imExpMaker, the function that will create our imExp
state.chsToCorrect = str2num(get(hObject,'String'));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%% ENCODER OFFSET CALLBACK %%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function encoderOffset_Callback(hObject, eventdata, handles)
global state
% When the user selects a new offset for the encoder ch we need to modify
% state
state.encoderOffset = str2num(get(handles.encoderOffset,'String'));
% Update handles to reflect all changes made to the gui
guidata(hObject, handles);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%% ENCODER THRESHOLD CALLBACK %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function encoderThreshold_Callback(hObject, eventdata, handles)
global state
% When the user selects a new threshpld for the encoder ch we need to
% modify state
state.encoderThreshold = str2num(get(handles.encoderThreshold,'String'));
% Update handles to reflect all changes made to the gui
guidata(hObject, handles);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%% ENCODER PERCENTAGE CALLBACK %%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function encoderPercentage_Callback(hObject, eventdata, handles)
global state
% When the user selects a new percentage for the encoder ch we need to
% modify state
state.encoderPercentage = str2num(get(handles.encoderPercentage,'String'));
% Update handles to reflect all changes made to the gui
guidata(hObject, handles);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%% IMAGING DEPTH CALLBACK %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function imagingDepth_Callback(hObject, eventdata, handles)
global state
% When the user enters an imaging depth we want to save this to state
state.imagingDepth = str2num(get(handles.imagingDepth,'String'));
% Update handles to reflect all changes made to the gui
guidata(hObject, handles);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%% SAVE BUTTON CALLBACK %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function saveButton_Callback(hObject, eventdata, handles)
global state
% When the user presses the saveButton, we need to perform the following
% operations
% 1. pass state structure to the imExpCreator
% 2. call imExpSaverFunc to save the imExp to dirInfo.imExpLoc

% call imExpCreator to perform motion correction if selected and create an
% imExp (NOTE!!! in imExpCreator the motion correction code will destroy
% the state variable so no more references can be made to state, This is an
% error in the java turboReg code. The code is ~10,000 lines and I could
% not locate the deletion point)
imExp = imExpCreatorV2(state);

stimFileNames = get(handles.stimFileNamesBox,'string');
% call imExpSaverFunc to save the imExp to imExpRawLoc
imExpSaverFunc(stimFileNames, [], imExp, 'raw')

guidata(hObject,handles);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
%$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
%$$$$$$$$$$$$$$$$$$$$$$$$ END OF USED CALLBACKS $$$$$$$$$$$$$$$$$$$$$$$$$$$
%$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
%$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%% UNUSED CALLBACKS %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function stimInfoText_Callback(hObject, eventdata, handles)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%% CREATE FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Executes during object creation, after setting all properties.
function stimInfoText_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,...
        'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function slider1_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,...
        'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

% --- Executes during object creation, after setting all properties.
function imageFileNamesBox_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,...
        'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function stimFileNamesBox_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,...
        'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function TrigNum_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,...
        'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function tiffImage_CreateFcn(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function chToDisplayBox_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,...
        'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function chsToSaveBox_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,...
        'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function saveEncoderBox_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,...
        'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function chsToCorrectBox_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,...
        'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function scaleFactor_CreateFcn(hObject, eventdata, handles)
% hObject    handle to scaleFactor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,...
        'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function encoderOffset_CreateFcn(hObject, eventdata, handles)
% hObject    handle to encoderOffset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function encoderThreshold_CreateFcn(hObject, eventdata, handles)
% hObject    handle to encoderThreshold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function encoderPercentage_CreateFcn(hObject, eventdata, handles)
% hObject    handle to encoderPercentage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function missingTriggs_CreateFcn(hObject, eventdata, handles)
% hObject    handle to missingTriggs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,...
        'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function imagingDepth_CreateFcn(hObject, eventdata, handles)
% hObject    handle to imagingDepth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
