 function imExp = imExpCreator(state)
% imExpCreator creates an experiment array of structures for a single
% cell recorded during an imaging experiment. The structure contains all
% the stimuli, images, and encoder data (if user selected) for a given cell
% across all trials of the stimulus.
%
% INPUTS:           STATE, a structure passed from the ImExpMaker gui
%                   containing, a cell array of stimFileNames
%                               a cell array of imageFileNames
%                   SAVEENCODER, a logical to indicate whether a DAQ file
%                   containing an encoder ch should be analyzed for running
%
% OUTPUTS:          IMEXP, a two dimensional array of structures of all
%                   trials indexed by run number and trigger number (e.g.
%                   imExp(runNumber, triggerNumber)
%
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%TESTING INPUTS
% state.stimFileNames = {'MSC_2012-11-27_n1orientation_13_Trials',...
%                        'MSC_2012-11-27_n1orientation_14_Trials'};
                   
% state.stimFileNames = {'MSC_2012-8-7_n3orientation_7_Trials',...
%                        'MSC_2012-8-7_n3orientation_8_Trials'};
               
% state.imageFileNames = {'n1orientation_13_131.tif',...
%                         'n1orientation_13_132.tif',...
%                         'n1orientation_13_133.tif',...
%                         'n1orientation_13_134.tif',...
%                         'n1orientation_13_135.tif',...
%                         'n1orientation_13_136.tif',...
%                         'n1orientation_13_137.tif',...
%                         'n1orientation_13_138.tif',...
%                         'n1orientation_13_139.tif',...
%                         'n1orientation_13_140.tif',...
%                         'n1orientation_13_141.tif',...
%                         'n1orientation_13_142.tif',...
%                         'n1orientation_13_143.tif',...
%                         'n1orientation_14_144.tif',...
%                         'n1orientation_14_145.tif',...
%                         'n1orientation_14_146.tif',...
%                         'n1orientation_14_147.tif',...
%                         'n1orientation_14_148.tif',...
%                         'n1orientation_14_149.tif',...
%                         'n1orientation_14_150.tif',...
%                         'n1orientation_14_151.tif',...
%                         'n1orientation_14_152.tif',...
%                         'n1orientation_14_153.tif',...
%                         'n1orientation_14_154.tif',...
%                         'n1orientation_14_155.tif',...
%                         'n1orientation_14_156.tif'};
%                     
% state.saveEncoder = [];
% state.dc_offset = 6.6;
% state.threshold = 0.5;
% state.percentage = 75;
% state.chsToSave = [2,3];
% state.chsToCorrect = [];
% state.imagePath = 'G:\data\ImagingData\11272012';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%% LOAD DIR INFORMATION %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ImExpDirInformation;
daqFileLoc = dirInfo.daqFileLoc;
stimFileLoc = dirInfo.stimFileLoc;
%imExpFileLoc = dirInfo.imExpFileLoc;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% This code is broken into two main for loops. In the first loop we will
% create three structures; a fileInfo structure containing important file
% information that will be included in the experiment such as file names
% and sampling rates, a stimulus structure containing all the trials
% information, and a behavior structure containing a running state
% information. In the second for loop we will perform motion correction and
% return a corrected images structure, an image extrema structure and and
% image offsets structure. All these structures from loop 1 and 2 will be
% combined into the imExp structure passed out by this function

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%% INITIALIZE ARRAYS, CELLS AND STRUCTS %%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% initialize cell array to hold encoder results
boolean = [];
stimulusStruct= struct([]);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%% CREATE WAITBAR TO RELAY PROGRESS %%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Creating the experiment structure may take a few seconds to run. We don't
% want the user to continue to press gui buttons as the imExp is being
% created so we will show them a waitbar
h = waitbar(0,'Creating imExp Structure Please Wait...');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%% MAIN LOOP ONE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Loop through the stimulus file names supplied in state
for name = 1:numel(state.stimFileNames)
    
    %%%%%%%%%%%%%%% ADD STIMFILENAMES TO FILEINFO STRUCT %%%%%%%%%%%%%%%%%%
    imExp.fileInfo(name,1).stimFileName = state.stimFileNames{name};
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    %%%%%%%%%%%%%%% ADD DATAFILENAMES TO FILEINFO STRUCT %%%%%%%%%%%%%%%%%%
    % call dataStimMatcher to autofind dataFiles associated with stim file
    % names passed from state. Note we only load data file names if the
    % user has elected to save the encoder ch
    if ~isnan(state.saveEncoder)
        [dataFileName, missingDataFileNames ]= dataStimMatcher(...
                                              {state.stimFileNames{name}});
                                          
        imExp.fileInfo(name,1).dataFileName = dataFileName;
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    %%%%%%%%%%%%%%% ADD TIFF FILENAMES TO FILEINFO STRUCT %%%%%%%%%%%%%%%%%
    % call stimImageMatcher to return back the tiffFileNames associated
    % with this stimulus file
    [imageFileNames, missingImageFiles, imagePath] = ...
                             stimImageMatcher({state.stimFileNames{name}});
                            
     imExp.fileInfo(name,1).imageFileNames = imageFileNames;
     imExp.fileInfo(name,1).imagePath = imagePath;
     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
     
    if isempty(missingImageFiles)
         % if there are no missing image files, then we will get image
         % informmation for the first image stack for this stimulus file
         % and get all the sampling information
         %%%%%%%%%%%%%% ADD IMAGE SAMPLING RATE TO FILEINFO STRUCT %%%%%%%%
         tiffFile = fullfile(imagePath,imageFileNames{1});
         
         % Get image info structure
         InfoImage=imfinfo(tiffFile);
         
         % We now need to get the frame rate. This is determined by scan
         % image as 1/(lines/frame * ms/line). We can get the lines/frame
         % and the ms/line from the header file Scan image is written
         % poorly, the designer saved all the aquistion info to a character
         % array. . The character array is called ImageDescription, I
         % rename to 'a' here for brevity. We will locate the strings in
         % tha character array coresponding to our variables of interest
         
         a = InfoImage(1,1).ImageDescription;
         
         % start by locating the start indices of the strings
         stringsToFind = {'state.acq.linesPerFrame','state.acq.msPerLine'};
         startIndices = [strfind(a, stringsToFind{1}),...
             strfind(a, stringsToFind{2})];
         % Now use strtok to extract the lines from 'a' using the newline
         % char(13) as the delimiter
         tokenLines = {strtok(a(startIndices(1):end),char(13)),...
             strtok(a(startIndices(2):end),char(13))};
         
         % now break each line on the equals and retrieve the remainder
         % (i.e. the number string for the variable)
         [~,linesPerFrame] = strtok(tokenLines{1},'=');
         % note we take 2:end becasue remainder also returns the equal sign
         linesPerFrame = str2double(linesPerFrame(2:end));
         
         [~, msPerLine] = strtok(tokenLines{2},'=');
         
         % note we take 2:end becasue remainder also returns the equal sign
         msPerLine = str2double(msPerLine(2:end));
         
         % Now we calculate our frame rate and time per frame
         frameRate = 1/(linesPerFrame*msPerLine/1000);
         
         imExp.fileInfo(name,1).linesPerFrame = linesPerFrame;
         imExp.fileInfo(name,1).msPerLine = msPerLine;
         imExp.fileInfo(name,1).imageFrameRate = frameRate;
     end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    %%%%%%%%%%%%%%%%%%%%% LOAD STIMULUS TRIALS STRUCT %%%%%%%%%%%%%%%%%%%%%
    load(fullfile(stimFileLoc,state.stimFileNames{name}))
    stimulusStruct = [stimulusStruct, trials];
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%%%%%%%%%%%%%%%%%% OBTAIN ENCODER CH FROM DAQ FILE %%%%%%%%%%%%%%%%%%%
    % We only perform the enoder extraction from a daq file if the user has
    % selected to save the encoder by enetering its channel number
    if ~isnan(state.saveEncoder)
        % get number of triggers for all stimuli files
        numTriggers = numel(trials);
        
        
        %%%%%%%%%%%%%%%% READ ENCODER CH FROM EACH FILE %%%%%%%%%%%%%%%%%%%
        % Call daqread to read in our data file
        origData = daqread(fullfile(daqFileLoc, dataFileName{1}),...
                        'Channels', state.saveEncoder);
        
       % Triggers are denoted by NaN's in the data so we remove these
        origData(isnan(origData(:,1)),:)=[];
       
        % reshape the data so that rows are data pts and columns are
        % triggers
        reshapedData = reshape(origData,[], numTriggers);
        
        %collect the columns into cells
        celledData = num2cell(reshapedData,1);
        
        %%%%%%%%%%%%%%%%%%%%%%%%%% CALL RUN DETECT %%%%%%%%%%%%%%%%%%%%%%%%
       boolean = [boolean, cellfun(@(x) runDetect(x,...
                                    state.encoderOffset,...
                                    state.encoderThreshold,...
                                    state.encoderPercentage), celledData)];
      
    end
    % update the wait bar progress
    waitbar(name/numel(state.stimFileNames))
end
%%%%%%%%%%%%%%%%%%%% ADD STIMULUSSTRUCT TO IMEXP %%%%%%%%%%%%%%%%%%%%%%%%%%
imExp.stimulus = stimulusStruct';

%%%%%%%%%%% IF ENCODER THEN ADD BEHAVIOR STRUCTURE TO IMEXP %%%%%%%%%%%%%%%
if ~isnan(state.saveEncoder)
    % convert the boolean array to a cell (will have 1 row X
    % (numFiles*numTriggers) cols)
    behavior = num2cell(boolean);

    % convert the behavior cell to a structure with the field of 'Running'
    % dimensions will be (numTriggers X numFiles) rows
    behavior = cell2struct(behavior,'Running',1);

    % now reshape the structure to be number of stimFiles x numTriggers
    behavior = reshape(behavior,[], numel(state.stimFileNames))';

    imExp.behavior = behavior;
    
    % also create a new field with the user supplied encoder options if the
    % encoder state is being saved
    imExp.encoderOptions.encoderOffset = state.encoderOffset;
    imExp.encoderOptions.encoderThreshold = state.encoderThreshold;
    imExp.encoderOptions.encoderPercentage = state.encoderPercentage;
end
% Close the wait bar here
close(h) 
%%%%%%%%%%%%%%%%%%%%%%%%%%%% END MAIN LOOP 1 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%% ERROR CHK THE NUMBER OF FILES %%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We want to perform a check that the number of triggers in the stimulus
% matches the number of tiff stacks. We allow the user to bypass this check
% but we will warn them
numTriggers = numel(stimulusStruct);
numImageStacks = numel(state.imageFileNames);
if numTriggers > numImageStacks
    choice = questdlg(...
                'Missing Image Stacks For Some Triggers, Continue??',...
                'Data Missing','YES','NO','NO');
    switch choice
        case 'YES'
            disp('Continuing Execution of imExpMaker');
        case 'NO'
            error('Aborting execution of imExpMaker');
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% MAIN LOOP 2 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% In this second loop, we will load each of the tiff stacks, perform motion
% correction if the user supplied channels to correct, and save the image
% stacks to imExp.

%%%%%%%%%%%%%%%%% OPEN WAITBAR TO RELAY PROGRESS %%%%%%%%%%%%%%%%%%%%%%%%%%
% Since motion correction can be a lengthy process, we will relay back to
% the user the progress percentage in a wait bar

h = waitbar(0,'Performing Motion Correction, Please Wait...',...
            'CreateCancelBtn','setappdata(gcbf,''canceling'',1)');
setappdata(h,'canceling',0)
tic
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%% LOAD TIFFS AND CALL MOTION CORRECTION %%%%%%%%%%%%%%%%%%%%

% Initialize for cells for holding images and extremums returned from
% tiffLoader and MotionCorrection_turboReg functions called here
[tiffExtremas{1:numImageStacks}] = deal(cell(1,4));
[tiffStacks{1:numImageStacks}] = deal(cell(1,4));
[correctedStacks{1:numImageStacks}] = deal(cell(1,4));

% we set a flag here to allow the user to breakout of the motion correction
% loop by pressing the 'cancel' button in the wait bar
breakOut = 0;

% LOOP THROUGH EACH TIFF IMAGE FILE NAME
for imageFile = 1:numel(state.imageFileNames)
    
    % CHECK FOR CANCEL PRESS
    if getappdata(h,'canceling')
        breakOut = 1;
        break
    end
    
    % CALL TIFFLOADER TO LOAD THE IMAGE STACK & EXTREMUMS
    [tiffExtremas{imageFile},tiffStacks{imageFile}] =...
                     tiffLoader(state.imagePath,...
                         state.imageFileNames{imageFile}, state.chsToSave);
                    
    % CALL MOTION CORRECTION TURBOREG ON TIFFSTACK IF CHS TO SELECT NOT
    % EMPTY
    if ~isnan(state.chsToCorrect)
            for ch = 1:numel(state.chsToCorrect)
                correctedStacks{imageFile}{state.chsToCorrect(ch)} = ...
                    MotionCorrection_TurboReg(...
                    tiffStacks{imageFile}{state.chsToCorrect(ch)},10);
            end
    else
        correctedStacks = tiffStacks;
    end 

    % REPORT CURRENT ESTIMATE IN THE WAITBAR'S MESSAGE FIELD
    waitbar(imageFile/numImageStacks,h, sprintf('%s',...
        ['Performing Motion Correction: ',...
        num2str(round(imageFile/numImageStacks*100)),'%' ' Complete']));
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% DELETE THE WAIT BAR IF CANCEL PRESSED
if breakOut == 1;
    delete(h)
end

%%%%%%%%%%%%%%%%%%% RESHAPE DATA AND ADD TO EXP STRUCT %%%%%%%%%%%%%%%%%%%%

% Reshape the corrected stacks cell to be num stimulus files x numTriggers
correctedStacks = reshape(correctedStacks, [],numel(state.stimFileNames))';

% Convert corrected stacks to a structure with fields chs1 to chs4 (
% scanimage records at most 4 chs as of vers 3.6)
correctedStacks = cellfun(@(y) cell2struct(y, ...
                      {'Ch1' 'Ch2' 'Ch3' 'Ch4'}, 2), correctedStacks);

% Reshape the corrected stacks cell to be num stimulus files x numTriggers
extremas = reshape(tiffExtremas,[], numel(state.stimFileNames))';

% Convert extremas to a structure with fields chs1 to chs4 (
% scanimage records at most 4 chs as of vers 3.6)
extremas = cellfun(@(y) cell2struct(y, ...
                      {'Ch1' 'Ch2' 'Ch3' 'Ch4'}, 2), extremas);

                  
% Add stimulus, correctedstacks, extremas to
% the experiment structure                 
imExp.correctedStacks = correctedStacks;
imExp.stackExtremas = extremas;
 

% assign to base workspace for inspection
%assignin('base','imExp',imExp)

% If the wait bar is still around, go ahead and delete it
if breakOut ~= 1
delete(h)
end

% return back processing time
toc

end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%% ALTERNATE METHOD USING CELLFUN %%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%% CREATE IMAGE STACK CELL ARRAY %%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We are ready to create an image stack cell array. This cell array will
% contain cells as elements. Individual cells will contain the image
% matrices for chs 1-4. If no data is present for a specific ch it will be
% empty. The cell array will look like {{ch1 ch2 ch3 ch4},{ch1 ch2...},...
% it will be numStimFiles x numTriggers long. 

% CONSTRUCT FIELD NAMES
% scan image can handle a max of 4-chs as of version 3.6 so construct
% fieldnames
%fieldnames = {'Ch1','Ch2','Ch3','Ch4'};

% CALL TIFFLOADER WITHIN CELLFUN ON THE IMAGE FILE NAMES CELL ARRAY
% note this returns back a cell array of cells containing the matrices of
% images for each channel ordered 1-4.
% [tiffExtrema,tiffStacks] = cellfun(@(x) tiffLoader(...
%                                     state.imagePath, x, state.chNums),...
%                                     state.imageFileNames,...
%                                     'UniformOutput',0);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% CALL TURBOREG %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We now have the image matrices for each channel stored in our cell array
% of cells and are ready to perform image correction on the channels
% specified by the user. Again we use cellfun to call turboReg for each
% cell in the cell array. We perform image correction on the channels
% specified. If chsToCorrect is empty no image correction is applied

% if ~isempty(state.chsToCorrect)
%     % Initialize for speed
%     correctedStacks = cell(1,numel(tiffStacks));
%     % Loop through our chs to correct and call MotionCorrection_TurboReg
%     for ch = 1:numel(state.chsToCorrect)
%         correctedStacks{state.chsToCorrect(ch)} = cellfun(@(x) ...
%                MotionCorrection_TurboReg(x{state.chsToCorrect(ch)},10), ...
%                cellfun(@(y) y, tiffStacks,'UniformOutput', 0),...
%                'UniformOutput', 0);
%     end
%     % If the chsToCorrect field is empty we assume not to perform image
%     % motion correction
% else correctedStacks = tiffStacks;
%     
% end
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%