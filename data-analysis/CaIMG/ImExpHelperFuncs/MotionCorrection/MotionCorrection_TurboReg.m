function [correctedMatrix] = ...
                    MotionCorrection_TurboReg(uncorrectedMatrix, cropSize)
% MotionCorrection_TurboReg description

% Add ImageJ java controls for turboreg
        spath = javaclasspath('-static');
        spath = cell2mat(spath(1));
        javafolder = strfind(spath,['java' filesep]);
        javafolder = spath(1:javafolder+3);
        
        javaaddpath([javafolder filesep 'jar' filesep 'ij.jar'])
        javaaddpath([javafolder filesep 'jar' filesep 'mij.jar'])
        javaaddpath([javafolder])

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%% CREATE AND CONVERT TARGET IMAGE %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% CREATE  A REFERENCE IMAGE FOR REGISTRATION
% our reference or target image will be the average of all the images in
% the uncorrectedMatrix
targetImage = mean(double(uncorrectedMatrix),3);
targetImage = uint16(targetImage);


% CONVERT TARGET IMAGE TO AN IMAGEJ IMAGE
ijTargetImage = array2ijStackAK(targetImage);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                      
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%% GENERATE COMMAND STRING FOR DO ALIGN JAVA METHOD %%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% CROPPING COMMAND SUBSTRING
% We are going to crop each of the images along each side to allow images
% to be shifted over cropped regions
imageWidth = size(targetImage,2);
imageHeight = size(targetImage,1);

borderToCrop = [num2str(cropSize) ' ' num2str(cropSize) ' '...
    num2str(imageWidth-cropSize) ' ' num2str(imageHeight-cropSize)];

% SET TRANSFORMATION SUBSTRING (CURRENTLY ONLY TRANSLATION IS SUPPORTED)
Transformation = '-translation';

% SET LANDMARK SUBSTRING FOR REGISTRATION
% use the center of the image as landmarks for registration
centerX = num2str(fix(imageWidth/2)-1-cropSize);
centerY = num2str(fix(imageHeight/2)-1-cropSize);
% construct  full landmarks command string
landmarks = [centerX,' ',centerY,' ',centerX,' ',centerY];

% CONSTRUCT THE FULL COMMAND STRING FROM SUBSTRINGS
cmdstr = ['-align -window s ', borderToCrop,' -window t ',...
          borderToCrop,' ', Transformation, ' ', landmarks,' -hideOutput'];
      
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


clear correctedMatrix
correctedMatrix = zeros(size(uncorrectedMatrix,1),...
                        size(uncorrectedMatrix,2),...
                        size(uncorrectedMatrix,3),'uint16');
                    
for frame = 1:size(uncorrectedMatrix,3)
    % CONVERT TO IJSOURCE IMAGE
    ijSource = array2ijStackAK(uncorrectedMatrix(:,:,frame));
    
    % Perform image registration calling doAlign method on al object
    al=IJAlign_AK;
    ijRegistered = al.doAlign(cmdstr, ijSource, ijTargetImage);
    
    % Convert registered image back to matlab array
    registered = ij2arrayAK(ijRegistered);
    
    % convert to unsigned 16bit integer format
    correctedMatrix(:,:,frame) = uint16(round(registered));
                    
    %java.lang.Runtime.getRuntime.gc % java garbage collector
    clear ijSource ijRegistered al registered
end


% also clear the target image object on end of function call 04232013MSC
clear ijTargetImage
clear uncorrectedMatrix
end

