function sizeTunePlot(runState, varargin )
%sizeTunePlot constructs a size tuning plot for a single experiment. The
%plot has an annotation describing the running behavior of the animal and
%the suppression index for this experiment
% INPUTS                
%           runState            : integer to seperate trials based on
%                                 running behavior (1 = yes, 0 = No, 
%                                 2= Keep ALL)
%           varargin            : save, a logical to determine
%                                 whether to open a save dialog box, 
%                                 defaults to false
%                               : normalize, an option to normalize the
%                                 firing rates to the greatest firing rate
%                                 across all angles defaults to false
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%% PARSE INPUTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
inputParseStruct = inputParser;
% set default values for the options under varargin (saveOption, normalize)
defaultSave = false;
defaultNormalize = false;

% Add all requried and optional args to the input parser object
addRequired(inputParseStruct,'runState',@isnumeric);
addParamValue(inputParseStruct,'save',defaultSave,@islogical);
addParamValue(inputParseStruct,'normalize',defaultNormalize,@islogical);

% call the parser
parse(inputParseStruct,runState,varargin{:})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%% LOAD FIELDS FROM EXP TO SUBEXP %%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We call the function dialogLoadExp to load the specific fields from the
% exp structure. This save considerable computation time becasue the exp
% structure can be very large.
% We need the behavior to evaluate running, spikeIndices to get a firing
% rate, the stimulus to get the orientation, and the fileInfo to get sample
% rate of the data

subExp = dialogLoadExp('behavior', 'spikeIndices', 'stimulus', 'fileInfo');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%% CALL ORIENTATION MAP FUNC TO CONSTRUCT MAP OBJ %%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% we will now call the function firingRateMap which constructs a map
% object of firing rates 'keyed' on stimulus diameters. Running state is
% passed to this function to return a map that meets the user definded
% running state condition ( see inputs above)
[sizeMap, meanSpont, runStateInfo] = firingRateMap(runState,...
                            'Diameter', subExp.behavior,...
                            subExp.spikeIndices, subExp.stimulus,...
                            subExp.fileInfo);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

assignin('base','sizeMap',sizeMap);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%% NORMALIZE FIRING RATES IN MAP %%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% if the user has not entered a choice for normalization we will default to
% the case where we *DO NOT* normalize. So we will just get the values from
% the orientation map

FiringRates = sizeMap.values;
switch inputParseStruct.Results.normalize
    case false
        % calculate the mean and std of the firing rates across trials
        meanFiringRates = cellfun(@(x) mean(x),FiringRates);
        stdevFiringRates = cellfun(@(y) std(y),FiringRates);
    case true
         % calculate the mean and std of the firing rates as before
        meanFiringRates = cellfun(@(x) mean(x),FiringRates);
        stdevFiringRates = cellfun(@(y) std(y),FiringRates);
        % calculate the max of meanFiringRates and use this to normalize
        % the mean and stdev of the mean arrays
        maxMean = max(meanFiringRates);
        meanFiringRates = meanFiringRates/maxMean;
        stdevFiringRates = stdevFiringRates/maxMean;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%% CALCULATE SUPPRESSION INDEX %%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
diameters = cell2mat(sizeMap.keys);
si = NaN;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%% PLOT SIZE TUNING CURVE %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plot the mean and error and return a handle to the plot
hE = errorbar(diameters, meanFiringRates, stdevFiringRates);

% plot the mean spontaneous activity as well
 hold on
 hSpont = plot([diameters(1) diameters(end)], [meanSpont meanSpont]);
 
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%% CALL FITDATA  TO CONSTRUCT DOUBLE GAUSSIAN FIT %%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[~, xfit, diffOfGaussFit] = fitData('differenceOfGaussians',...
                                        diameters, meanFiringRates);
hfit = plot(xfit, diffOfGaussFit);

 %%%%%%%%%%%%%%%%%%%%% SET ERROR BAR LINE PROPERTIES %%%%%%%%%%%%%%%%%%%%%%%
set(hE                            , ...
  'LineStyle'       , 'none'        , ...
  'Color'           , [0 0 0]        );

set(hE                            , ...
  'LineWidth'       , 1           , ...
  'Marker'          , 'o'         , ...
  'MarkerSize'      , 6           , ...
  'MarkerEdgeColor' , [.2 .2 .2]  , ...
  'MarkerFaceColor' , [.7 .7 .7]     );

set(hSpont                        , ...
    'Color'         , [1 0 0]        );

set(hfit                          , ...
    'Color'         , [0 0 0]        );

%%%%%%%%%%%%%%%%%%%%%%%% SET AXIS PROPERTIES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
set(gca, ...
  'Box'         , 'off'     , ...
  'TickDir'     , 'out'     , ...
  'TickLength'  , [.02 .02] , ...
  'XMinorTick'  , 'off'      , ...
  'YMinorTick'  , 'off'      , ...
  'XTick'       ,[5:10:85]  ,  ...
  'YGrid'       , 'off'     , ...
  'XColor'      , [0 0 0],    ...
  'YColor'      , [0 0 0],    ...
  'LineWidth'   , 1             );

axis tight

%%%%%%%%%%%%%%%%%%%%%%%%% AXIS LABELS & TITLE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get all the parts of the filename contained in the fileInfo structure of
% the subExp (e.g. 'MSC_2012-08-17_n4orientation_3.daq'
expString = subExp.fileInfo(1,1).dataFileName;
% split this file name on the underscores
allStrings = regexp(expString,'_', 'split');
% the date will be the second element of the cell array
date = allStrings{2};
% the exp type will be the third element
cellNumExpType = allStrings{3};
% construct the title from the date and exp type
expTitle = [date,' ',cellNumExpType,' ','Running State is  ',...
            num2str(runState)]; 
% set the titles and labels and return handles to each for changing fonts
% etc. later
hTitle  = title (expTitle);
hXLabel = xlabel('diameter (deg)'                     );
hYLabel = ylabel('sp/s (Hz)'                      );

%%%%%%%%%%%%%%%%%%%%%%%% ANNOTATION ABOUT RUNNING INFO %%%%%%%%%%%%%%%%%%%%
% create an annotation box that describes the percentage of trials the
% animal ran for.
if runState == 0 || runState == 1
    ha = annotation('textbox', [.15, 0.9, .50, 0], 'string',...
                ['animal ran ',...
                num2str(runStateInfo.percentRunning),'% of the ',...
                num2str(runStateInfo.numTriggers),' triggers' char(10)...
                'SI = ',num2str(si)]);
else 
    ha = annotation('textbox', [.15, 0.9, .50, 0], 'string',...
                ['Running State Ignored' char(10) 'SI = ',num2str(si)]);
end

% remove the default box around the annotation
set(ha, 'LineStyle','none');

%%%%%%%%%%%%%%%%%%%%%%%% SET TITLE AND LABEL FONTS %%%%%%%%%%%%%%%%%%%%%%%%        
set( gca                            , 'FontName'   , 'Helvetica' );
set([hTitle, hXLabel, hYLabel]      , 'FontName'   , 'Helvetica' );
set([hXLabel, hYLabel]              , 'FontSize'   , 10          );
set( hTitle                         , 'FontSize'   , 12       , ...
                                      'FontWeight' , 'bold'      );
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

end

