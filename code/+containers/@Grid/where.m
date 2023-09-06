function self = where(self, value)
    % Filters the grid using a value, the result is again a grid.
    %
    %   grid = grid.where(value)
    %
    % If the result from the filtering operation would result in a
    % non-rectangular grid, then the result will be a sparse grid.
    % A sparse grid has a single struct iterator with all possible
    % combinations of iterators.
    %
    % See also containers.Grid/sparse, containers.Grid/filter

    arguments
        self containers.Grid
        value (1,1)
    end

    self = slice(self, self.Data == value);
end

%#release exclude file
