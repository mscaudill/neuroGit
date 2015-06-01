function [osi] = orientationSelectivity(angles, FiringRates)
%orientationSelectivity determines the orientation selectivity index of an
%orientation tuning curve described by angles and firing rates
% INPUTS            : angles, set of stimulus angles in degrees
%                   : FiringRates a set of firing rates the size of
%                     angles that determine orientation tuning
% OUTPUTS           : osi, the orientation selectivity calculated as 1 -
%                     circular variance (see Ringach Orientation...
%                     Selectivity in Macaque V1... 2002 J. Neurosci)
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

% Perform a check to make sure the meanFiringRates array is not empty
if ~isempty(FiringRates)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%% CONVERT ANGLES TO RADIANS %%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    anglesRads = pi/180*angles;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    osi = abs(sum(FiringRates.*exp(2i*anglesRads)/sum(FiringRates)));
else
    % if the mean firing rates array is empty simply set osi to NaN.
    osi = NaN;
end

end

