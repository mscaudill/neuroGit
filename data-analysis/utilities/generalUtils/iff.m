function result = iff(test,trueVal,falseVal)
% iff is a conditional if function that can be used within an anonymous
% function. It is useful because matlab does not offer a conditional
% function call for anonymous functions. For example, lets say you have a
% cell array { [array1] [array2] ...} and you would like to calculate
% sin(x)/x for each cell without writing a new function. If you try
% cellfun(@(p) sinc(p), cell array) you might have an error if any of the
% cells contain 0s. So we want a conditional anonymous function call like
% this cellfun(@(p) iff(p,0,sinc(p)), cell array) where the value 0 is
% placed if p = 0;
test
if test
    result = trueVal;
else
 	result = falseVal;
end



end


