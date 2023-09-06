function varargout = partition(self, N)
    % Splits grid into multiple parts.
    %
    %   partitions = grid.partition(3)
    %   [p1, p2, p3] = grid.partition()
    %   [myVarIs5, other] = grid.partition(@(key) key.myVar == 5)
    %   [a, b, c] = grid.partition(@(key) ismember(["a", "b", "c"], key.abc))
    %   [a, b, c] = grid.partition(@(key) find(ismember(["a", "b", "c"], key.abc)))
    %
    % The number of partitions is optional and if omitted, inferred from the
    % number of output arguments.
    %
    % See also distributed

    if nargin < 2
        % assume N from number of requested outputs
        N = nargout;
    end

    if isa(N, 'function_handle')
        % specify splits dynamically
        [varargout{1:nargout}] = partitionByFunction(self, N);
    else
        % specify splits automatically
        [varargout{1:nargout}] = partitionIntoEqualParts(self, N);
    end

    function varargout = partitionByFunction(grid, fcn)
        % Partitions the grid by an indexing function.

        % apply user partitioning function, return either numerical, or {logical}
        mask = grid.map(fcn).Data;

        if iscell(mask)
            % user returned a logical array with one element 'true'
            % cellfun() will fail if more that one element was 'true'
            nParts = numel(mask{1});
            mask = cellfun(@find, mask);
        elseif islogical(mask)
            % user returned a logical scalar, output 'true' into first output
            nParts = 2;
            mask = 2 - mask;
        else
            % user returned an index
            assert(isnumeric(mask), "tico:InvalidInput", ...
                "Partitioning function returned a non-numerical value, should be index.");
            nParts = max(mask, [], 'all');
        end

        varargout = arrayfun(@(iPart) {slice(grid, mask == iPart)}, 1:nParts);
    end

    function varargout = partitionIntoEqualParts(grid, N)
        % Partitions the grid into N mostly equal parts.

        mySize = size(grid);
        [mySize, largest] = sort(mySize);
        factors = factor(N);

        % there might be more factors than dimensions, collapse until same
        while numel(factors) > numel(mySize)
            factors(1) = factors(1) * factors(end);
            factors(end) = [];
        end

        % now we want to repeatedly split the largest dimension by the largest factor
        iDim = numel(mySize);
        splits = num2cell(mySize);
        for iFactor = flip(1:numel(factors))
            % best fit for split
            split = floor(mySize(iDim) / factors(iFactor));
            assert(split > 0);
            % mat2cell needs an array of these splits
            split = repmat(split, 1, factors(iFactor));
            % the last split will be increased to account for rounding
            split(end) = split(end) + mySize(iDim) - (split(end) * factors(iFactor));
            % split the matrix along the iDim-th largest dimension
            splits{iDim} = split;
            % use next largest dimension
            iDim = iDim - 1;
        end

        % undo sorting of cell array
        splits(largest) = splits;

        % split the nd space into (N) parts
        d = mat2cell(grid.Data, splits{1:ndims(grid.Data)});
        n = ndims(grid);

        % also do the same with the iterators
        iters = cell(1, n);
        [iters{:}] = ndgrid(grid.Iter{:});
        iters = cellfun(@(iter) mat2cell(iter, splits{:}), iters, 'Uni', false);

        % create an array of grid from the current one as prototype, and
        % make it empty before duplication, could exhaust memory else
        grid.Data = [];
        varargout = repmat({grid}, 1, numel(d));

        % assign the data and iterator slices to each partition
        for k = 1:numel(d)
            varargout{k}.Data = d{k};
            varargout{k}.Iter = arrayfun(@(l) kthDim(iters{l}{k}, l), 1:n, 'Uni', false);
        end
    end

    function v = kthDim(v, k)
        % KTHDIM - helper function to extract values across a given dimension

        subs = num2cell(ones(1, ndims(v)));
        subs{k} = ':';
        v = reshape(v(subs{:}), 1, []);
    end
end

%#release exclude file
