function [tf, index] = contains(self, value)
    % Returns whether it contains the given value.
    %
    %   [tf, index] = grid.contains(value)
    %
    % Example:
    %
    %   tf = grid.contains(tico.TestStatus.Success)
    %
    % See also containers.Grid/find

    [mask, index] = find(self, @(x) isequal(x, value));
    tf = any(mask, 'all');
end

%#release exclude file
