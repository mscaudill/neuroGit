function trial = dispStimInfo(Exp,fileNames, fileName, triggerNumber )
%dispStimInfo retrieves stimulus information from an experiment in the base
%workspace to display to the ExpMaker gui. This will allow the gui user to
%see the stimulus information for each file. We use evalc to capture the
%information
%INPUTS                         : Exp, structure of experiment from
%                                 expMakerGui
%                               : fileNames, list of fileNames passed from
%                                 the state of the gui
%                               : fileName, the specific file the user is
%                                 looking at in the gui
%                               : triggerNumber the current trigger in the
%                                 gui state
% OUTPUTS                       : trial, the specific stimulus trial for
%                                 that fileName and trigger number to be...
%                                 displayed back in the gui
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

% we first locate the fileName within the string of filenames that exist in
% the experiment
fileNumber = find(not(cellfun('isempty', strfind(fileNames,fileName))));
% we now use eval to capture the character array os stimulus info to trial
trial = evalc('Exp.stimulus(fileNumber, triggerNumber)');
trial(1:18)='';

end

