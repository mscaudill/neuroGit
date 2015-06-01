%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%copyright (c) 2012  Matthew Caudill
%
%this program is free software: you can redistribute it and/or modify
%it under the terms of the gnu general public license as published by
%the free software foundation, either version 3 of the license, or
%at your option) any later version.

%this program is distributed in the hope that it will be useful,
%but without any warranty; without even the implied warranty of
%merchantability or fitness for a particular purpose.  see the
%gnu general public license for more details.

%you should have received a copy of the gnu general public license
%along with this program.  if not, see <http://www.gnu.org/licenses/>.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [ inputPixVal ] =...
                   GammaCorrect(Luminance)
%GAMMACORRECT determines the pixel value to pass to the graphics hardware
%in order to acheive gamma corrected luminance output values for grays

% INPUTS: scale factor for power law relationship
%         gamma, exponent of power law relationship
%         Luminance value to be displayed
%         
% OUTPUTS:
%         inputPixVal is the pixel value passed to the hardware that will
%         undergo gamma correction and display as the Luminance value

% EXPLANATION:
% Computer monitors utilize a power-law relationship
% (Output=scaleFactor*Input^Gamma) between the requested pixel value and
% actual displayed pixel luminance. So for example if you ask for gray at a
% pixel value of 128/255 = 0.5 on a monitor with a gamma value of 2.5 you
% actually get a returned pixel value from the monitor as (128/255)^2.5 =
% .177. Manufacturers of monitors perform this operation becasue the human
% eye encodes luminance values logarithmically, meaning more bandwidth at
% lower luminance values and less bandwith at high lumiance values. In
% order to correct this problem we will compute the Luminance values for
% black and white (see PixToLum.m) and use these to calculate gray =
% 0.5(black + white). Then we will call this function GammaCorrect on this
% gray value to determine the pixel value to pass to the graphics hardware
% so that this gray value is properly displayed.

%Get the scale factor and gamma from monitorInformation.m in
%RigSpecificInfo directory
monitorInformation;
scaling = monitorInfo.powerLawScaleFactor;
gamma = monitorInfo.gamma;

inputPixVal = round((Luminance./scaling).^(1/gamma));

% Make sure pixel vals are in the correct range (0-255)

if inputPixVal > 255
    inputPixVal = 255;
elseif inputPixVal <0
    inputPixVal = 0;
end

end

