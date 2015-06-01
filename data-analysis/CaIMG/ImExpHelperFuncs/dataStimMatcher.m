function [ dataFileNames, missingDataFileNames ] =...
                                           dataStimMatcher( stimFileNames )
% DATASTIMMATCHER takes in a cell array of stimulus fileNames and returns
% back a cell array of data (*.daq) fileNames that match. It is the
% companion function to stimDataMatcher.m which performs the opposite
% operation. It is currently used solely by imExpCreator to add the encoder
% ch into the imExp structure given a set of stimulus files.  Note
% if the function fails to find the corresponding data files it will
% return a message to the user and allow them to select the files by hand.
%
% INPUTS:          stimFileNames:        a cell array of stimulus
%                                        fileNames
% OUTPUTS:         dataFileNames:        cell array of dataFileNames
%                                        corresponding to the stimFileNames
%                  missingStimFileNames: a cell array of data 
%                                        files that the program failed to 
%                                        find
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

%%%%%%%%%%%%%%%%%%%%%%%%%% TESTING FILENAMES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Below is a sample list of stimulus file names we want to find matches for
% stimFileNames = {'MSC_2012-9-20_n4orientation_5_Trials',...
%                  'MSC_2012-9-20_n4orientation_6_Trials',...
%                  'MSC_2012-9-20_n4orientation_7_Trials',...
%                  'MSC_2012-9-20_n4orientation_99_Trials'};
%              
% we are specifically loooking for daq files of the form
% MSC_2012-09-20_n4orientation_5.daq ## NOTE THE ADDED ZERO IN DATE ##
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%% LOAD DIRECTORY INFORMATION %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ImExpDirInformation;
daqFileLoc = dirInfo.daqFileLoc;

%obtain all the daq FileNames in the daqFileLoc
daqFileDir = dir(daqFileLoc);
daqFileNames = {daqFileDir(:).name};
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% initialize missingFileName cell array
missingDataFileNames = {};

for fileName = 1:numel(stimFileNames)
    stimFileName = stimFileNames{fileName};
    underscores = strfind(stimFileName,'_');
    
    % get the user (appears before first underscore
    user = stimFileName(1:underscores(1)-1);
    
    % get date (is between first two underscores)
    date = stimFileName(underscores(1)+1:underscores(2)-1);
    % Check that date contains zeros before single digits
    formatIn = 'yyyy-mm-dd';
    dateNumber = datenum(date,formatIn);
    formatOut = 'yyyy-mm-dd';
    date = datestr(dateNumber,formatOut);
    
    % get the cellInfo (e.g. n4orientation_6). It appears
    % between underscores 2 and 4
    cellInfo = stimFileName(underscores(2)+1:underscores(4)-1);
    
    % Construct a daqFileName to search for in daqFileLoc
    daqName = [user, '_', date, '_', cellInfo, '.daq'];
    
    if any(strcmp(daqName, daqFileNames))
        % if so then add to outgoing daqFileName cell array
        dataFileNames{fileName} = daqName;
        
    else dataFileNames{fileName} = 'NOT FOUND';
        % otherwise set the dataFileName to Not found and include in the
        % missing list to be passed back to user
         missingDataFileNames = [missingDataFileNames, daqName];
    end
end

% Throw an error dialog to the user if dataFiles are not found and ask them
% to rename
if ~isempty(missingDataFileNames)
    missingStimFileNames=[ '**PLEASE RENAME FILES**',missingDataFileNames];
    errordlg(missingDataFileNames,'imExpMaker Could Not Find:')
end
    
return
