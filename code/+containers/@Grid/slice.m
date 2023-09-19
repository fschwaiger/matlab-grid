function self = slice(self, varargin)
    % Extracts a subspace from this grid using indices or masks.
    %
    %   grid = slice(grid, 1:4, 4:5, :)
    %   grid = slice(grid, [true, true], [true, false])
    %
    % See also containers.Grid/partition

    % allow user to slice via logical indexing function
    if nargin == 2 && isa(varargin{1}, 'function_handle')
        self = subsref(self, substruct('()', varargin));
        return
    end

    % do not index at all
    if nargin == 1
        return
    end

    if issparse(self)

        % cannot run the code below or 'setdiff' would produce []
        self.Iter = self.Iter(varargin{1});
        self.Data = self.Data(varargin{1});

    elseif nargin == 2 && islogical(varargin{1}) && ndims(self) > 1

        % cache set of all dimensions iterator
        dims = 1:ndims(self);
        mask = varargin{1};

        % cell of logical masks for all dimensions
        split = arrayfun(@(iDim) reshape(any(mask, setdiff(dims, iDim)), 1, []), dims, 'Uniform', false);

        % would produce a wrong result if non-rectangular
        if not(all(mask(split{:}), 'all'))
            self = sparse(self);
            split = {mask};
        end

        % apply the slice
        self = slice(self, split{:});
        
    elseif isscalar(varargin) && ndims(self) > 1
        
        % select as sparse in correct order
        self = sparse(self);
        self.Iter = self.Iter(varargin{1});
        self.Data = self.Data(varargin{1});
        
    else

        % slice the iterators independently, each one according to the respective indexer
        self.Iter = cellfun(@(iter, arg) iter(:, arg), self.Iter, varargin, 'Uni', false);

        % slice the data according to the given indices
        self.Data = self.Data(varargin{:});

    end
end

%#release exclude file
