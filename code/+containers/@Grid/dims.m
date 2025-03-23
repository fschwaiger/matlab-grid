function self = dims(self, dim, new)
    % Read or write dimension names.
    %
    %    grid.dims()
    %    grid.dims(dim)
    %    grid.dims(old = new)
    %
    % When no arguments are given, the function returns the names of all
    % dimensions. When a single argument is given, the function updates
    % the dimension names with the given values. When two arguments are
    % given, the function updates the dimension names with the new values
    % for the dimensions specified by the old values.
    %
    % DIMS Inputs:
    %    dim  -  Dimension names to update.
    %    new  -  New dimension names. If not given, all dimension names are
    %            updated dfrom `dim`.
    %
    % DIMS Outputs:
    %    self  -  Updated grid object, or the dimension names if no arguments
    %             are given.
    %
    % See also containers.Grid

    arguments
        self
        dim (1, :) string = []
        new (1, :) string = []
    end

    if isempty(dim)
        self = self.Dims;
    elseif isempty(new)
        assert(numel(dim) == numel(self.Dims), 'grid:InvalidInput', 'Number of dimensions must match');
        self.Dims = dim;
    else
        k = self.Dims == dim;
        self.Dims(k) = new;
    end
end

%#release exclude file
