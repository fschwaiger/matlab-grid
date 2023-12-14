function self = collapse(self, dims, reduceFcn)
    % Removes the given dimensions from the grid, using a reduction function.
    %
    %    grid = grid.collapse(dimensionNames, reduceFcn)
    %    grid = grid.collapse(dimensionIndex, reduceFcn)
    %
    % The reduction function must accept vector or matrix inputs. When you
    % collapse a single dimension, the input will be an array. When you
    % collapse 2 dimensions at the same time, it will be a 2D matrix, ...
    % Then the reduction function must return a scalar output value. Some
    % examples for valid reduction functions are:
    %
    %   @mean (only when collapsing a single dimension)
    %   @(x) mean(x, 'all')
    %   @(x) sum(x, 'all')
    %   @(x) max(x, [], 'all')
    %   @join
    %
    % An example where a single dimension is collapsed:
    %
    %    grid = containers.Grid([], {1:8, 1:9, 1:10}, ["a", "b", "c"])
    %    grid = grid.collapse("c", @mean)
    %
    % See also containers.Grid/retain

    if isempty(dims)
        % prevent running reduceFcn on each scalar value below
        return
    end
    
    % the user can specify dimension indices OR strings OR logical mask
    if islogical(dims)
        dims = find(dims);
    end

    % the user can specify dimension indices OR strings OR logical mask
    if not(isnumeric(dims))
        dims = string(dims);
        dims = arrayfun(@(d) find(ismember(self.Dims, d)), dims, "Uniform", false);
        dims = [dims{:}];
    end

    % special solution to collapse singular dimensions, faster than arrayfun
    if nargin < 3
        assert(all(size(self, dims) == 1), "grid:InvalidUse", ...
            "Cannot collapse dimensions with size > 1 without a reduction function.");

        if issparse(self)
            self.Iter = rmfield(self.Iter, self.Dims(dims));
        else
            self.Data = permute(self.Data, [setdiff(1:ndims(self), dims), dims]);
            self.Iter(dims) = [];
            self.Dims(dims) = [];
        end

        return
    end

    % sparse solution
    if issparse(self)
        values = rmfield(self.Iter, self.Dims(dims));
        groups = zeros(size(values));
        reduced = [];
        indices = 1:numel(values);
        nGroups = 1;
        while not(isempty(values))
            c = values(1);
            mask = arrayfun(@(v) isequaln(c, v), values);
            groups(indices(mask)) = nGroups;
            values(mask) = [];
            indices(mask) = [];
            nGroups = nGroups + 1;
            reduced = [reduced; c]; %#ok
        end

        self.Iter = reduced;
        self.Data = splitapply(reduceFcn, self.Data, groups);
        return
    end

    % non-sparse solution
    nDim = ndims(self);
    cols = repmat({':'}, 1, nDim);

    resultSize = size(self);
    resultSize(dims) = 1;
    mm = ismember(1:nDim, dims);
    subs = cell(1, nDim);

    function r = reduceOne(k)
        [subs{:}] = ind2sub(resultSize, k);
        subs(mm) = cols(mm);
        r = reduceFcn(self.Data(subs{:}));
    end

    result = arrayfun(@reduceOne, reshape(1:prod(resultSize), resultSize));
    self.Data = permute(result, [setdiff(1:ndims(self), dims), dims]);

    % remove the collapsed dimensions
    self.Iter(dims) = [];
    self.Dims(dims) = [];
end

%#release exclude file
