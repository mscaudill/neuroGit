function popHwhmPlot(running, popNames, plotType)
%popHwhm returns a histogram or scatter plot of the HWHM calculated from a
%double Gaussian fit to the orientation tuning curves of each population. 
%It guides the user to the Exp Location where they can choose a single
%population at a time 
% INPUTS                        : running state, 0, 1, or 2 to determine
%                                 whether to calculate OSI for...
%                                 non-runinng, running, or both...
%                                 respectively
%                               : popNames, cell array of pop names
%                                 will go into the histogram||scatter plot,
%                                 the function
%                                 will use uigetfile to load each pop
%                                 separately
%                               : plotType, type of plot to display
%                                 (histogram, scatter) defualts to
%                                 histogram
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
%%%%%%%%%%%%%%%%%%%%%%%% SET DEFAULT PLOT TYPE %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin < 3;
    plotType = 'histogram';
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%% LOOP OVER POPULATIONS AND CALL EXPSELECTOR %%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
numPops = numel(popNames);
for pop = 1:numPops
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%% GET A LIST OF EXPERIMENTS FOR THE POPULATION PLOT %%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % We will now call expSelector to get a cell array of fullfileNames
    % (including paths) to the experiments we wish to include in the plot.
    % This function utilizes uigetfile to obtain filenames
    expFileNames = expSelector;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%% MAIN LOOP OVER EXP FILE NAMES %%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % We will loop over all the expFileNames, load each, construct an
    % orientation tuning curve and repeat storing each to a cell array
    % below
    for file = 1:numel(expFileNames)
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%% LOAD SPECIFIED FIELDS FROM THE EXP %%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % we will need only the specified fields to make our plot
        subExp = loadExp(expFileNames{file}, 'behavior', 'spikeIndices',...
            'stimulus', 'fileInfo');
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%% CALL FIRINGRATEMAP FUNC TO CONSTRUCT MAP OBJ %%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % we will now call the function firingRateMap which constructs a
        % map object of firing rates 'keyed' on stimulus angles. Running
        % state is passed to this function to return a map that meets the
        % user definded running state condition ( see inputs above)
        [oriMap] = firingRateMap(running,'Orientation',...
            subExp.behavior, subExp.spikeIndices,...
            subExp.stimulus, subExp.fileInfo);
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%% OBTAIN MEAN FIRING RATES FROM MAP %%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % For this exp (cell) we will first obtain the firing rates and
        % store them to a a cell array
        FiringRates = oriMap.values;
        % now we compute the mean firing rate across trials for this exp
        % and store to a cell in the cell array meanFiringRates
        meanFiringRates{pop,file} = cellfun(@(f) mean(f), FiringRates);
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% CALL DATA FIT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We now call fitData function (in MathTools dir) to compute a double
% Gaussian fit for each tuning curve in the meanFiringRates cell array

% fitData requires a fitFunc, a set of xpts (angles) and ypts (array of
% firing rates). We obtain these here
angles = cell2mat(oriMap.keys);

