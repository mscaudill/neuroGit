function imageFigureUpdater(viewerState, callbackType)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%% OBTAIN THE ACTIVE FIGURE %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% use gcf to get the active figure window
activeFigHandle = get(gcf);

% access the tag of this figure (created in createImageFig.m) to get the
% fileNumber using string token and strtim (ex tiffViewerImage 4) yields 4
stringCell = strsplit(activeFigHandle.Tag);
fileNumber = str2double(strtrim(stringCell{2}))-1;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

switch callbackType
    
    %%%%%%%%%%%%%%%%%%%%%%%%%% SLIDER CALLBACK %%%%%%%%%%%%%%%%%%%%%%%%%%%%
    case 'slider'
        % use the fileNumber to access the specific handle for this slider
        % in this figure (also created in createImageFigure.m)
        hSlider = get(gco);
        
        % get the current value of the slider
        sliderVal = hSlider.Value;

        % get the frameNumber which is the first element (minor increment)
        % of the slider value
        frameNumber = sliderVal;
        
        % obtain the axes that we will plot to using the fileNumber and
        % viewerState structure
        haxes = flipud(findall(gcf,'type','axes'));
        
        % call dispTiff for each axis (i.e. channels)
        for chIndex = 1:numel(viewerState.chsAcquired)
            
            % get the channel of this index
            channel = viewerState.chsAcquired(chIndex);
            
            % get the image stack/extrema for this file and channel
            imageStack = viewerState.tiffCells{fileNumber}{channel};
            stackExtrema = viewerState.stackExtremas{fileNumber}{channel};
            
            % call dispTiff
            dispTiff(haxes(chIndex), imageStack, stackExtrema,...
                     frameNumber,1);
                 
            %%%%%%%%%%%%%%%%%%%%%%%% Title axes %%%%%%%%%%%%%%%%%%%%%%%%%%%
           title(haxes(chIndex),[viewerState.chColors{chIndex},' Ch'],...
                'Interpreter','None','BackgroundColor',...
                viewerState.chColors{chIndex});
        end
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
      
end

