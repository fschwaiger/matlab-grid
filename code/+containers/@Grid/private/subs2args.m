function args = subs2args(self, subs)
    % Prepares the subscript arguments for slicing the grid.
    
    % do not index, use all
    if isempty(subs)
        args = {};
    
    % select via struct: grid(struct_array)
    elseif isstruct(subs{1})
        args = {struct2mask(self, subs{1})};
    
    % select via mask: grid(mask)
    elseif islogical(subs{1})
        args = subs;
    
    % select via function: grid(@selector)
    elseif isa(subs{1}, 'function_handle')
        args = {map(self, subs{1}).Data};
    
    % select via struct: grid(name, value, ...)
    elseif all(cellfun(@(v) isstring(v) && isscalar(v) || ischar(v), subs(1:2:end))) ...
            && mod(numel(subs), 2) == 0 ...
            && all(ismember(cellstr(subs(1:2:end)), self.Dims))
        [~, order] = ismember(cellstr(subs(1:2:end)), self.Dims);
        args = repmat({':'}, 1, numel(self.Dims));
        args(order) = subs(2:2:end);
        args = values2indices(self, args);
    
    % select by field value grid('.name', value, ...)
    elseif all(cellfun(@(v) isstring(v) && isscalar(v) || ischar(v), subs(1:2:end))) ...
            && mod(numel(subs), 2) == 0 ...
            && ( ...
                isstruct(self.Data) && all(isfield(self.Data, extractAfter(cellstr(subs(1:2:end)), "."))) ...
                || isobject(self.Data) && all(isprop(self.Data, extractAfter(cellstr(subs(1:2:end)), "."))) ...
            )
        fields = extractAfter(cellstr(subs(1:2:end)), ".");
        values = subs(2:2:end);
        args = {map(self, @(data) fields2indices(self, data, fields, values)).Data};
    
    % select via values: grid(iter1, iter2, ...)
    else
        args = values2indices(self, subs);
        
    end
end

%#release exclude file
