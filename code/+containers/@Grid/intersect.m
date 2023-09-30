function self = intersect(self, with, joinFcn, reduceFcnSelf, reduceFcnWith)
    % Inner joins two grids, the result is the common subspace.
    %
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
    % See also containers.Grid/union, containers.Grid/join

    if nargin < 4
        reduceFcnSelf = joinFcn;
    end

    if nargin < 5
        reduceFcnWith = reduceFcnSelf;
    end

    % prevent downstream errors while not implemented
    if issparse(self) || issparse(with)
        error("grid:InvalidUse", "Sparse grid does not support intersect().");
    end

    % return an empty grid if there is no overlap on dimensions
    dims = intersect(self.Dims, with.Dims);
    if isempty(dims)
        self.Data = self.Data([]);
        self.Iter = {};
        self.Dims = strings(1, 0);
        return
    end

    % force onto same dimensions
    self = retain(self, dims, reduceFcnSelf);
    with = retain(with, dims, reduceFcnWith);

    % force onto same iterators
    iter = cellfun(@intersect, self.Iter, with.Iter, "Uniform", false);
    args = [cellstr(self.Dims); iter];
    self = slice(self, args{:});
    with = slice(with, args{:});

    % join the grids element-wise
    self = map(self, with, joinFcn);
end

%#release exclude file
