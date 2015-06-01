function [im, header] = imread_multi(filename, channel)
% Input: filename - scanimage tiff file name.
%        channel - 'g' or 'green', 'r' or 'red'
% Output: im - uint16 image matrix
%         header - scanimage header info.
%
% NX 3/11/2009

finfo = imfinfo(filename); 
if isfield(finfo, 'ImageDescription')
    header = parseHeader(finfo(1).ImageDescription);
else
    header = [];
end
n_channel = header.acq.numberOfChannelsAcquire;
if nargin>1 || n_channel > 1
    if strncmpi(channel, 'g', 1)
        firstframe = 1;
        step = n_channel;
    elseif strncmpi(channel, 'r', 1)
        firstframe = 2;
        step = n_channel;
    else
        error('unknown channel name?')
        
    end
else
    firstframe = 1;
    step = 1;
end

width = header.acq.pixelsPerLine;
height = header.acq.linesPerFrame;
n_frame = header.acq.numberOfFrames;

im = zeros(height, width, n_frame, 'uint16');

count = 0;
for i = firstframe : step : length(finfo)
    count = count+1;
    im (:,:,count) = imread(filename, i);
end;