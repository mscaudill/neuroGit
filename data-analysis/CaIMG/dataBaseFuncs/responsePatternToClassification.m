function [ classifications ] = responsePatternToClassification(...
                                                        responsePatterns )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
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


%generate all possible binary patterns
n=5;
D = [0:2^n-1]';
allClassifications = rem(floor(D*pow2(-(n-1):0)),2);


for index = 1:numel(responsePatterns)
    switch responsePatterns(index)
        case 1
            matchedIndices = (allClassifications(:,1)==0 &...
                              allClassifications(:,2)==0 &...
                              allClassifications(:,3)==0 &...
                              allClassifications(:,4)==0 &...
                              allClassifications(:,5)==0);
                         
           classes = allClassifications(matchedIndices,:);
           classifications{index} = mat2cell(classes,...
                                        ones(1,size(classes,1)),5);
           
        case 2
            matchedIndices = (allClassifications(:,1)==1 &...
                              allClassifications(:,2)==0 &...
                              allClassifications(:,3)==0 &...
                              allClassifications(:,4)==0 &...
                              allClassifications(:,5)==0);
                          
            classes = allClassifications(matchedIndices,:);
            classifications{index} = mat2cell(classes,...
                                        ones(1,size(classes,1)),5);
            
        case 3
            matchedIndices = (allClassifications(:,1)==0 &...
                              (allClassifications(:,2)|...
                              allClassifications(:,3)==1) &...
                              allClassifications(:,5)==0);
                          
            classes = allClassifications(matchedIndices,:);
            classifications{index} = mat2cell(classes,...
                                        ones(1,size(classes,1)),5);
            
        case 4
            matchedIndices = (allClassifications(:,1)==1 &...
                              (allClassifications(:,2)|...
                              allClassifications(:,3)==1) &...
                              allClassifications(:,5)==0);
                          
            classes = allClassifications(matchedIndices,:);
            classifications{index} = mat2cell(classes,...
                                        ones(1,size(classes,1)),5);
            
        case 5
            matchedIndices = (allClassifications(:,5)==1); 
                
            classes = allClassifications(matchedIndices,:);
            classifications{index} = mat2cell(classes,...
                                        ones(1,size(classes,1)),5);
                         
    end
end

% concatenate all the classifications together
classifications = vertcat(classifications{:});
