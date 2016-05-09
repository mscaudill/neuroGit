function initState = stimGenInit(~)
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
% StimGenInit is a function that initializes the stimGen gui with user
% defined options. This file should be edited for each user/Rig

% Set the user of this rig
initState.user = 'MSC';

% Set the defualt stimulus 
initState.defaultStimType = 'Gridded Grating';

% List all the stimulus types
initState.defaultStimTypes = {'Full-field Flash',...
                        'Radially Moving Bar',...
                        'Full-field Drifting Grating',...
                        'Masked Grating',...
                        'Gridded Grating',...
                        'Annular Center-surround Grating',...
                        'Simple Center-surround Grating',...
                        'Gauss Simple Center-surround Grating',...
                        'Single Angle CS',...
                        'Mouse Controlled Dot',...
                        'Mouse Controlled Bar',...
                        'Mouse Controlled Grating',...
                        'Mouse Controlled White Noise Box'};


% Set the default table matching the above stimulus
initState.defaultTable = ...
    StimGenDefaultTable('Gridded Grating');

% Set the tag
initState.tag = '';
% Set the default trial state (1 = true (save) 0 = false (don't save)
initState.saveTrials = 1;

end

