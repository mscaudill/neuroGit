function Turboreg_TS(targetfilename, sourcefilename, savefilename)
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

cd(fileparts(sourcefilename));

target = imread(targetfilename);
target_ij = array2ijStackAK(target);


[state, ImageMatrix, FileInfo] = g_getprofile(sourcefilename, inf);
% xsource = state.acq.pixelsPerLine;
% ysource = state.acq.linesPerFrame;
n_frame = state.acq.numberOfFrames;
numChannels = state.acq.numberOfChannelsSave;
ImageDescription = FileInfo(1).ImageDescription; % to be put back to the header


%since the terboreg file will be saved as Green only file, modify the
%ImageDescrition accordingly.
if numChannels==2
    %change numberOfChannelsAcquire
    BP = find(double(ImageDescription)==13);%Return
    NumOfLine = length(BP)+1;
    BP = [0 BP length(ImageDescription)+1];
    for line=1:NumOfLine
        Comment{line} = ImageDescription(BP(line)+1 : BP(line+1)-1);
        if length(Comment{line})>34 && isequal(Comment{line}(1:34), 'state.acq.numberOfChannelsAcquire=')
            ImageDescription = [ImageDescription(1:BP(line)), 'state.acq.numberOfChannelsAcquire=1', ...
                ImageDescription(BP(line+1):end)];
        end
    end

    %change numberOfChannelsSave
    BP = find(double(ImageDescription)==13);%Return
    NumOfLine = length(BP)+1;
    BP = [0 BP length(ImageDescription)+1];
    for line=1:NumOfLine
        Comment{line} = ImageDescription(BP(line)+1 : BP(line+1)-1);
        if length(Comment{line})>31 && isequal(Comment{line}(1:31), 'state.acq.numberOfChannelsSave=')
            ImageDescription = [ImageDescription(1:BP(line)), 'state.acq.numberOfChannelsSave=1', ...
                ImageDescription(BP(line+1):end)];
        end
    end
end

h_waitbar = waitbar(0, 'running turboreg ....');
for ii = 1 : n_frame
    source = ImageMatrix{1}(:,:,ii);
    source_ij=array2ijStackAK(source);

    Cropping= ['0 0 ' num2str(size(target,2)) ' ' num2str(size(target,1))];
    Transformation='-translation';
    center_x = num2str(fix(size(source,2)/2)-1);
    center_y = num2str(fix(size(source,1)/2)-1);
    landmarks = [center_x,' ',center_y,' ',center_x,' ',center_y];
    cmdstr=['-align -window s ',Cropping,' -window t ', Cropping,' ',Transformation, ' ', landmarks,' -hideOutput'];
    
    al=IJAlign_AK;
    registered = al.doAlign(cmdstr, source_ij, target_ij);
    registered = ij2arrayAK(registered);
    a=uint16(round(registered));
    if ii == 1,
        imwrite(a,savefilename,'tif','Compression','none','WriteMode','overwrite');%, 'Description', ImageDescriptio]);
    else
        imwrite(a,savefilename,'tif','Compression','none','WriteMode','append');
    end;
    waitbar(ii/n_frame,h_waitbar)
end
close(h_waitbar);
