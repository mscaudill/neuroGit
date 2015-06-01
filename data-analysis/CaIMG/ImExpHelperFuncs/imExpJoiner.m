function imExpJoiner(~)
%imExpJoiner uses uigetfile to allow the user to select imExps they would
%like to join together. One reason they may want to do this is to perform
%motion correction on smaller files (i.e. faster) and then join them later
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
% INPUTS:           NONE
% OUTPUTS:          uiputfile for saving

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%% IMEXP DIR INFORMATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ImExpDirInformation;
imExpFileLoc = dirInfo.imExpRawFileLoc;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%% LOAD IMEXPS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% call uigetFile to load user selected imExp files and return back
% imExp path
[imExpFileNames, pathName] = uigetfile(imExpFileLoc,...
                                            'MultiSelect','on');
try
    %%%%%%%%%%%%%%%%%%%%%% CREATE WAITBAR TO RELAY PROGRESS %%%%%%%%%%%%%%%
    h = waitbar(0,'Loading imExps, Please Wait...',...
        'CreateCancelBtn','setappdata(gcbf,''canceling'',1)');
    
    setappdata(h,'canceling',0)
    
    breakOut = 0;
    
    for file  = 1:numel(imExpFileNames)
        % Check for cancel press
        if getappdata(h,'canceling')
            breakOut = 1;
            break
        end
        
        imExps{file} = load(fullfile(pathName,imExpFileNames{file}));
        
        % update the wait bar progress REPORT CURRENT ESTIMATE IN THE
        % WAITBAR'S MESSAGE FIELD
        waitbar(file/numel(imExpFileNames),h, sprintf('%s',...
            ['Loading imExps: ',...
            num2str(file), ' of ' num2str(numel(imExpFileNames)),...
            ' Completed']));
    end
    
    % Delete waitbar if cancel pressed and throw error
    if breakOut == 1;
        delete(h)
        error('LoadFailure:imExpsNotLoaded', 'User canceled load')
    end
    
catch MEload % load error
    throw(MEload)
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%% JOIN IMEXPS (STRUCTJOINER) %%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% call the function structJoiner to create our combined imExp
combinedImExp = structJoiner(imExps);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%% CONSTRUCT DEFAULT NAME FOR COMBINED EXP %%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%2013-1-22_loc1orientation_imExp

% split the stimFileName on the underscores returning an allStrings cell
% array
allStrings = regexp(imExpFileNames{1},'_', 'split');
% obtain the date
date = allStrings{1};
% obtain the location and expType identifier
locExpType = allStrings{2};

defaultName = [imExpFileLoc, date,'_',locExpType,'_','imExp_Combined',...
               '.mat'];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
           
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%% CONSTRUCT PATH AND FILE NAME %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Use uiputfile to allow user to save to a directory of their choice
% suggesting the default name as the save name (note they can overide with
% their own name if they wish)
[fileName,pathName] = uiputfile(imExpFileLoc,'Save As',defaultName);

file = fullfile(pathName,fileName);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% SAVE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ischar(fileName) && ischar(pathName) && breakOut==0;
    saveMsg = msgbox('SAVING: Please Wait...');
    save(file, '-struct', 'combinedImExp', '-v7.3');
    close(saveMsg)
else
    warndlg('WARNING: EXPERIMENT NOT SAVED')
    if (exist('h','var')==1)
        delete(h)
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
           

end

