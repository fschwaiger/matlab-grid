function indices = values2indices(self, values)
    % convert values into index arrays by search

    iter = self.Iter;
    dims = self.Dims;
    assert(numel(values) == numel(dims), "grid:InvalidInput", ...
        "Number of slice values must match number of grid dimensions.");

    if issparse(self)
        indices = cellfun(@findIndicesOrReturnColonForSparse, dims, values, 'Uniform', 0);
        for k = 2:numel(indices)
            indices{1} = intersect(indices{1}, indices{k}, 'stable');
        end
        indices = indices(1);
    else
        indices = cellfun(@findIndicesOrReturnColonForDense, iter, values, 'Uniform', 0);
    end
    
    function indices = findIndicesOrReturnColonForSparse(d, v)
        % either finds the value in 'iter', or specifies all with ':'

        assert(iscolumn(v), "grid:InvalidInput", ...
            "Sparse grids can only be sliced with a single value per dimension.");
        
        if isequal(v, ':')
            indices = 1:numel(iter);
        else
            indices = findIndicesWithNanEquality([iter.(d)], v);
        end
    end

    function indices = findIndicesOrReturnColonForDense(it, v)
        % either finds the value in 'it', or specifies all with ':'

        if ischar(v) && strcmp(v, ':')
            indices = ':';
        else
            indices = arrayfun(@(k) findIndicesWithNanEquality(it, v(:, k)), ...
                1:size(v, 2), "Uniform", false);
            indices = [indices{:}];
        end
    end

    function index = findIndicesWithNanEquality(array, search)
        % either finds a value by equality, or a missing value

        index = ismissing(search) & ismissing(array) | array == search;
        index = find(all(index, 1));
    end
end

%#release exclude file
