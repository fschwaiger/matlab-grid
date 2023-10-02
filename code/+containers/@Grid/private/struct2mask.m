function mask = struct2mask(self, values)
    % convert values into index arrays by search

    dims = self.Dims;
    assert(all(ismember(fieldnames(values), dims)), "grid:InvalidInput", ...
        "Trying to slice an unknown dimension.");

    indices = arrayfun(@(v) values2indices(self, arrayfun(@(name) fieldorall(v, name), dims, "Uniform", 0)), values, "Uniform", 0);
    theSize = size(self);

    % check whether any index returned the wildcard ':'
    if any(cellfun(@ischar, [indices{:}]))
        % create a logical mask, not preserving the order
        mask = false(theSize);
        for k = 1:numel(indices)
            mask(indices{k}{:}) = true;
        end
    elseif isscalar(theSize)
        % create a linear index mask, preserving the order
        mask = cell2mat([indices{:}]);
    else
        % create a linear index mask, preserving the order
        mask = cellfun(@(kk) sub2ind(theSize, kk{:}), indices);
    end

    function index = fieldorall(s, name)
        % either returns the field value or ':'

        if isfield(s, name)
            index = s.(name);
        else
            index = ':';
        end
    end
end

%#release exclude file
