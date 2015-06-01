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
function dispTiff(imageAxes, tiffMatrix, stackExtrema, imageNumber,...
                  scaleFactor )
% dispTiff displays a single tiff image stored in the tiff matrix and uses
% the extrema of the entire uint16 stack as the low and high values to
% display
% INPUTS:               
%                       :tiffMatrix, matrix of tiff images passed from
%                        tiffLoader.m
%                       :stackExtrema, lower and upper bounds of pixel 
%                        values in uint16 format of the stack, used to 
%                        scale images for display
%                       :imageNumber, specific image of stack to be
%                        displayed
%                       : scaleFactor, a factor to reduce the image display
%                        range for better viewing

imshow(tiffMatrix(:,:,imageNumber), stackExtrema/scaleFactor, 'Parent',...
                  imageAxes);
           
end

