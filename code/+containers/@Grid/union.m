function self = union(self, with, joinFcn, missingSelf, missingWith)
    % Outer joins two grids, the result is the combined superspace.
    %
    %   c = union(a, b)
    %   c = union(a, b, @(va, vb, iter) myJoinFcn(va, vb, iter))
    %   c = union(a, b, @myJoinFcn)
    %   c = union(a, b, @myJoinFcn, missing)
    %   c = union(a, b, @myJoinFcn, missingA, missingB)
    %
    % The 3rd input argument is a function handle to produce value
    % joins, both for pairwise element joins and reduce operations,
    % if dimension names overlap partially.
    %
    % Where the dimension names have no overlap, the original grids
    % will be repeated. Where dimensions match but iterators are not
    % the same, missing iterator values will be filled in with the
    % given <missing> scalar value. You can specify missing values
    % individually for both grids.
    %
    % See also containers.Grid/intersect, containers.Grid/join

    if nargin < 4
        missingSelf = feval(class(self.Data), nan);
    end

    if nargin < 5
        missingWith = missingSelf;
    end

    if nargin < 3
        joinFcn = @join;
    end

    % join with an array of grids
    if iscell(with)
        for grid = reshape(with, 1, [])
            self = union(self, grid{1}, joinFcn, missingSelf, missingWith);
        end
        return
    end

    % no need to continue, outer join with empty set is identity
    if isempty(self.Dims)
        self = with;
        return
    elseif isempty(with.Dims)
        return
    end

    % prevent downstream errors while not implemented
    if issparse(self) || issparse(with)
        error("grid:InvalidUse", "Sparse grid does not support union().");
    end

    % extend grids onto same dimensions
    self = extendDims(self, with);
    with = extendDims(with, self);
    with = permute(with, self.Dims);

    % extend grids onto same iterators
    self = extendIter(self, with, missingSelf);
    with = extendIter(with, self, missingWith);
    with = subsref(with, substruct('()', self.Iter));

    % join the grids element-wise
    self = map(self, with, joinFcn);

    function a = extendDims(a, b)
        % Extend the dimensions of "a" by the dimensions in "b".

        % these are the dimension indices to be added
        [~, added] = setdiff(b.Dims, a.Dims, 'stable');

        % if added were empty, extend() would add "x1" and "x2" dims
        for k = reshape(added, 1, [])
            a = extend(a, b.Dims(k), b.Iter{k});
        end
    end

    function a = extendIter(a, b, m)
        % Extend grid "a" with the iterator values in "b", or place "m".

        % these are the indexes for each iterator to add
        [iter, added] = cellfun(@mysetdiff, b.Iter, a.Iter, "Uniform", false);

        % extend one dimension at a time
        for k = find(not(cellfun(@isempty, iter)))
            % how many missing elements we may add
            nAllowedMissing = 1 - sum(ismissing(a.Iter{k}));

            % omit NaN if there already is a NaN in the array
            added{k}( ...
                ismissing(iter{k}) & ...
                cumsum(ismissing(iter{k})) > nAllowedMissing ...
            ) = [];

            % empty index array would lead to errors below
            if isempty(added{k})
                continue
            end

            % append to iterator array
            a.Iter{k} = [a.Iter{k}, b.Iter{k}(added{k})];

            % determine index for current dimension, make others ':'
            where = repmat({':'}, 1, ndims(a));
            where{k} = feval(@(s) s+1:s+numel(added{k}), size(a.Data, k));

            % assign missing value to extended dimension
            a.Data(where{:}) = m;
        end
    end

    function varargout = mysetdiff(a, b)
        if isstring(a) ~= isstring(b)
            a = string(a);
            b = string(b);
        end
        [varargout{1:nargout}] = setdiff(a, b);
    end
end

%#release exclude file
