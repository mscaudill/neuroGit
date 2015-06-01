function polarTuningPlot(angles, meanFiringRates)
%polarTuningPlot creates a plot of an experiments orientation tuning curve
% and plots this to a polar axis
% INPUTS                    :angles, 1xn-element array of angles in degrees
%                           :meanFiringrates, a 1xn-element array of firing
%                                             rates
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%% CONVERT ANGLES TO RADIANS %%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
radianAngles = angles*pi/180;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%% CYCLICAL PAD FIRING RATES AND ANGLES %%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% In order to have a closed contour in the polar plot over the angles, we
% must repeat the beginning value of the angles and firing rates arrays at
% the end of each (i.e. array(end+1) = array(1))
cycRadianAngles = padarray(radianAngles, [0,1],'circular','post');
cycMeanFiring = padarray(meanFiringRates, [0,1],'circular','post');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%% CALL POLAR PLOT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
rlim = max(cycMeanFiring);
hP = polar2(cycRadianAngles,cycMeanFiring,[0,rlim]);
view([180 270])
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% FORMAT PLOT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%% SET LINE STYLE PROPS %%%%%%%%%%%%%%%%%%%%%%%%%%
set(hP, 'LineStyle', '-','LineWidth', 1.5, 'Color', [64/255 224/255 208/255]);

%%%%%%%%%%%%%%%%%%%%%%%%%%% SET MARKER STYLE PROPS %%%%%%%%%%%%%%%%%%%%%%%%
set(hP, 'Marker', 'o', 'MarkerSize', 6, 'MarkerEdgeColor' , 'k',...
     'MarkerFaceColor' , [.7 .7 .7] );

%%%%%%%%%%%%%%%%%%%%%%%%%% FORMAT AXIS PROPS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

end

