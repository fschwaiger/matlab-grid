function indices = values2indices(self, values)
    % convert values into index arrays by search

    iter = self.Iter;
    assert(numel(values) == numel(iter), "grid:InvalidInput", ...
        "Number of slice values must match number of grid dimensions.");
    indices = cellfun(@findorall, iter, values, 'UniformOutput', false);

    function indices = findorall(iter, values)
        % either finds the value in 'iter', or specifies all with ':'

        if ischar(values) && strcmp(values, ':')
            indices = ':';
        else
            indices = arrayfun(@(k) findnaneq(iter, values(:, k)), 1:size(values, 2));
        end
    end

    function index = findnaneq(array, search)
        % either finds a value by equality, or a missing value

        index = ismissing(search) & ismissing(array) | array == search;
        index = find(all(index, 1));

        assert(not(isempty(index)), "grid:InvalidInput", ...
            "Cannot select nonexisting iterator values.");
    end
end

%#release exclude file
