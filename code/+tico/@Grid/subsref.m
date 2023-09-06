function varargout = subsref(self, s)
    % SUBSREF - customize some indexing expressions

    % prevent errors below and allow recursive invokation with empty struct array
    if isempty(s)
        varargout = {self};
        return
    end

    if any(s(1).type(1) == '({')
        if isempty(s(1).subs)
            % do not index, use all
            args = {};
        elseif isstruct(s(1).subs{1})
            % select via struct: grid(struct_array)
            args = {struct2mask(self, s(1).subs{1})};
        elseif all(cellfun(@(v) isstring(v) && isscalar(v) || ischar(v), s(1).subs(1:2:end))) ...
            && mod(numel(s(1).subs), 2) == 0 ...
            && all(ismember(cellstr(s(1).subs(1:2:end)), self.Dims))
            % select via struct: grid(name, value, ...)
            [~, order] = ismember(cellstr(s(1).subs(1:2:end)), self.Dims);
            subs = repmat({':'}, 1, numel(self.Dims));
            subs(order) = s(1).subs(2:2:end);
            args = values2indices(self, subs);
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

        if s(1).type == "()"
            % slice and continue: grid("a", "b").Data
            varargout = {subsref(slice(self, args{:}), s(2:end))};
        elseif s(1).type == "{}" && numel(s) > 1
            % select data and continue: grid{"a", "b"}.myfield
            varargout = {subsref(self.Data(args{:}), s(2:end))};
        else
            % select data and stop: grid{"a", "b"}
            varargout = {self.Data(args{:})};
        end
    elseif isequal(s(1), substruct('.', 'Iter')) && length(s) > 1 ...
        && s(2).type == "()"  && (ischar(s(2).subs{1}) || isstring(s(2).subs{1})) ...
        && any(ismember(cellstr(s(2).subs), self.Dims))
        % select Iter by name, return cell array: grid.Iter("x1", "x2", ...)
        varargout = {self.Iter(cellfun(@(n) find(strcmp(self.Dims, n)), s(2).subs))};
    elseif isequal(s(1), substruct('.', 'Iter')) && length(s) > 1 ...
        && s(2).type == "{}" && (ischar(s(2).subs{1}) || isstring(s(2).subs{1})) ...
        && any(ismember(cellstr(s(2).subs), self.Dims))
        % select Iter by name, return varargout: grid.Iter{"x1", "x2", ...}
        varargout = self.Iter(cellfun(@(n) find(strcmp(self.Dims, n)), s(2).subs));
    else
        % everything else
        [varargout{1:nargout}] = builtin('subsref', self, s);
    end
end

%#release exclude file
