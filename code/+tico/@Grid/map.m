function varargout = map(self, varargin)
    % Transforms (n) input grids into (m) output grids. All iterators must match.
    %
    %   grid = grid.map(mapFcn)
    %   grid = grid.map(mapFcn, errorFcn)
    %   [grid_1, ... grid_m] = map(grid_1, ... grid_n, mapFcn)
    %   [grid_1, ... grid_m] = map(grid_1, ... grid_n, mapFcn, errorFcn)
    %
    % See also tico.Grid

    % assign inputs
    other = cellfun(@(v) isa(v, class(self)), varargin);
    grids = [{self}, varargin(other)];
    varargin = varargin(not(other));
    mapFcn = varargin{1};
    if numel(varargin) > 1
        errorFcn = varargin{2};
    end

    % can only operate on compatible grids
    assert(iscompatible(grids{:}), "tico:InvalidInput", ...
        "Specified incompatible grids for map() to operate on. " + ...
        "Use [~, c] = iscompatible(grids) to figure out differences.");

    % init output containers
    grids = cellfun(@(grid) grid.Data, grids, 'Uniform', false);
    varargout = cell(1, nargout);

    if nargin(mapFcn) < numel(grids)
        % with matrices, we can use arrayfun to cover all data points
        if exist('errorFcn', 'var')
            [varargout{:}] = arrayfun(@(varargin) mapFcn([varargin{:}]), grids{:}, 'ErrorHandler', @(e, varargin) errorFcn(e, [varargin{:}]));
        else
            [varargout{:}] = arrayfun(@(varargin) mapFcn([varargin{:}]), grids{:});
        end
    elseif nargin(mapFcn) == numel(grids)
        % with matrices, we can use arrayfun to cover all data points
        if exist('errorFcn', 'var')
            [varargout{:}] = arrayfun(mapFcn, grids{:}, 'ErrorHandler', errorFcn);
        else
            [varargout{:}] = arrayfun(mapFcn, grids{:});
        end
    elseif issparse(self)
        % iterator is already in struct array format

        iter = self.Iter;
        if isdistributed(grids{1})
            iter = distributed(iter);
        end

        if exist('errorFcn', 'var')
            [varargout{:}] = arrayfun(mapFcn, grids{:}, iter, 'ErrorHandler', errorFcn);
        else
            [varargout{:}] = arrayfun(mapFcn, grids{:}, iter);
        end
    else
        % blow up the iterator arrays to matrices
        iterators = cell(1, ndims(self));
        [iterators{:}] = ndgrid(self.Iter{:});

        if isdistributed(grids{1})
            iterators = cellfun(@distributed, iterators, 'Uniform', false);
        end

        % make a local copy to prevent propagation of SELF into parallel workers
        dimNames = self.Dims;
        nData = numel(grids);

        % assign the data values as individual inputs, followed by the key as a struct
        mapWithKeyValue = @(varargin) mapFcn(varargin{1:nData}, cell2struct(varargin(nData+1:end), dimNames, 2));

        if exist('errorFcn', 'var')
            mapErrorWithKey = @(e, varargin) errorFcn(e, varargin{1:nData}, cell2struct(varargin(nData+1:end), dimNames, 2));
            [varargout{:}] = arrayfun(mapWithKeyValue, grids{:}, iterators{:}, 'ErrorHandler', mapErrorWithKey);
        else
            [varargout{:}] = arrayfun(mapWithKeyValue, grids{:}, iterators{:});
        end
    end

    % reassign outputs to grids
    varargout = cellfun(@(data) subsasgn(self, substruct('.', 'Data'), data), varargout, 'Uniform', false); %#ok
end

%#release exclude file
