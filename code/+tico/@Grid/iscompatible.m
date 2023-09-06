function [isCompatible, areCompatible] = iscompatible(self, varargin)
    % Returns true if all array elements have equal Iter and Dims.

    % check for 2nd...last grid if they are compatible with first
    areCompatible = cellfun( ...
        @(g) isequaln(self.Iter, g.Iter) && isequaln(self.Dims, g.Dims), ...
        varargin ...
    );

    % the 1st is always compatible with itself
    areCompatible = [true; areCompatible(:)]';

    % return as a scalar
    isCompatible = all(areCompatible, 'all');
end

%#release exclude file
