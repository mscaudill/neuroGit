function addDroppedStacks(~)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

%%%%%%%%%%%%%%%% LOAD DIR INFORMATION AND LOAD IMEXPS %%%%%%%%%%%%%%%%%%%%%
% We will have the user select two imExps. The first will contain the
% dropped frames field and the second will be either an roi or an analyzed
% exp we wish to add the dropped frames to.
ImExpDirInformation;

% Get the file and pathnames of the imExps, one contatining the dropped
% frames field ('raw') and the other where we would like to add the dropped
% frames to (presumably roi).
imExpRawFileLoc = dirInfo.imExpRawFileLoc;

[rawImExpName, rawPathName] = uigetfile(imExpRawFileLoc,...
                         'MultiSelect','off',...
                         'Please select imExp with dropped frames field');

imExpRoiFileLoc = dirInfo.imExpRoiFileLoc;
[imExpName, PathName] = uigetfile(imExpRoiFileLoc,...
                      'MultiSelect','off',...
                      'Please select an imExp to add dropped frames to.');

% Now perform the loading %
%%%%%%%%%%%%%%%%%%%%%%%%%%%

% open a dialog to tell user what is happening
loadMsg = msgbox(...
                'Loading imExp with dropped frames field: Please Wait...');
% now load the imExp using full-file to construct path\fileName, load only
% the dropped stacks field.
rawImExp = load(fullfile(rawPathName,rawImExpName),'droppedStacks');
close(loadMsg)

% extract the droppedStacks structure
droppedStacks = rawImExp.droppedStacks;

% make space for the next imExp to be loaded
clear rawImExp

% open another msg for loading the analyzed imExp. Note this will take some
% time
loadMsg = msgbox(...
             'Loading imExp without dropped frames field: Please wait...');

% now load the imExp using full-file to construct path\fileName
imExp = load(fullfile(PathName,imExpName));
close(loadMsg)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%% ADD DROPPED FRAMES STRUCT TO IMEXP %%%%%%%%%%%%%%%%%%
imExp.droppedStacks = droppedStacks;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%% SAVE MODIFIED IMEXP WITH DROPPED FRAMES %%%%%%%%%%%%%%
% Use uiputfile to allow user to save to a directory of their choice
defaultName = [imExpRoiFileLoc,imExpName];
[saveFileName,savePathName] = uiputfile(imExpRoiFileLoc,'Save As',...
                                        defaultName);

file = fullfile(savePathName,saveFileName);

%SAVE %
%%%%%%%
% Depending on the size of the imExp, we will either save the file with the
% -v7.3 switch or with -v6 (standard). This is because the -v7.3 will allow
% us to save files larger than 2GB but is unfortunately much slower.
imExpInfo = whos('imExp');

byteSize = imExpInfo.bytes;

if ischar(saveFileName) && ischar(savePathName)
    saveMsg = msgbox('SAVING: Please Wait...');
    
    if byteSize < 2.147e+9
    save(file, '-struct', 'imExp', '-v6');
    else % we do it the slower way
    save(file, '-struct', 'imExp', '-v7.3');
    end
    
    close(saveMsg)
else
    warndlg('WARNING: EXPERIMENT NOT SAVED')
end

% clean up memory space
clear imExp
