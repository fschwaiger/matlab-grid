function self = where(self, keyOrValue, value)
    % Filters the grid using a value, the result is again a grid.
    %
    %   grid = grid.where(value)
    %   grid = grid.where(key = value)
    %
    % If the result from the filtering operation would result in a
    % non-rectangular grid, then the result will be a sparse grid.
    % A sparse grid has a single struct iterator with all possible
    % combinations of iterators.
    %
    % If you require more complex slicing using multiple fields,
    % then use the syntax `.slice(@fcn)` instead. 
    %
    % See also containers.Grid/sparse, containers.Grid/filter

    arguments
        self containers.Grid
        keyOrValue
        value = []
    end
    
    if nargin == 2
        self = slice(self, self.Data == keyOrValue);
    else
        self = slice(self, "." + string(keyOrValue), value);
    end
end

%#release exclude file
