function addImagingDepth(depth,ExpType)
% This function opens and imExp_rois and adds the field cellDepth to the
% structure using the user inputted depth. It can accept any if the
% expTypes (i.e. raw, roi, or analyzed

%%%%%%%%%%%%%%%% LOAD DIR INFORMATION AND SAVE TO STATE %%%%%%%%%%%%%%%%%
% We need to tell the gui where it can locate the experiments. This info is
% stored in ImExpDirInformation.m
ImExpDirInformation;
switch ExpType
    case 'raw'
        %TBD
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Now perform the loading and open a dialog box to relay to user
loadMsg = msgbox('LOADING IMEXP: Please Wait...');
% now load the imExp using full-file to construct path\fileName
imExp = load(fullfile(PathName,imExpName));
close(loadMsg)

% Add depth field
imExp.imagingDepth = depth;

% and resave the imExp using the type supplied 
imExpSaverFunc([], imExpName, imExp, ExpType)

end

