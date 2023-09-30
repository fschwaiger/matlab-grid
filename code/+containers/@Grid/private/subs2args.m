function args = subs2args(self, subs)
    % Prepares the subscript arguments for slicing the grid.
    
    args = subs;

    if isstruct(subs{1})
        % select via struct: grid(struct_array)
        args = {struct2mask(self, subs{1})};
    elseif islogical(subs{1})
        % select via mask: grid(mask)
        args = subs;
    elseif isa(subs{1}, 'function_handle')
        % select via function: grid(@selector)
        args = {map(self, subs{1}).Data};
    elseif all(cellfun(@(v) isstring(v) && isscalar(v) || ischar(v), subs(1:2:end))) ...
            && mod(numel(subs), 2) == 0 ...
            && all(ismember(cellstr(subs(1:2:end)), self.Dims))
        % select via struct: grid(name, value, ...)
        [~, order] = ismember(cellstr(subs(1:2:end)), self.Dims);
        args = repmat({':'}, 1, numel(self.Dims));
        args(order) = subs(2:2:end);
        args = values2indices(self, args);
    elseif all(cellfun(@(v) isstring(v) && isscalar(v) || ischar(v), subs(1:2:end))) ...
            && mod(numel(subs), 2) == 0 ...
            && isstruct(self.Data) ...
            && all(isfield(self.Data, extractAfter(cellstr(subs(1:2:end)), ".")))
        % select by field value grid('.name', value, ...)
        fields = extractAfter(cellstr(subs(1:2:end)), ".");
        values = subs(2:2:end);
        args = {map(self, @(data) fields2indices(self, data, fields, values)).Data};
    end
end

%#release exclude file
