function [fColorMap] = falseColorMaps(minImageVal, maxImageVal, ...
                                      increment, color )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

colorArray = ((minImageVal/maxImageVal):(increment/maxImageVal):1)';
zeds = zeros(numel(colorArray),1);

switch color
    case 'red'
        fColorMap = [colorArray, zeds, zeds];
    case 'green'
        fColorMap = [zeds, colorArray, zeds];
    case 'blue'
        fColorMap = [zeds, zeds, colorArray];
end

end
