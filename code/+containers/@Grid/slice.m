function [self, args] = slice(self, varargin)
    % Extracts a subspace from this grid using indices or masks.
    %
    %   grid = slice(grid, 1:4, 4:5, :)
    %   grid = slice(grid, [true, true], [true, false])
    %   grid = slice(grid, mask)
    %   [grid, mask] = slice(grid, ...)
    %
    % See also containers.Grid/partition

    % this line does the magic of supporting all kinds of indexing
    args = subs2args(self, varargin);
    dims = 1:ndims(self);
    nDim = numel(dims);
    
    % empty grid
    if nDim == 0
        return
    end

    if isscalar(args) && islogical(args{1}) && nDim > 1
        % cache set of all dimensions iterator
        mask = args{1};
        mask = reshape(mask, size(self.Data));

        % cell of logical masks for all dimensions
        args = arrayfun(@(iDim) reshape(any(mask, setdiff(dims, iDim)), 1, []), dims, 'Uniform', false);

        % would produce a wrong result if non-rectangular
        if not(all(mask(args{:}), 'all'))
            self = sparse(self);
            args = {mask};
        end
    end

    % sparse grid can already do a linear index
    if issparse(self) || (isscalar(args) && nDim > 1) 
        self = sparse(self);
        self.Iter = self.Iter(args{:});
        self.Data = self.Data(args{:});
        return
    end

    % slice each iterator according to the index in its own dimension
    self.Iter = cellfun(@(iter, subscript) iter(:, subscript), self.Iter, args, 'Uniform', false);

    % slice the data according to the given indices, in n-D this keeps the shape
    self.Data = self.Data(args{:});
end

%#release exclude file
