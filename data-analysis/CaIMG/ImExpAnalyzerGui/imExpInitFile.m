function state = imExpInitFile(~)
% This is the initialization file for the imExpAnalyzer gui. It defines
% initialization values for the state structure used in the gui that us
% specific to each rig.
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

%%%%%%%%%%%%%%%%%%%%%%% CREATE THE ANALYZER STATE VARIABLE %%%%%%%%%%%%%%%%
% We create a state varible that will keep track of all the options the
% user chooses within the imExpAnalyzer gui. Some of these options will
% depend on the user. This initialization file allows the user to set some
% of these options so that when the gui is loaded, their particular
% configuration is preloaded for them.

% The user can set the channel that will initially be displayed
state.chToDisplay = 2;
state.allChs = [1,2];
% user can also select the initial scale factor to display the images
state.scaleFactor = 1;
% user can select their preferred method of drawing rois, The first one
% should be the preferred one
state.drawMethod = 'Free Hand';

% user can specify an initial cell type of interest for this exp
state.initCellType = 'pyr';

% user can select the initial parameter thye want to see for each trigger.
% The first one should be the preferred one
state.stimVariable = 'Orientation';

% user can select the run state they are interested in seeing fluorescent
% traces for (0=non run, 1 = run only, 2=run and non run trials)
state.runState = 2;
% user can select the initial neuropil ratio.
state.neuropilRatio = 0.7;

% set the initial led state
state.Led = {false, 'even'};

% user can select any pre initialized notes to display with this imExp
state.notes = 'Notes';

%%%%%%%%%%%%%%%% LOAD DIR INFORMATION AND SAVE TO STATE %%%%%%%%%%%%%%%%%
% We need to tell the gui where it can locate the experiments. This info is
% stored in ImExpDirInformation.m
ImExpDirInformation;
state.imExpRoiFileLoc = dirInfo.imExpRoiFileLoc;
state.imExpRawFileLoc = dirInfo.imExpRawFileLoc;