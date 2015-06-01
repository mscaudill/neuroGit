function [ trials ] = SingleAngleCSTrialsStruct(stimType, table)

conditions = {'centerAlone', 'iso', 'cross1', 'cross2', 'surroundAlone'};

if table{5,2}
    conditions = conditions(randperm(numel(conditions)));
end

for condition = 1:numel(conditions)
    trials(condition).Stimlulus_Type = stimType;
    trials(condition).Mask_Outer_Diameter = table{1,2};
    trials(condition).Center_Grating_Diameter = table{2,2};
    trials(condition).Center_Orientation = table{3,2};
    trials(condition).Timing = [table{4,2:end}];
    trials(condition).Randomize = table{5,2};
    [trials(condition).Condition] = conditions{condition};
end
trials = trials';
end

