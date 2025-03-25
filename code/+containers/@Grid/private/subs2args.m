function subs = subs2args(self, subs)
    % Prepares the subscript arguments for slicing the grid.
    
    s = subs{1};

    if isnumeric(s)
        % select via numeric (linear or n-dimension) indices
        return
    elseif ischar(s) && s(1) == ':'
        % colon indexing, still numeric
        return
    elseif isstruct(s)
        % select via struct: grid(struct_array)
        subs = {struct2args(self, s)};
        return
    elseif islogical(s)
        % select via mask: grid(mask)
        return
    elseif isa(s, 'function_handle')
        % select via function: grid(@selector)
        subs = {map(self, s).Data};
        return
    end

    k = subs(1:2:end);
    v = subs(2:2:end);
    d = self.Dims;
    assert(isstring(s) || ischar(s), "grid:Subsref", ...
        "Index the grid via numeric, struct, logical, function_handle or key/value pair subscripts.");

    if startsWith(s, ".")
        % select by field value grid('.name', value, ...)
        k = extractAfter(cellstr(k), 1);
        subs = {arrayfun(@(data) fields2indices(self, data, k, v), self.Data)};
        return
    elseif any(strcmp(s, d))
        % select via struct: grid(name, value, ...)
        [~, order] = ismember(string(k), d);
        subs = repmat({':'}, 1, numel(d));
        subs(order) = v;
        subs = values2indices(self, subs);
        return
    end

    error("grid:Subsref", "Subscript indices %s are invalid.", jsonencode(subs));
end

%#release exclude file
