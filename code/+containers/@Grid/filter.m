function self = filter(self, fcn)
    % Filters the grid using a closure, the result is again a grid.
    %
    %   grid = grid.filter()
    %
    % If the result from the filtering operation would result in a
    % non-rectangular grid, then the result will be a sparse grid.
    % A sparse grid has a single struct iterator with all possible
    % combinations of iterators.
    %
    % Example:
    %
    %   grid = grid.filter(@(ts) ts == tico.TestStatus.Error)
    %
    % See also containers.Grid/sparse, containers.Grid/reject

    arguments
        self containers.Grid
        fcn (1,1) function_handle = @(x) x ~= 0
    end

    % define logical mask from user function
    mask = map(self, fcn).Data;
    assert(islogical(mask), "grid:InvalidInput", ...
        "Filter function handle must return a scalar logical.");

    % apply the logical mask
    self = slice(self, mask);
end

%#release exclude file
