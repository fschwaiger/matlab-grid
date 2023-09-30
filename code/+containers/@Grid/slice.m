function self = slice(self, varargin)
    % Extracts a subspace from this grid using indices or masks.
    %
    %   grid = slice(grid, 1:4, 4:5, :)
    %   grid = slice(grid, [true, true], [true, false])
    %
    % See also containers.Grid/partition

    args = subs2args(self, varargin);

    if isscalar(args) && islogical(args{1}) && ndims(self) > 1
        % cache set of all dimensions iterator
        dims = 1:ndims(self);
        mask = args{1};

        % cell of logical masks for all dimensions
        args = arrayfun(@(iDim) reshape(any(mask, setdiff(dims, iDim)), 1, []), dims, 'Uniform', false);

        % would produce a wrong result if non-rectangular
        if not(all(mask(args{:}), 'all'))
            self = sparse(self);
            args = {mask};
        end
    end

    if issparse(self) || (isscalar(args) && ndims(self) > 1)
        self = sparse(self);
        self.Iter = self.Iter(args{:});
        self.Data = self.Data(args{:});
        return
    end

    % slice the iterators independently, each one according to the respective indexer
    self.Iter = cellfun(@(iter, arg) iter(:, arg), self.Iter, args, 'Uniform', false);

    % slice the data according to the given indices
    self.Data = self.Data(args{:});
end

%#release exclude file
