function self = retain(self, dims, reduceFcn)
    % Reduces the grid to given dimensions using a reducer.
    %
    %    grid = grid.retain(dimensionNames, reduceFcn)
    %    grid = grid.retain(dimensionIndex, reduceFcn)
    %
    % The reduction function must accept vector or matrix inputs. When you
    % collapse a single dimension, the input will be an array. When you
    % collapse 2 dimensions at the same time, it will be a 2D matrix, ...
    % Then the reduction function must return a scalar output value. Some
    % examples for valid reduction functions are:
    %
    %   @mean (only when collapsing a single dimension)
    %   @(x) mean(x, "all')
    %   @(x) sum(x, 'all')
    %   @(x) max(x, [], 'all')
    %   @join
    %
    % An example where only two dimensions are retained:
    %
    %    grid = containers.Grid([], {1:8, 1:9, 1:10}, ["a", "b", "c"])
    %    grid = grid.retain(["b", "c"], @mean)
    %
    % See also containers.Grid/collapse`

    % the user can specify dimension indices as logical array
    if islogical(dims)
        if numel(dims) ~= ndims(self)
            error("grid:InvalidInput", "Cannot retain() with logical: array has %d " + ...
                "entries, but grid has %d dimensions.", numel(dims), ndims(self));
        end
        dims = find(dims);
    end

    % the user can specify dimension indices OR strings
    if not(isnumeric(dims))
        dims = string(dims);
        if ~all(ismember(dims, self.Dims))
            error("grid:InvalidInput", "Unknown dimension(s) %s, check for typos. " + ...
                "Grid has dimensions: %s.", jsonencode(setdiff(dims, self.Dims)), jsonencode(self.Dims));
        end
        dims = arrayfun(@(d) find(ismember(self.Dims, d)), dims);
    end

    if min(dims) < 1 || max(dims) > ndims(self)
        error("grid:InvalidInput", "Dimension index %d out of bounds.", find(dims < 1 | dims > ndims(self), 1));
    end

    % these are the dimensions we need to collapse
    dimsToCollapse = setdiff(1:ndims(self), dims);
    self = collapse(self, dimsToCollapse, reduceFcn);

    % reorder, so that result matches order of input dims
    if issparse(self)
        [~, order] = sort(dims);
        self.Iter = orderfields(self.Iter, order);
    else
        [~, order] = sort(dims);
        order(order) = 1:numel(order);
        withAtLeastNdims = 1:ndims(self.Data);
        withAtLeastNdims(1:numel(order)) = order;
        self.Data = permute(self.Data, withAtLeastNdims);
        self.Iter = self.Iter(order);
        self.Dims = self.Dims(order);
    end
end

%#release exclude file
