function [ unitResults ] = Unit_imExpCreate(~)
% This function performs a unit test of the imExpCreate function. The
% purpose of this test is to ensure that the stimulus files and the tiff
% files are loaded & assembled into imExps correctly. We will specifically
% be looking for the following:
% Given a set of stimulus files we will make an imExp and check:
% 1. Are the set of associated dataFiles correct and positioned correctly
%    in the imExp
% 2. Do each of the stimuli files match the corresponding stimulus
%    structure in the imExp
% 3. Are the image Stacks the same as the image stacks in the imExp struct
%    and are they positioned corrently in the structure array

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%% OBTAIN INITIAL GUI STATE %%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The imExpCreate function requires one input variable called state that
% contains all the information necessary to make an imExp. We get the
% inital structure of values here.
state = ImExpMakerInit();
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%% UIGET THE STIMULUS FILES FOR THE IMEXP %%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We will ask the user to load a set of stimulus files and autolocate the
% corresponding image files and associated paths. We will save information
% to the state structure and return this in the unitResults structure

% call uigetFile to load user selected stimulus files and return back
% stimulus path
[state.stimFileNames, state.PathName] = uigetfile(state.stimFileLoc,...
                                                'MultiSelect','on');
                                        
% uigetfile will return a string or cell array of strings depending
% on whether the user selected one file or many. We must cast single files
% as cell arrays so that they display properly in the imageFileNamesBox
if isstr(state.stimFileNames)
    state.stimFileNames = {state.stimFileNames};
end

% call the stimImageMatcher to locate the corresponding image files and
% pathNames
[state.imageFileNames, ~, state.imagePath] =...
                               stimImageMatcher(state.stimFileNames);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                           
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%% MODIFY ANY STATE PARAMETERS %%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The gui state is now complete (see imExpMakerInit) and ready to be passed
% to imExpCreate except we do not want any motion correction since we want
% to compare the stacks in the imExp with the imputted tiff stacks
% directly. So we now set motion correction to false
state.chsToCorrect = [];
state.framesToDrop = [];
% Please see the init vaules in imExpMakerInit for any further
% modifications

% assign the state structure to the unitResults structure array
unitResults.inputState = state;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%% CREATE THE IMEXP STRUCTURE ARRAY %%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We now call imExpCreate to make the imExp structure that we want to test.
imExp = imExpCreate(state);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%% COMPARE INPUTTED IMAGE FILES WITH CORRECTED STACKS IN IMEXP %%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We now want to compare the inputted image files with the corrected stacks
% in the imExp. To do this we need to call tiffloader on the input
% tiffFiles and store all of them to a cell array
[~,inputTiffs] = cellfun(@(x)...
                    tiffLoader(state.imagePath, x, state.chsToSave),...
                    state.imageFileNames,'UniformOut',0);
 %%%%%% reshape the input tiffs to a single cell array

% now we will reshape the corrected stacks in the imExp and extract the
% channel(s) saved for comparing with

% We first need to rotate the imExpCorrected stacks since rows are read
% before cols in matlab
rotStacks = imExp.correctedStacks';
% now we will extract the chsToSave and save to a cell array
outputTiffs = {rotStacks(:,:).Ch2};

% now we will do a subtraction of the output and input tiffs and return the
% max. If they are the same the max should be 0. Note we will flatten the
% input and output stacks to speed up
for stack = 1:numel(inputTiffs)
    stackDiffs(stack) = max([outputTiffs{stack}(:)]-...
                                [inputTiffs{stack}{state.chsToSave}(:)]);
end
unitResults.stackDiffs = stackDiffs;
plot(stackDiffs);
xlabel('stack #')
ylabel('In/Out frame differences')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%% COMPARE INPUT STIM FILES WITH OUTPUT STIM STRUCT %%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We now want to compare the incoming stimulus files with the stimulus
% structure created by imExpCreate

% First we get all of the input stimstructs
for name = 1:numel(state.stimFileNames)
    % load the trials structure
    load(fullfile(state.stimFileLoc,state.stimFileNames{name}))
    % save them to a cell array
    inputTrialsCell{name} = trials;
    % clear trials to avoid confusion with next loaded trials
    clear trials
end

% reshape the input trials cell into single structure organized by file
% along rows and triggers along cols
inputStimuli = [inputTrialsCell{:}]';
% Now we want to get the trials strucutre from the imExp to compare with
outputStimuli = imExp.stimulus;

stimStructEquality = isequal(inputStimuli,outputStimuli);

unitResults.stimStructEquality = stimStructEquality;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%% CHECK THE ORDER OF THE FILENAMES %%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% As a final check we will check the order of the input stimFileNames,
% input dataFileNames against to output stimFileNames and output
% dataFileNames.
inputStimFileNames = state.stimFileNames;
inputImageFileNames = state.imageFileNames;

outputStimFileNames = {imExp.fileInfo(:).stimFileName};
outputImageFileNames = [imExp.fileInfo(:).imageFileNames];

% Save these to unitResults for inspection
unitResults.inputStimFileNames = inputStimFileNames;
unitResults.inputImageFileNames = inputImageFileNames;
unitResults.outputStimFileNames = outputStimFileNames;
unitResults.outputImageFileNames = outputImageFileNames;

% Perform equality test
unitResults.stimFileNameEquality = ...
                           isequal(inputStimFileNames,outputStimFileNames);
unitResults.imageFileNamesEquality = ...
                         isequal(inputImageFileNames,outputImageFileNames);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end