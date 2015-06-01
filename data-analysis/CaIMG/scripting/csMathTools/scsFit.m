function [fitParams, xFit, dataFit] = scsFit(areasCell, mapKeys, method )
%scsFit is a wrapper function for fitData. It is used to fit the scs areas
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


switch method
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    case 'method1'
        % This method uses no padding and allows a gaussian or relaxed
        % gaussian fit currently yields 24 bad fits
        for cell = 1:numel(areasCell)
            cell
            [pks, indices] = findpeaks(areasCell{cell}, 'SORTSTR',...
                                        'descend');
            if numel(pks) < 2 % FIT A GAUSSIAN
                display(['Fitting a Gaussian to cell',num2str(cell)])
                % Perform Fit
                [fitParams{cell},xFit{cell},dataFit{cell}] = ...
                    fitData('gaussian',mapKeys, areasCell{cell});
                
            else % FIT A RELAXED DOUBLE GAUSSIAN
                display(['Fitting RELAXED double Gaussian to cell',...
                            num2str(cell)])
                % Perform Fit
                [fitParams{cell},xFit{cell},dataFit{cell}] = ...
                    fitData('relaxedDoubleGaussian',mapKeys,...
                                areasCell{cell});
            end
            
            
        end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    case 'method2'
        % This method pads the areasCell and mapKeys circularly.
        %pad areasCell 20 bad fits
        areasCell = cellfun(@(g) padarray(g,[0,1],'circular'),...
                               areasCell,'uniformout',0);
        % pad the map keys
        mapKeys = padarray(mapKeys,[0,1],'circular');
        
        % Change the mapKey endpt angles
        %mapKeys(1)=-45;
        %mapKeys(end) = 360;
        % Note we will not need to change the endpts becasue we will still
        % fit the data over the range 0:45:315. we simply pad the arrays to
        % better locate the peaks
        
        for cell = 1:numel(areasCell)
            cell
            [pks, indices] = findpeaks(areasCell{cell}, 'SORTSTR',...
                                        'descend');
            if numel(pks) < 2 % FIT A GAUSSIAN
                display(['Fitting a Gaussian to cell',num2str(cell)])
                % Perform Fit
                [fitParams{cell},xFit{cell},dataFit{cell}] = ...
                    fitData('gaussian',mapKeys, areasCell{cell});
                
            else % FIT A RELAXED DOUBLE GAUSSIAN
                display(['Fitting RELAXED double Gaussian to cell',...
                            num2str(cell)])
                % Perform Fit
                [fitParams{cell},xFit{cell},dataFit{cell}] = ...
                    fitData('relaxedDoubleGaussian',mapKeys,...
                                areasCell{cell});
            end
        end
end

