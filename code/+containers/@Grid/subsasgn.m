function varargout = subsasgn(self, s, value)
    % SUBSREF - customize some indexing expressions

    if any(s(1).type(1) == '({')
        if isstruct(s(1).subs{1})
            % select via struct: grid(struct_array)
            args = {struct2mask(self, s(1).subs{1})};
        elseif (isstring(s(1).subs{1}) || ischar(s(1).subs{1})) ...
            && mod(numel(s(1).subs), 2) == 0 ...
            && all(ismember(cellstr(s(1).subs(1:2:end)), self.Dims))
            % select via struct: grid(name, value, ...)
            args = {struct2mask(self, struct(s(1).subs{:}))};
        elseif islogical(s(1).subs{1})
            % select via mask: grid(mask)
            args = s(1).subs;
        elseif isa(s(1).subs{1}, 'function_handle')
            % select via function: grid(@selector)
            args = {self.map(s(1).subs{1}).Data};
        else
            % select via values: grid(iter1, iter2, ...)
            args = values2indices(self, s(1).subs);
        end

        if s(1).type(1) == '(' && numel(s) > 1
            % select data and continue: grid("a", "b").Data = 42
            assert(s(2).type(1) == '.' && strcmp(s(2).subs, 'Data'), "tico:InvalidInput", ...
                "When assigning a grid by slice, can only assign the Data property.");
            self.Data = subsasgn(self.Data, [substruct('()', args); s(3:end)], value);
        elseif s(1).type(1) == '('
            % select data and continue: grid("a", "b").Data = 42
            self.Data = subsasgn(self.Data, [substruct('()', args); s(2:end)], value.Data);
        elseif s(1).type(1) == '{' && numel(s) > 1
            % select data and continue: grid{"a", "b"}.myfield = 42
            self.Data = subsasgn(self.Data, [substruct('()', args); s(2:end)], value);
        else
            % select data and stop: grid{"a", "b"} = 42
            self.Data(args{:}) = value;
        end
    elseif isequal(s(1), substruct('.', 'Iter')) && length(s) > 1 ...
        && s(2).type == "()" && (ischar(s(2).subs{1}) || isstring(s(2).subs{1})) ...
        && any(ismember(cellstr(s(2).subs), self.Dims))
        % select Iter by name: grid.Iter("x1", "x2", ...)
        self.Iter(cellfun(@(n) find(strcmp(self.Dims, n)), s(2).subs)) = value;
    elseif isequal(s(1), substruct('.', 'Iter')) && length(s) > 1 ...
        && s(2).type == "{}" && (ischar(s(2).subs{1}) || isstring(s(2).subs{1})) ...
        && any(ismember(cellstr(s(2).subs), self.Dims))
        % select Iter by name: grid.Iter{"x1", "x2", ...}
        [self.Iter{cellfun(@(n) find(strcmp(self.Dims, n)), s(2).subs)}] = value;
    elseif not(isempty(s))
        % everything else
        self = builtin('subsasgn', self, s, value);
    end

    varargout = {self};
end

%#release exclude file
