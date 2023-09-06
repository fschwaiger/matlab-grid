function [tf, index] = contains(self, value, varargin)
    % Returns whether it contains the given value (at iterator).
    %
    %   [tf, index] = grid.contains(value, iteratorAsCell)
    %   [tf, index] = grid.contains(value, iteratorAsStruct)
    %   [tf, index] = grid.contains(value, name1, value1, ...)
    %
    % Example:
    %
    %   tf = grid.contains(tico.TestStatus.Success)
    %   tf = grid.contains(tico.TestStatus.Success)
    %   tf = grid.contains(tico.TestStatus.Success, "Flaps", "up")
    %   tf = grid.contains(tico.TestStatus.Success, "up")
    %   tf = grid.contains(tico.TestStatus.Success, {"up"})
    %   tf = grid.contains(tico.TestStatus.Success, struct("flaps", "up"))
    %
    % See also containers.Grid/find

    if nargin == 3 && iscell(varargin{1})
        varargin = varargin{1};
    end

    [mask, index] = find(subsref(self, substruct('()', varargin)), @(x) isequal(x, value));
    tf = any(mask, 'all');
end

%#release exclude file
