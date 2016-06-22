function [ roi ] = roiDrawer(drawMethod,axes)
% roiDrawer draws an roi according to drawMethod and returns back an roi
% position array defined by the class drawMethod. To obtain all the
% methods available; such as get position etc at the command propmt enter a
% draw method (i.e. imfreehand.methods) to see a listing of all methods for
% the class. In this function we currently only support the imfreehand
% class and methods.
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
% Use a switch-case construct to determine the drawMethod (currently only
% freehand is available)
switch drawMethod
    case 'Free Hand'
        roiHandle = imfreehand(axes);
       
        % We now will get the position of the roi
        roi = getPosition(roiHandle);

    case 'Ellipse'
        roiHandle = imellipse(axes);
        
        % imEllipse get vertices returns the perimeter nx2 array
        roi = getVertices(roiHandle);
end

% we will now delete the object since we don't need it anymore
delete(roiHandle)
roiPlotter(roi, 'y', axes);
end

