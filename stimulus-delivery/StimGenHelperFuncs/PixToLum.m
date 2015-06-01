function [ Luminance ] = PixToLum( pixelValue )
%This function converts pixel values to luminance values according to a
%power-law relationship defined by parameters in monitorInformation.
%Get the scale factor and gamma from monitorInformation.m 
%
% INPUTS: pixel value supplied by the user
%
% OUTPUTS: Luminance in cd/m^2 via power-law measured with a
% spectrophotmeter (Luminance = scaling*pixelValue^gamma)

%RigSpecificInfo directory
monitorInformation;
scaling = monitorInfo.powerLawScaleFactor;
gamma = monitorInfo.gamma;

Luminance = round(scaling*pixelValue^gamma);

end

