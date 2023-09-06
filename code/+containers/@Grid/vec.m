function varargout = vec(self, varargin)
    % Vectorized map() function.
    %
    %   grid = grid.vec(mapFcn)
    %   [grid_1, ... grid_m] = vec(grid_1, ... grid_n, mapFcn)
    %
    % See also containers.Grid/map

    other = cellfun(@(v) isa(v, class(self)), varargin);
    grids = [{self}, varargin(other)];
    varargin = varargin(not(other));

    % can only operate on compatible grids
    assert(iscompatible(grids{:}), "tico:InvalidInput", ...
        "Specified incompatible grids for vec() to operate on. " + ...
        "Use [~, c] = iscompatible(grids) to figure out differences.");

    % init output containers
    grids = cellfun(@(grid) grid.Data, grids, 'Uniform', false);
    varargout = cell(1, nargout);

    % apply vector function
    [varargout{:}] = varargin{1}(grids{:}, varargin{2:end});

    % reassign outputs to grids
    varargout = cellfun(@(data) subsasgn(self, substruct('.', 'Data'), data), varargout, 'Uniform', false); %#ok
end

%#release exclude file
