function indices = values2indices(self, values)
    % convert values into index arrays by search

    assert(numel(values) == numel(self.Iter), "tico:InvalidInput", ...
        "Number of slice values must match number of grid dimensions.");
    indices = cellfun(@findorall, self.Iter, values, 'UniformOutput', false);

    function indices = findorall(iter, values)
        % either finds the value in 'iter', or specifies all with ':'

        if ischar(values) && strcmp(values, ':')
            indices = ':';
        else
            indices = arrayfun(@(value) findnaneq(iter, value), values);
        end
    end

    function index = findnaneq(array, search)
        % either finds a value by equality, or a missing value

        if ismissing(search)
            index = find(ismissing(array));
        else
            index = find(array == search);
        end

        assert(not(isempty(index)), "tico:InvalidInput", ...
            "Cannot select nonexisting iterator values.");
    end
end

%#release exclude file
