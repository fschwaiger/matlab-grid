function varargout = map(self, varargin)
    % Transforms (n) input grids into (m) output grids. All iterators must match.
    %
    %   grid = grid.map(mapFcn)
    %   grid = grid.map(mapFcn, nargin)
    %   [grid_1, ... grid_m] = map(grid_1, ... grid_n, mapFcn)
    %   [grid_1, ... grid_m] = map(grid_1, ... grid_n, mapFcn, nargin)
    %
    % The hint for nargin is optional. If not specified, the number of input
    % arguments is determined from the function handle. If specified, the number
    % of input arguments must match the number of input grids. Use this for
    % functions like `mean`, that have more than one input argument, but can
    % operate on a single input:
    %
    %   grid = map(grid1, grid2, @mean, 1)
    %   
    % See also containers.Grid

    % assign inputs
    other = cellfun(@(v) isa(v, class(self)), varargin);
    grids = [{self}, varargin(other)];
    varargin = varargin(not(other));
    mapFcn = varargin{1};
    if numel(varargin) > 1
        nInputs = varargin{2};
    else
        nInputs = nargin(mapFcn);
    end

    % can only operate on compatible grids
    assert(iscompatible(grids{:}), "grid:InvalidInput", ...
        "Specified incompatible grids for map() to operate on. " + ...
        "Use [~, c] = iscompatible(grids) to figure out differences.");
    
    % if we have multiple grids, all must be distributed or none
    assert(not(exist('isdistributed', 'file')) || ...
        all(cellfun(@isdistributed, grids) == isdistributed(self)), ...
        "grid:InvalidInput", "All grids must be distributed or none.");

    % make a local copy to prevent propagation of SELF into parallel workers
    dims = self.Dims;
    nDims = numel(dims);
    iter = self.Iter;
    sz = size(self);

    % init output containers
    for k = 1:numel(grids)
        grids{k} = grids{k}.Data;
    end
    
    % if we run the arrayfun below in a distributed environment, then MATLAB will
    % broadcast the current grid to all workers because of the closures below.
    % We can avoid serializing and broadcasting the entire grid data by unsetting
    % the Data property. We will replace it with the correct data later.
    self.Data = [];

    if nInputs < numel(grids)
        % with matrices, we can use arrayfun to cover all data points
        [varargout{1:nargout}] = arrayfun(@mapAsVector, grids{:});
    elseif nInputs == numel(grids)
        % with matrices, we can use arrayfun to cover all data points
        [varargout{1:nargout}] = arrayfun(mapFcn, grids{:});
    elseif isstruct(iter)
        % iterator is already in struct array format
        [varargout{1:nargout}] = arrayfun(mapFcn, grids{:}, iter);
    else
        % iterator will be computed from linear indices
        [varargout{1:nargout}] = arrayfun(@mapWithIter, reshape(1:prod(sz), [sz, 1, 1]), grids{:});
    end

    % reassign outputs to grids
    for k = 1:nargout
        self.Data = varargout{k};
        varargout{k} = self;
    end

    % only local functions below
    return

    function varargout = mapWithIter(k, varargin)
        [varargout{1:nargout}] = mapFcn(varargin{:}, iterator(k));
    end

    function varargout = mapAsVector(varargin)
        [varargout{1:nargout}] = mapFcn([varargin{:}]);
    end

    function it = iterator(k)
        subs = cell(1, nDims);
        [subs{:}] = ind2sub(sz, k);
        it = struct();
        for iDim = 1:nDims
            it.(dims(iDim)) = iter{iDim}(:, subs{iDim});
        end
    end
end

%#release exclude file
