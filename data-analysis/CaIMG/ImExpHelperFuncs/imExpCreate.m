function imExp = imExpCreate(state)
% imExpCreate creates an array of structures containing all individual
% trials of imaging data, stimulus information and encoder data (if
% requested) for a single field of imaging. This array can then be further
% processed by various programs such as the imExpAnalyzer. In the rare case
% that triggers are missed it will locate postitions of the missing
% triggers and set the data to [].
% 
% INPUTS:       STATE: a structure passed from the imExpMaker gui
%                      containing stimFileNames, imageFileNames, 
%                      dataType (daq/abf)
% OUTPUTS:      IMEXP: a 2-d array of structures of size trials x triggers

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

%TESTING INPUTS

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%% LOAD DIR INFORMATION %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ImExpDirInformation;
stimFileLoc = dirInfo.stimFileLoc;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%% INITIALIZE ARRAYS, CELLS AND STRUCTS %%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% initialize cell array to hold encoder results
boolean = [];
stimulusStruct= struct([]);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%% MAIN LOOP ONE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% We will create a waitbar to relay completion time for creating the
% imExp
h1 = waitbar(0,'Creating imExp Structure, Please Wait...',...
    'CreateCancelBtn','setappdata(gcbf,''canceling'',1)');
setappdata(h1,'canceling',0)

breakOut = 0;

