function [ stackExtrema, tiffCell] = tiffLoader(imagePath, ...
                                                 tiffImageStack,...
                                                 chsToSave, varargin)
% tiffLoader reads in a single image stack and converts it into a 1 x 4
% cell array where each element contains a 3-d matrix of images for that
% ch. (e.g. user selects to save chs 2 and 3 then tiffCell = {[],
% [512x512x50], [512x512x50], []}. We use emptys as positional holders
% only. Also note there are only 4 elements in the cell array because this
% is the max number of chs scanimage currently can save. stack extrema is a
% 1 x 4 cell array with two-element arrays as the elements. Each two el
% array contains the [min,max] of the stack for that ch. We will use this
% to scale our images when plotting.
%
%
% INPUTS:               :imagePath, the path to the tiffstack filenam
%                       :tiffImageStack, a tiffstack filename
%                       :chsToSave, an array of channel numbers, these are
%                       user requested chs. We check these against the
%                       actual chsRecorded to relay back to user if they
%                       request a ch not present in the data.
%
% OUTPUTS:              :stackExtrema, an cell array of [min, max] pairs 
%                        for each channel
%                       :tiffCell, a cell array of tiff matrices, one for
%                       each channel
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

%TESTING
%  imagePath = 'G:\data\ImagingData\02062013';
%  tiffImageStack = 's7cs_2_161.tif';
%  chsToSave = [2,3];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%% BUILD INPUT PARSER %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Construct the parser object
p = inputParser;

%%%%%%%%%%%%%%%%%%%%%%%% ADD REQUIRED ARGS TO PARSER %%%%%%%%%%%%%%%%%%%%%%
% add the required imagePath to the parser and validate
addRequired(p,'imagePath',@ischar);

% add the required tiff stack fileName and validate
addRequired(p,'tiffImageStack',@ischar);

% add the required chs to save
addRequired(p,'chsToSave',@isnumeric)

%%%%%%%%%%%%%%%%%%%%%%% ADD VARARGS TO PARSER %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
defaultFramesToDrop = [];
addParamValue(p,'framesToDrop',defaultFramesToDrop,@isnumeric)

%%%%%%%%%%%%%%%%%%%%%%%%%%% CALL PARSE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
parse(p, imagePath, tiffImageStack, chsToSave, varargin{:})

%%%%%%%%%%%%%%%%%%% EXTRACT FROM PARSER REQUIRED INPUTS %%%%%%%%%%%%%%%%%%%
imagePath = p.Results.imagePath;
tiffImageStack = p.Results.tiffImageStack;
chsToSave = p.Results.chsToSave;
framesToDrop = p.Results.framesToDrop;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%% CONSTRUCT FULLFILE PATH/NAME TO TIFF STACK %%%%%%%%%%%%%%%%
tiffFile = fullfile(imagePath,tiffImageStack);

%%%%%%%%%%%%%%%%%%%%%%% GET TIFF FILE INFORMATION %%%%%%%%%%%%%%%%%%%%%%%%%
% Get image info structure
InfoImage=imfinfo(tiffFile);

% Determine the channels that were recorded. Scan image is
% written poorly, the designer saved all the aquistion info to a character
% array. . The character array is called ImageDescription, I rename
% to 'a' here for brevity. We will locate the strings in tha character
% array coresponding to our channels

a = InfoImage(1,1).ImageDescription;

% All the the channel numbers are stroed into the string with the following
% prefix. We use this to isolate the channel numbers from the rest of the
% giant character array
stringsToLocate = 'state.acq.acquiringChannel';

% Once we locate the string we move to the end of the string and add 2 for
% the = sign present in each string
aIndices = strfind(a,stringsToLocate) + length(stringsToLocate)+2;

%Loop through the indices to get the chs
for index = 1:numel(aIndices)
    chs(index) = str2double(a(aIndices(index)));
end

% Determine number of chs (chs not used are given a zero)
chsRecorded = find(chs);


%%%%%%%%%%%%% CHECK THAT CHS REQUESTED ARE PRESENT IN STACK %%%%%%%%%%%%%%%
% Perform a check to make sure that the number of channels being requested
% in the function inputs matches the actual number of channels recorded

% case 1, the number of channelsRequested = numChannels recorded but some
% channels are not equal
% case 2, the number of channels requested>numChs Recorded
% case 3, numChs requested < numChs recorded but a channel is being
% requested that is not in the chsRecorded set
if numel(chsToSave) == numel(chsRecorded) && any(~eq(chsToSave,chsRecorded))...
    || numel(chsToSave) > numel(chsRecorded)...
    || ~isempty(setdiff(chsToSave, chsRecorded))
                errordlg(['**Missing Channels**, Only Channels [',...
             num2str(chsRecorded), '] are present in the image stack'])
end

%%%%%%%%%%%%%%%%%% LOAD ALL CHS TO A TIFF MATRIX %%%%%%%%%%%%%%%%%%%%%%%%%%

% Get image dimensions
imageWidth=InfoImage(1).Width;
imageHeight=InfoImage(1).Height;

% Get the number of frames in the tiff stack (this needs correcting see
% saveAvi
NumberImages=length(InfoImage);

%Initialize the tiff matrix
tiffMatrix = zeros(imageWidth, imageHeight ,NumberImages, 'uint16');

% IF YOU ARE USING MATLAB 2011 OR EARLIER UNCOMMENT THE SECTION TIFFLIB
% PORT AND COMMENT THE IMREAD SECTION (WILL MAKE MORE PERMANENT FIX LATER
% we do this becasue imread is slower in previous vers of matlab

%%%%%%%%%%%%%%%%%%%%%%%%%%%%% TIFFLIB PORT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %%%%%% CREATE A TIFF OBJECT USING MATLAB'S GATEWAY TO TIFF LIBRARY %%%%%%%%
% TifLink = Tiff(tiffFile, 'r');
% 
% for image = 1:NumberImages
%     if ~ismember(image,framesToDrop)
%         % Each image in the stack is stored to it's own directory and can
%         % be accessed by the directory number matching the image number
%         TifLink.setDirectory(image);
%         % store image to tiffMatrix
%         tiffMatrix(:,:,image)=TifLink.read();
%     end
% end
% 
% % Be sure to close our tiff object to free up memory chunk
% TifLink.close();
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%% IMREAD TIFFS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We now will load the images from the tiff file using imread.
for image = 1:NumberImages
        tiffMatrix(:,:,image)=imread(tiffFile,'Index',image,'Info',...
                                    InfoImage);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%% DEINTERLEAVE TIFF MATRIX %%%%%%%%%%%%%%%%%%%%%%%%%%%
% Now that we have all the images for all chs stored to the tiff matrix we
% are ready to deinterleave the matrix extracting only the channels we want
% to pass back to the user
tiffCell = cell(1,numel(chs));
stackExtrema = cell(1,numel(chs));

for ch = 1:numel(chsToSave)
    index = find(chsToSave(ch) == chsRecorded);
    tiffCell{chsToSave(ch)} = tiffMatrix(:,:,index:numel(chsRecorded):end);
    % Now we will drop the requested frames in each of the channels
    tiffCell{chsToSave(ch)}(:,:,framesToDrop) = [];
    % For displaying the images, we will pass back the lowest and highest
    % uint16 value in the tiffMatrix
    stackExtrema{chsToSave(ch)} = [min(min(min(tiffCell{chsToSave(ch)}))),...
                   max(max(max(tiffCell{chsToSave(ch)})))];
end


%assignin('base','matrices',tiffCell);
%assignin('base','extrema',stackExtrema);
end

