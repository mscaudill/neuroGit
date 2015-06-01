function addCellType(~)
%This function opens an imExp in order to add cell types. It assumes all
%cells are pyramidals

%%%%%%%%%%%%%%%% LOAD DIR INFORMATION AND SAVE TO STATE %%%%%%%%%%%%%%%%%
% We need to tell the gui where it can locate the experiments. This info is
% stored in ImExpDirInformation.m
ImExpDirInformation;
imExpRoiFileLoc = dirInfo.imExpRoiFileLoc;

% Call uigetfile (built-in) to select the imExp and get path to file
[imExpName, PathName] = uigetfile(imExpRoiFileLoc,...
                                            'MultiSelect','off');
                                        
% Now perform the loading and open a dialog box to relay to user
loadMsg = msgbox('LOADING IMEXP: Please Wait...');
% now load the imExp using full-file to construct path\fileName
imExp = load(fullfile(PathName,imExpName));
close(loadMsg)

roiSets = imExp.rois;

for roiSet=1:numel(roiSets)
    for roi=1:numel(roiSets{roiSet})
        cellTypes{roiSet}{roi} = 'pyr';
    end
end

imExp.cellTypes = cellTypes;

imExpSaverFunc([], imExpName, imExp, 'roi')
end