% Loop through the stimulus file names supplied in state
for name = 1:numel(state.stimFileNames)
   
    % CHECK FOR CANCEL PRESS
    if getappdata(h1,'canceling')
        breakOut = 1;
        break
    end
    
    %%%%%%%%%%%%%%% ADD STIMFILENAMES TO FILEINFO STRUCT %%%%%%%%%%%%%%%%%%
    imExp.fileInfo(name,1).stimFileName = state.stimFileNames{name};
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%%%%%%%%%%%%%%%%%%%% LOAD STIMULUS TRIALS STRUCT %%%%%%%%%%%%%%%%%%%%%
    load(fullfile(stimFileLoc,state.stimFileNames{name}))
    stimulusStruct = [stimulusStruct, trials];
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

     %%%%%%%%%%%%%%% ADD TIFF FILENAMES TO FILEINFO STRUCT %%%%%%%%%%%%%%%%%
    % call stimImageMatcher to return back the tiffFileNames associated
    % with this stimulus file
    [imageFileNames, ~, imagePath] = ...
                             stimImageMatcher({state.stimFileNames{name}});
     
    % now we will dtermine whether any triggers (i.e. tiff stacks) are
    % missing for this stimulus file. We will do this by testing if the num
    % of triggers for the stimulus matches the number of image files
    if numel(trials) ~= numel(imageFileNames);
        % if the numbers don't match we missed a trigger and need to
        % insert the name 'Missed' into the image file names cell for
        % this stimulus file
        fullImageFileNames = insertTrigToCell(...
                                            state.missingTriggers{name},...
                                            imageFileNames);
    else
        % no fileNames to insert
        fullImageFileNames = imageFileNames;
    end
     % Now for this stimulus file name we create a new struct element                 
     imExp.fileInfo(name,1).imageFileNames = fullImageFileNames;
     imExp.fileInfo(name,1).imagePath = imagePath;
     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
     
     %%%%%%%%%%%%% ADD TIFF INFO TO FILEINFO STRUCT %%%%%%%%%%%%%%%%%%%%%%%
     % Using the first image fileName, we will load the image file header
     % and retrieve image information. Since all image files have the same
     % header this is ok
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
     
     %%%%%%%%%%%%%%% ADD DATAFILENAMES TO FILEINFO STRUCT %%%%%%%%%%%%%%%%%
     % If the user selected to save an encoder channel then the
     % dataFileNames and dataFilePath are already in state. We simply
     % determine the file type and proceed with loading.
     if ~isnan(state.saveEncoder)
         % get the file type from the data file name
         fileNameParts = strsplit(state.dataFileNames{name},'.');
         
        % and save filename to fileInfo struct                                
        imExp.fileInfo(name,1).dataFileName = state.dataFileNames{name};
         
        % FILETYPE IS DAQ 
        if strcmp(fileNameParts{2},'daq')
        % get number of triggers for all stimuli files
        numTriggers = numel(trials);
        
        %%%%%%%%%%%%%%%% READ ENCODER CH FROM EACH FILE %%%%%%%%%%%%%%%%%%%
        % Call daqread to read in our data file
        origData = daqread(fullfile(state.dataFilePath,...
                        state.dataFileName{name}),...
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
       
       % Perform a clear of no longer needed variables (MSC )04242013
       clear origData reshapedData celledData
      
       %CASE FILETYPE IS ABF
        elseif strcmp(fileNameParts{2},'abf')
            % for each data file we will call the abf loader. The abfloaded
            % data is three-dim and contains all chs. (it does not allw
            % specific channel loading). The shape of the loaded data is
            % numDataPts x numChs x numTriggers. We will reshape this to be
            % numDataPts x numTriggers x numChs
            [data,~,~] = abfload([state.dataFilePath,...
                                        state.dataFileNames{name}]);
            
            % now perform the reshape using permute on the 2nd and 3rd dim
            allData = permute(data,[1,3,2]);
            
            % now we only need the encoder channel and as before convert to
            % cell for rundetect
            celledData = num2cell(allData(:,:,state.saveEncoder),1);
            
            %%%%%%%%%%%%%%%%%%%%%%%%% CALL RUN DETECT %%%%%%%%%%%%%%%%%%%%%
            boolean = [boolean, cellfun(@(x) runDetect(x,...
                                    state.encoderOffset,...
                                    state.encoderThreshold,...
                                    state.encoderPercentage), celledData)];
        % Perform a clear of no longer needed variables 
        clear data allData celledData
        end
     end
% REPORT CURRENT ESTIMATE IN THE WAITBAR'S MESSAGE FIELD
    waitbar(name/numel(state.stimFileNames),h1, sprintf('%s',...
        ['Creating imExp Structure: ',...
        num2str(round(name/numel(state.stimFileNames)*100)),...
        '%' ' Complete']));  
end % End of stimFileName loop   
   
% DELETE THE WAIT BAR IF CANCEL PRESSED
if breakOut == 1;
    delete(h1)
end

% We now have a complete list of stimulusFileNames, tiffFileNames, image
% information, a full stimulus struct, and a running boolean. We will now
% add the stimulusStruct to the imExp and the boolean to the imExp

%%%%%%%%%%%%%%%%%%%% ADD STIMULUSSTRUCT TO IMEXP %%%%%%%%%%%%%%%%%%%%%%%%%%
imExp.stimulus = stimulusStruct';

%%%%%%%%%%%%%%%%%%%%% ADD IMAGING DEPTH TO IMEXP %%%%%%%%%%%%%%%%%%%%%%%%%%
imExp.imagingDepth = state.imagingDepth;

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

%%%%%%%%%%%%%%%%%%%%%%%%%%%% END MAIN LOOP 1 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% MAIN LOOP 2 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% In this second loop, we will load each of the tiff stacks, perform motion
% correction if the user supplied channels to correct, and save the image
% stacks to imExp.

%tic % set a counter for the processing time
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%% LOAD TIFFS AND CALL MOTION CORRECTION %%%%%%%%%%%%%%%%%%%%

% Obtain the total number of image stacks (should exactly match the total
% number of triggers in the stimulus struct of imExp
numImageStacks = numel([imExp.fileInfo(:,:).imageFileNames]);
% obtain the complete list of image fileNames (this list ncludes the
% 'Missed' triggers as well)
allImageFileNames = [imExp.fileInfo(:,:).imageFileNames];

% Initialize cell arrays of 4 element cells (one for each possible data
% channel) for tiffExtremas, tiffStacks, and motionCorrectedStacks
[tiffExtremas{1:numImageStacks}] = deal(cell(1,4));
[tiffStacks{1:numImageStacks}] = deal(cell(1,4));
[correctedStacks{1:numImageStacks}] = deal(cell(1,4));

% we set a flag here to allow the user to breakout of the motion correction
% loop by pressing the 'cancel' button in the wait bar
breakOut = 0;

%%%%%%%%%%%%%%%%% OPEN WAITBAR TO RELAY PROGRESS %%%%%%%%%%%%%%%%%%%%%%%%%%
% Since motion correction can be a lengthy process, we will relay back to
% the user the progress percentage in a wait bar
h = waitbar(0,'Performing Motion Correction, Please Wait...',...
    'CreateCancelBtn','setappdata(gcbf,''canceling'',1)');
setappdata(h,'canceling',0)

% LOOP THROUGH EACH TIFF IMAGE FILE NAME
for imageFile = 1:numImageStacks
    
    % CHECK FOR CANCEL PRESS
    if getappdata(h,'canceling')
       breakOut = 1;
       break
    end
    
    % CALL TIFFLOADER TO LOAD THE IMAGE STACK & EXTREMUMS 
    % We will call tiffLoader to load the image stack for this
    % imageFileName if and only if the imageFileName is not 'MissedTrigger'. This
    % string indicates a missed trigger. In that case, we will bypass the
    % loading and set the tiffExtrema and tiffStack to a [] array
    if ~strcmp(allImageFileNames{imageFile},'missedTrigger') 
        [tiffExtremas{imageFile},tiffStacks{imageFile}] =...
                     tiffLoader(state.imagePath,...
                     allImageFileNames{imageFile}, state.chsToSave,...
                     'framesToDrop',state.framesToDrop);
    else
        % if we missed a trigger then we will loop through the chsToSave
        % and assign an NaN to the tiffExtremas and tiffStacks
        for ch = 1:numel(state.chsToSave)
            tiffExtremas{imageFile}{state.chsToSave(ch)} = NaN;
            tiffStacks{imageFile}{state.chsToSave(ch)} = NaN;
        end
    end
    
    % CALL MOTION CORRECTION TURBOREG ON TIFFSTACK. 2 CONDITIONS TO BE
    % MET. 1. USER MUST SELECT CHS TO CORRECT, 2. TRIGGER MUST NOT HAVE
    % BEEN MISSED IN ORDER THAT WE CALL TURBOREG TO CORRECT
    if ~isnan(state.chsToCorrect) % chk that some chs are to be corrected
        
            % loop through only chs to be corrected
            for ch = 1:numel(state.chsToCorrect)
                % chk that the tiffstack to correct is not a missedTrigger
                if ~any(cellfun(@(x) any(isnan(x(:))),tiffStacks{imageFile}));
                    correctedStacks{imageFile}{state.chsToCorrect(ch)} = ...
                            MotionCorrection_TurboReg(...
                            tiffStacks{imageFile}{state.chsToCorrect(ch)},10);
                else
                    % we propogate the NaN value to the correct stack if
                    % the trigger was missed
                    correctedStacks{imageFile}{state.chsToCorrect(ch)} =...
                                                                       NaN;
                end
            end
    else % if no chs to be corrected we do not perform motion correction
         % but we still call it a corrected stack
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

% If the wait bar is still around, go ahead and delete it
if breakOut ~= 1
delete(h)
end

% return back processing time
%toc

% assign to base workspace for inspection
assignin('base','imExp',imExp)

% Clean-up in case wait bars where not deleted
F = findall(0,'type','figure','tag','TMWWaitbar'); 
delete(F);

end

