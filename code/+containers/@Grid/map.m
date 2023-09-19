function varargout = map(self, varargin)
    % Transforms (n) input grids into (m) output grids. All iterators must match.
    %
    %   grid = grid.map(mapFcn)
    %   grid = grid.map(mapFcn, errorFcn)
    %   [grid_1, ... grid_m] = map(grid_1, ... grid_n, mapFcn)
    %   [grid_1, ... grid_m] = map(grid_1, ... grid_n, mapFcn, errorFcn)
    %
    % See also containers.Grid

    % assign inputs
    other = cellfun(@(v) isa(v, class(self)), varargin);
    grids = [{self}, varargin(other)];
    varargin = varargin(not(other));
    
    % assign functions
    mapFcn = varargin{1};
    if numel(varargin) > 1
        errorFcn = varargin{2};
    else
        errorFcn = @silentRethrow;
    end

    % can only operate on compatible grids
    assert(iscompatible(grids{:}), "grid:InvalidInput", ...
        "Specified incompatible grids for map() to operate on. " + ...
        "Use [~, c] = iscompatible(grids) to figure out differences.");
    assert(all(cellfun(@isdistributed, grids) == isdistributed(self)), ...
        "grid:InvalidInput", "All grids must be distributed or none.");

    % make a local copy to prevent propagation of SELF into parallel workers
    dims = self.Dims;
    nDims = numel(dims);
    iter = self.Iter;
    sz = size(self);
    clear self

    % init output containers
    for k = 1:numel(grids)
        grids{k} = grids{k}.Data;
    end

    if nargin(mapFcn) < numel(grids)
        % with matrices, we can use arrayfun to cover all data points
        [varargout{1:nargout}] = arrayfun(@mapVec, grids{:}, 'Error', @mapVecError);
    elseif nargin(mapFcn) == numel(grids)
        % with matrices, we can use arrayfun to cover all data points
        [varargout{1:nargout}] = arrayfun(mapFcn, grids{:}, 'Error', errorFcn);
    elseif isstruct(iter)
        % iterator is already in struct array format
        [varargout{1:nargout}] = arrayfun(mapFcn, grids{:}, iter, 'Error', errorFcn);
    else
        % iterator will be computed from linear indices
        [varargout{1:nargout}] = arrayfun(@mapIt, reshape(1:prod(sz), sz), grids{:}, 'Error', @mapItError);
    end

    % reassign outputs to grids
    for k = 1:nargout
        varargout{k} = makegrid(varargout{k}, iter, dims);
    end

    % only local function below
    return

    function varargout = mapIt(k, varargin)
        [varargout{1:nargout}] = mapFcn(varargin{:}, iterator(k));
    end

    function varargout = mapItError(e, k, varargin)
        [varargout{1:nargout}] = errorFcn(e, varargin{:}, iterator(k));
    end

    function varargout = mapVec(varargin)
        [varargout{1:nargout}] = mapFcn([varargin{:}]);
    end
    
    function varargout = mapVecError(e, varargin)
        [varargout{1:nargout}] = errorFcn(e, [varargin{:}]);
    end

    function unused = silentRethrow(e, varargin) %#ok<STOUT>
        rethrow(e);
    end

    function it = iterator(k)
        subs = cell(1, nDims);
        [subs{:}] = ind2sub(sz, k);
        it = cellfun(@(it, kk) it(:, kk), iter, subs, 'Uniform', false);
        it = cell2struct(it, dims, 2);
    end
end

%#release exclude file
