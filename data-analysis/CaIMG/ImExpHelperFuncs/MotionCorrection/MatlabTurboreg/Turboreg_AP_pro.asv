function Turboreg_AP_pro(targetfilename, sourcefilename, savefilename, channels)
%
% Call ImageJ class and Turboreg class to do motion correction on input
% image data file. Only works with translation of Turboreg. For other
% transformation algorithms, further modification is needed.
%
% squre_flag -- whether to scale the image to sqare before run Turboreg.
%
% Based on TurboregTK by TK.
%
% NX - May 09
%

% Load reference(tiff), otherwise assume im_t from gui
if ischar(targetfilename)
    im_t(:,:) = imread(targetfilename,'tiff');
else
    im_t = targetfilename;
end

target = im_t;
target_ij = array2ijStackAK(target);


% Load in data to be corrected(tiff), otherwise just assume im_s from gui
% if ischar(sourcefilename)
% [sourcepath, sourcename, sourceext] = fileparts(sourcefilename);
%    n_frame = length(imfinfo(sourcefilename,'tiff'))/channels;
%     for u = 1:channels:n_frame*channels
%         im_s(:,:,ceil(u/channels))=imread(sourcefilename,'tiff',u);
%     end
% else
%     im_s = sourcefilename;
%     n_frame = size(im_s,3);
% end

% Get information about source image
imageinfo=imfinfo(sourcefilename,'tiff');
if isfield(imageinfo(1),'ImageDescription')
    image_description = imageinfo(1).ImageDescription;
else
    disp('Warning! No scanimage header!')
end
numframes=length(imageinfo);
M=imageinfo(1).Width;
N=imageinfo(1).Height;

%Do turboreg

% load in full movie
clear im_s

disp('Done.')
clear im_registered
loadframes_channels = 1:channels:numframes;
im_registered = zeros(N,M,length(loadframes_channels),'uint16');
disp('Turboreg correcting...')
turboreg_offsets.x = [];
turboreg_offsets.y = [];

%Cropping= ['0 0 ' num2str(size(target,2)) ' ' num2str(size(target,1))];
% Crop 10 frames on all sides: this makes a significant difference
crop_border = 10;
Cropping = [num2str(crop_border) ' ' num2str(crop_border) ' '...
    num2str(size(target,2)-crop_border) ' ' num2str(size(target,1)-crop_border)];
Transformation='-translation';
center_x = num2str(fix(size(target,2)/2)-1-crop_border);
center_y = num2str(fix(size(target,1)/2)-1-crop_border);
landmarks = [center_x,' ',center_y,' ',center_x,' ',center_y];
cmdstr=['-align -window s ',Cropping,' -window t ', Cropping,' ', ...
    Transformation, ' ', landmarks,' -hideOutput'];

for curr_frame = 1:length(loadframes_channels);
    ii = loadframes_channels(curr_frame);
    % this is a slow way to load the tiffs, MSC
    im_s = imread(sourcefilename,'tiff',ii,'Info',imageinfo);
    source = im_s;
    source_ij=array2ijStackAK(source);
    
    al=IJAlign_AK; % Does this class instance need to be in loop?? MSC
    registered_ij = al.doAlign(cmdstr, source_ij, target_ij);
    registered = ij2arrayAK(registered_ij);
    a=uint16(round(registered));
    im_registered(:,:,curr_frame) = a;
    
    % calculate offsets based on rows/columns = 0 in one direction
    clear zeros_y zeros_x turboreg_offsets_y turboreg_offsets_x
    zeros_y = any(a,2)-flipud(any(a,2));
    turboreg_offsets_y = sum(abs(zeros_y))*zeros_y(1)/2;
    turboreg_offsets.y(curr_frame) = turboreg_offsets_y;
    zeros_x = fliplr(any(a,1))-any(a,1);
    turboreg_offsets_x = sum(abs(zeros_x))*zeros_x(1)/2;
    turboreg_offsets.x(curr_frame) = turboreg_offsets_x;
    save([savefilename '_offsets.mat'],'turboreg_offsets')
    disp(['Corrected frame (' savefilename '): ' num2str(curr_frame) '/' num2str(length(loadframes_channels))]);
    
    % something about the java code might leak memory, so clear the shit out of
    % everything related to java
    java.lang.Runtime.getRuntime.gc % java garbage collector
    clear source_ij registered_ij al
end
clear al

disp('Done. Saving...')
% You might get an error here about not being able to write to file
% because of permissions: SOLUTION IS TO NOT HAVE WINDOWS EXPLORER OPEN
% SIMULTANEOUSLY (but this windows lock solution might help fix)
% tic
% saveastiff(im_registered,[savefilename '.tif'],1,1,1,0,image_description);
% toc
for curr_frame = 1:length(loadframes_channels);
    if curr_frame == 1,
        for windows_lock = 1:100
            try
                if exist('image_description','var')
                    imwrite(im_registered(:,:,curr_frame),[savefilename '.tif'],'tif','Compression','none','WriteMode','overwrite', ...
                        'Description', image_description);
                else
                    imwrite(im_registered(:,:,curr_frame),[savefilename '.tif'],'tif','Compression','none','WriteMode','overwrite');
                end
                break;
            catch me
                pause(0.2);
                continue
            end
            disp('Error! Didn''t Write')
            keyboard
        end
    else
        for windows_lock = 1:100
            try
                if exist('image_description','var')
                    imwrite(im_registered(:,:,curr_frame),[savefilename '.tif'],'tif','Compression','none','WriteMode','append', ...
                        'Description', image_description);
                else
                    imwrite(im_registered(:,:,curr_frame),[savefilename '.tif'],'tif','Compression','none','WriteMode','append');
                end
                break;
            catch me
                pause(0.2);
                continue
            end
            disp('Error! Didn''t Write')
            keyboard
        end
    end;
    disp(['Frame written (' savefilename '): ' num2str(curr_frame) '/' num2str(length(loadframes_channels))]);
end

disp('Done.')