function args = subs2args(self, subs)
    % Prepares the subscript arguments for slicing the grid.
    
    if isnumeric(subs{1}) || (ischar(subs{1}) && subs{1}(1) == ':')
        % select via numeric (linear or n-dimension) indices
        args = subs;
        return
    elseif isstruct(subs{1})
        % select via struct: grid(struct_array)
        args = {struct2mask(self, subs{1})};
        return
    elseif islogical(subs{1})
        % select via mask: grid(mask)
        args = subs;
        return
    elseif isa(subs{1}, 'function_handle')
        % select via function: grid(@selector)
        args = {map(self, subs{1}).Data};
        return
    end

    dims = self.Dims;
    assert(isstring(subs{1}) || ischar(subs{1}), "grid:Subsref", ...
        "Index the grid via numeric, struct, logical, function_handle or key/value pair subscripts.");
    
    if ismember(subs{1}, dims)
        % select via struct: grid(name, value, ...)
        [~, order] = ismember(cellstr(subs(1:2:end)), dims);
        args = repmat({':'}, 1, numel(dims));
        args(order) = subs(2:2:end);
        args = values2indices(self, args);
        return
    elseif startsWith(subs{1}, ".")
        % select by field value grid('.name', value, ...)
        fields = extractAfter(cellstr(subs(1:2:end)), ".");
        values = subs(2:2:end);
        args = {map(self, @(data) fields2indices(self, data, fields, values)).Data};
        return
    end

    error("grid:Subsref", "Subscript indices %s are invalid.", jsonencode(subs));
end

%#release exclude file
