function addDroppedStacks(ExpTypes)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

%%%%%%%%%%%%%%%% LOAD DIR INFORMATION AND SAVE TO STATE %%%%%%%%%%%%%%%%%
% We need to tell the gui where it can locate the experiments. This info is
% stored in ImExpDirInformation.m
ImExpDirInformation;

switch ExpTypes{1}
    case 'raw'
        imExpRawFileLoc = dirInfo.imExpRawFileLoc;
        %Load
        [imExpName, PathName] = uigetfile(imExpRawFileLoc,...
                                            'MultiSelect','off');
    case 'roi'
        imExpRoiFileLoc = dirInfo.imExpRoiFileLoc;
        %Load
        [imExpName, PathName] = uigetfile(imExpRoiFileLoc,...
                                            'MultiSelect','off');
    case 'analyzed'
        imExpAnalyzedFileLoc = dirInfo.imExpAnalyzedFileLoc;
        %Load
        [imExpName, PathName] = uigetfile(imExpAnalyzedFileLoc,...
                                            'MultiSelect','off');
end

% load the exp with the dropped stacks loading only the dropped stack
% structure for speed
msgbox('Please select the imExp with the Dropped Stacks')
loadMsg = msgbox('LOADING IMEXP: Please Wait...');
% now load the imExp using full-file to construct path\fileName
imExp = load(fullfile(PathName,imExpName));
close(loadMsg)

end

