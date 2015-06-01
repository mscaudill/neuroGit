function [ stimFileNames, missingStimFileNames ] =...
                                           stimDataMatcher(...
                                             dataFileNames, fileType )
%STIMDATAMATCHER takes in a cell array of data filenames and returns back
%a cell array of stimulus filenames. This is useful for matching data files
%(*.daq) with stimulus files (*.mat) for analysis in the ExpMaker gui. Note
%if the function fails to find the corresponding stimulus files it will
%return a message to the user and allow them to select the files by hand.
%
%INPUTS:   dataFileNames is a cell array of data file names
%          fileType, the data file type, currently supports .daq and .abf
%
%OUTPUTS:  stimFileNames is a cell array of corresponding stimulus file
%          names
%          missingStimFileNames is a cell array of stimulus files that the
%          program failed to find
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
% dataFileNames=...
%     {'MSC_2014-02-14_s1gratings_4.daq',...
%     'MSC_2012-06-29_n1ffgrating_5999.daq'};
% dataFileNames = ...
%     {'2014_09_04_s1fgrating_008.abf',...
%     '2014_09_04_s1fgrating_0010.abf',...
%     '2014_09_04_s1fgrating_128.abf'};
    
% Below is an example of the stimulus file names we are looking for
% MSC_2012-6-29_n1ffgrating_3_TrialsStruct
% NOTE THE MISSING ZERO
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Directory information where the stimulus files are stored
electroExpDirInformation;
% Get the directory structure array for the StimFileLoc
StimFile = dir(eDirInfo.StimFileLoc);
% List all names in the stimulus directory
names = {StimFile(:).name};

% initialize missingFileName cell array
missingStimFileNames = {};

for fileName = 1:numel(dataFileNames)
    % Get the string token breaking on dot delimiter of the daq/abf files
    token = strtok(dataFileNames{fileName},'.');
    
    % if the fileType is abf then we need to add the user to the beginning
     if strcmp(fileType,'abf')
        token = ['MSC_',token];
     end
     
     % use the '_' and '-' delimeters to get all parts of the string
     % independent of file type
     splitFileName = strsplit(token,{'_','-'});
     
    % the stimulus file dates do not have zeros in them (ex 2014-09-08) so
    % we must remove these. They will occur only in elements 3 and 4 (i.e.
    % the month and day. We do this replacement only if 0 preceeds another
    % number (i.e. we exclude the cases 10,20,30 etc. these 0s remain
    if strcmp(splitFileName{3}(1),'0')
        splitFileName{3} = strrep(splitFileName{3},'0','');
    end
    
    if strcmp(splitFileName{4}(1),'0')
        splitFileName{4} = strrep(splitFileName{4},'0','');
    end
    
    % rejoin the split fileName. The dates are separated with '-' while the
    % rest of the elements are separated with a '_';
    token = strjoin(splitFileName,{'_','-','-','_','_'});
    
    % Now make the token into a stimFileName
    token = [token, '_', 'Trials','.mat'];
    
    % Determine if the token exist in the stimulus file directory
    if any(strcmp(token,names))
        % if so then add to out stimFileName cell array
        stimFileNames{fileName}=token;
    else stimFileNames{fileName} = 'NOT FOUND';
        % otherwise set the stimFileName to Not found and include in the
        % missing list to be passed back to user
         missingStimFileNames=[missingStimFileNames, token];
    end
end
% Throw an error dialog to the user if stimFiles are not found and ask them
% to rename
if ~isempty(missingStimFileNames)
    missingStimFileNames=[ '**PLEASE RENAME FILES**',missingStimFileNames];
    errordlg(missingStimFileNames,'ExpMaker Could Not Find:')
end
    
return


