function [csNormedF1Amplitudes,csF1Fits] = csNormedF1Amplitude(...
                                                            meanSignals,...
                                                            stimTiming,...
                                                            tempFreq,...
                                                            samplingFreq)
%csNormedF1Amplitude computes the normalized F1 amplitudes for cs data
%relative to the center alone condition data.
% INPUTS:                meansignals: a cell array of signals meanSignals{1}
%                                   contains the cntrl data ordered by surr
%                                   cond and MeanSignals{2} contains
%                                   led data (if present) ordered by Surr 
%                                   cond
%                       stimTiming: 3 el-array of stimulus timing
%                       tempFreq: temporal frequency of the grating
%                       samplingFreq: sampling freq of meanSignals
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
%%%%%%%%%%%%% OBTAIN INTERVAL OF DATA TO COMPUTE AMPLITUDE OVER %%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We need the indices in meanSignals of when the stimulus started and
% ended. We will fit a sine wave over this interval only
% Stim starts after delay period (i.e. stimTiming(1))
stimStartIdx = round(samplingFreq*stimTiming(1));
% Stimulus ends after delay + duration period (stimTiming(2))
stimEndIdx = round(samplingFreq*(stimTiming(1)+stimTiming(2)));

% construct a time vector for the fit
fitTime = (stimStartIdx:stimEndIdx)/samplingFreq;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%% FIT SINE TO DATA %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for map = 1:numel(meanSignals)
    if ~isempty(meanSignals{map})
        for cond = 1:numel(meanSignals{map})
            % Extract the dataPts where the fit will happen
            dataToFit = meanSignals{map}{cond}(stimStartIdx:stimEndIdx)';
            % perform the fit
            [fitParams,~,dataFit] = sineFit(fitTime, dataToFit, tempFreq);
            % save the fit parameters
            csF1Fits{map}{cond} = {fitParams, fitTime, dataFit};
            csF1Amplitudes{map}{cond} = fitParams(2);
        end
    else 
        csF1Fits{map} = [];
        csF1Amplitudes{map} = [];
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%% NORMALIZE AMPLITUDES %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for map = 1:numel(meanSignals)
    if ~isempty(meanSignals{map})
        csNormedF1Amplitudes{map} = cellfun(@(x)...
                                        x./csF1Amplitudes{map}{1},...
                                        csF1Amplitudes{map},...
                                        'UniformOut',1);
    else csNormedF1Amplitudes{map} = [];
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%% DISPLAY FIT PLOTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We want the user to confirm the fits by eye for each cell so we will open
% a figure with the signals and fits plotted together

% construct a time vector for the meanSignals
time = [1:numel(meanSignals{1}{1})]/samplingFreq;

for map = 1:numel(meanSignals)
    if ~isempty(meanSignals{map})
        % open a figure
        % get the number of open figures
        numFigs=length(findall(0,'type','figure'));
        % create a figure one greater than the number of open figures
        hfig{map} = figure(numFigs+1);
        set(hfig{map},'position', [186,410,1304,420])

        % plot the signals and then plot the sine fits across all conds
        for cond = 1:numel(meanSignals{1})
            subplot(1,numel(meanSignals{map}),cond)
            plot(time,meanSignals{map}{cond},'k-')
            hold all
            plot(fitTime,csF1Fits{1}{cond}{3},'r-')
        end
    end
end

