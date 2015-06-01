function varargout = tiffViewer(varargin)
% TIFFVIEWER MATLAB code for tiffViewer.fig allows the user to load images
% or stacks from their raw collected imaging data and perform basic
% functions and analysis similar to imageJ.
%
% Last Modified by GUIDE v2.5 26-Feb-2014 16:09:50
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
                   'gui_OpeningFcn', @tiffViewer_OpeningFcn, ...
                   'gui_OutputFcn',  @tiffViewer_OutputFcn, ...
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

function tiffViewer_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to tiffViewer (see VARARGIN)

% Choose default command line output for tiffViewer
handles.output = hObject;

%%%%%%%%%%%%%%%%%%%%%%%%% CREATE A GUI STATE STRUCTURE %%%%%%%%%%%%%%%%%%%%
% We here create a state structure that holds parameters needed for each 
% callback within the gui. It is initialized in a separate file called
% tiffViewerInitFile. We declare it to be global to all functions within
% this file.
global viewerState
viewerState = tiffViewerInitFile;

% Update handles structure
guidata(hObject, handles);

%%%%%%%%%%%%%%%%%%% CREATE GUI OUTPUT ARGS FROM THE GUI %%%%%%%%%%%%%%%%%
function varargout = tiffViewer_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%% FILE MENU CALLBACKS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function fileMenu_Callback(hObject, eventdata, handles)

% --------------------------------------------------------------------
function open_fileMenu_Callback(hObject, eventdata, handles)
% On user selected open choice, we need to use uigetFile to obtain the path
% and fileName of the desired image stack to be loaded and call the
% tiffloader to load the stack and its associated extrema. We will load the
% stack to a set of tiffCells and stackExtremas initialized in the init
% file. These set comprises all user opened tiff files.

% Set viewer state as global to this function
global viewerState

% get the size of the tiffCell and stackExtremas cell arrays since the user
% may have already opened a file prviously
numFiles = numel(viewerState.tiffCells);

% call uigetFile and retrieve fileName and path of the image to be loaded
[viewerState.currentImageFileName,viewerState.currentPathName] =...
                            uigetfile([viewerState.imageFileLoc,'\*'],...
                                        'MultiSelect', 'off');
                                    
% call the tiffLoader using the chsAcquired specified in the init file and
% load to the set of tiffCells and stackExtremas in viewerState
[viewerState.stackExtremas{numFiles+1},...
    viewerState.tiffCells{numFiles+1}] =...
                           tiffLoader(viewerState.currentPathName,...
                                      viewerState.currentImageFileName, ...
                                      viewerState.chsAcquired);

% call the createImageFigure function to create our figure for this file
createImageFigure(viewerState);

assignin('base','viewerState',viewerState)


% --------------------------------------------------------------------
function close_fileMenu_Callback(hObject, eventdata, handles)
% hObject    handle to close_fileMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function closeAll_fileMenu_Callback(hObject, eventdata, handles)
% hObject    handle to closeAll_fileMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function saveAs_fileMenu_Callback(hObject, eventdata, handles)
% hObject    handle to saveAs_fileMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function pageSetup_fileMenu_Callback(hObject, eventdata, handles)
% hObject    handle to pageSetup_fileMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function print_fileMenu_Callback(hObject, eventdata, handles)
% hObject    handle to print_fileMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function quit_fileMenu_Callback(hObject, eventdata, handles)
% hObject    handle to quit_fileMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
