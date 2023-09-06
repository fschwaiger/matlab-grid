function self = intersect(self, with, joinFcn, reduceFcnSelf, reduceFcnWith)
    % Inner joins two grids, the result is the common subspace.
    %
    %   c = intersect(a, b)
    %   c = intersect(a, b, @(va, vb, iter) myJoinFcn(va, vb, iter))
    %   c = intersect(a, b, @myJoin)
    %   c = intersect(a, b, @myJoin, @myReduce)
    %   c = intersect(a, b, @myJoin, @myReduceA, @myReduceB)
    %
    % This will produce an empty grid if the dimension names mismatch
    % or the dimension iterators have no overlap.
    %
    % The 3rd input argument is a function handle to produce value
    % joins, both for pairwise element joins and reduce operations,
    % if dimension names overlap partially.
    %
    % See also tico.Grid/union, tico.Grid/join

    if nargin < 3
        joinFcn = @join;
    end

    if nargin < 4
        reduceFcnSelf = @join;
    end

    if nargin < 5
        reduceFcnWith = reduceFcnSelf;
    end
    % join with an array of grids
    if iscell(with)
        for grid = reshape(with, 1, [])
            self = intersect(self, grid{1}, joinFcn, reduceFcnSelf, reduceFcnWith);
        end
        return
    end

    % prevent downstream errors while not implemented
    if issparse(self) || issparse(with)
        error("tico:InvalidUse", "Sparse grid does not support intersect().");
    end

    % return an empty grid if there is no overlap on dimensions
    dims = intersect(self.Dims, with.Dims);
    if isempty(dims)
        self.Data = self.Data([]);
        self.Iter = {};
        self.Dims = [];
        return
    end

    % force onto same dimensions
    self = retain(self, dims, reduceFcnSelf);
    with = retain(with, dims, reduceFcnWith);

    % force onto same iterators
    iter = cellfun(@intersect, self.Iter, with.Iter, "Uniform", false);
    self = subsref(self, substruct('()', iter));
    with = subsref(with, substruct('()', iter));

    % join the grids element-wise
    self = map(self, with, joinFcn);
end

%#release exclude file