% now call dataFit and return only the fit params (we don't need the other
% returned values
[fitParams,~,~] = cellfun(@(f) fitData('doubleGaussian', angles, f),...
                             meanFiringRates,'UniformOutput', 0);
                         
% we will cyclically permute the arrays of fitParams so that the first
% element is the sqrtVariance (currently it is third position)
cycFitParams = cellfun(@(g) circshift(g,[1,3]), fitParams,...
                       'UniformOutput',0);

hwhm = cellfun(@(h) sqrt(2*log(2))*h(1), cycFitParams, 'UniformOutput',0);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
assignin('base','Hwhm', hwhm)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%% PLOTTING OF HWHM DATA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Depending on the user choice for plot type, we will plot either a
% histogram, scatter plot or both
switch plotType
    
    case 'histogram'
        %%%%%%%%%%%%%%%%%%% HISTOGRAM OSI FOR EACH POPULATION %%%%%%%%%%%%%
        
        % rotate popOsi becasue hist plots a histogram for each column
        % which in our
        %case will be each population
        hist(cell2mat(hwhm)')
        
        %%%%%%%%%%%%%%%%%%%%%%%% SET AXIS PROPERTIES %%%%%%%%%%%%%%%%%%%%%%
        set(gca, ...
            'Box'         , 'off'     , ...
            'TickDir'     , 'out'     , ...
            'TickLength'  , [.02 .02] , ...
            'XMinorTick'  , 'on'      , ...
            'YMinorTick'  , 'on'      , ...
            'YGrid'       , 'off'     , ...
            'XColor'      , [0 0 0],    ...
            'YColor'      , [0 0 0],    ...
            'LineWidth'   , 1             );
        
        axis tight
        
        %%%%%%%%%%%%%%%%%%%%%%%%% AXIS LABELS & TITLE %%%%%%%%%%%%%%%%%%%%%
        popTitle = ['Tuning Sharpness:', ' Running State is  '...
            num2str(running)];
        hTitle  = title (popTitle);
        hXLabel = xlabel('HWHM (degrees)'                     );
        hYLabel = ylabel('counts'                      );
        
        %%%%%%%%%%%%%%%%%%%%%%%% ADD LEGEND %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        legend(popNames);
        
        %%%%%%%%%%%%%%%%%%%%%%%% COLORMAP %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        colormap(summer)
        
        
        %%%%%%%%%%%%%%%%%%%%%%%% SET TITLE AND LABEL FONTS %%%%%%%%%%%%%%%%
        set( gca                            , 'FontName'   , 'Helvetica' );
        set([hTitle, hXLabel, hYLabel]      , 'FontName'   , 'Helvetica' );
        set([hXLabel, hYLabel]              , 'FontSize'   , 10          );
        set( hTitle                         , 'FontSize'   , 12       , ...
            'FontWeight' , 'bold'      );
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        case'scatter'  
        %%%%%%%%%%%%%%% CREATE ERRORBAR PLOT OF HWHM VALUES %%%%%%%%%%%%%%%
        
        % remove the NaNs from each array, call the func removeNaN in
        % MathTools dir
        nonNaNHwhm = cellfun(@(p) removeNaN(p), hwhm,...
                            'UniformOutput',0);
                        
         % now create a cell array that is numPops x 1 long where each
         % array contains the hwhm for cells of that population
        popHwhmCell = arrayfun(@(idx) [nonNaNHwhm{idx,:}],...
                                1:size(nonNaNHwhm,1), 'UniformOutput',0)';
        
        %calculate the mean of each population (returns an array)
        meanHwhm = cellfun(@(p) mean(p), popHwhmCell);
        % and standard deviation of each population (returns an array)
        stdHwhm = cellfun(@(p) std(p), popHwhmCell);
        
        hE = errorbar(1:numPops, meanHwhm, stdHwhm);
        
        
        set(hE                            , ...
            'LineStyle'       , 'none'      , ...
            'Marker'          , '^'         , ...
            'MarkerFaceColor' , [0 0 0]     , ...
            'Color'           , [0 0 0]     );
        
        %%%%%%%%%%%%%%%%%%%% ADD SCATTERED DATA POINTS TO PLOT %%%%%%%%%%%%
        hold all
        for pop = 1:size(popHwhmCell,1)
            scatter(pop*ones(1,numel(popHwhmCell{pop}))-.5,...
                            popHwhmCell{pop},'k','Marker' ,'^')
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%% SET AXIS PROPERTIES %%%%%%%%%%%%%%%%%%%%%%
        set(gca, ...
            'Box'         , 'off'     , ...
            'TickDir'     , 'out'     , ...
            'TickLength'  , [.02 .02] , ...
            'XTick'       , [1 2]     , ...
            'XMinorTick'  , 'off'      , ...
            'YMinorTick'  , 'off'      , ...
            'YGrid'       , 'off'     , ...
            'XColor'      , [0 0 0],    ...
            'YColor'      , [0 0 0],    ...
            'LineWidth'   , 1             );
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%% AXIS LABELS & TITLE %%%%%%%%%%%%%%%%%%%%%
        popTitle = ['Orientation Selectivity:', ' Running State is  '...
            num2str(running)];
        hTitle  = title (popTitle);
        hXLabel = xlabel(''                                             );
        hYLabel = ylabel('hwhm (degrees)'                       );
        
        %%%%%%%%%%%%%%%%%%%%%%%% SET TITLE AND LABEL FONTS %%%%%%%%%%%%%%%%
        set( gca                            , 'FontName'   , 'Helvetica' );
        set([hTitle, hXLabel, hYLabel]      , 'FontName'   , 'Helvetica' );
        set([hXLabel, hYLabel]              , 'FontSize'   , 10          );
        set( hTitle                         , 'FontSize'   , 12       , ...
            'FontWeight' , 'bold'      );
        set(gca                             , 'XtickLabel' , popNames);
 end
end

