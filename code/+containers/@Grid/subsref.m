function varargout = subsref(self, s)
    % SUBSREF - Customizes indexing into the grid, getting data.

    if s(1).type == "()"
        % select data and continue: e.g. grid(...)
        args = subs2args(self, s(1).subs);
        varargout = {slice(self, args{:})};
        if numel(s) > 1
            [varargout{1:nargout}] = subsref(varargout{:}, s(2:end));
        end
    elseif s(1).type == "{}"
        % select data via named iterators: e.g. grid{"a", "b"}
        args = subs2args(self, s(1).subs);
        varargout = {self.Data(args{:})};
        if numel(s) > 1
            [varargout{1:nargout}] = subsref(varargout{:}, s(2:end));
        end
    elseif s(1).type == "." && ismember(s(1).subs, self.Dims)
        % select Iter by name, return values: e.g. grid.a
        if issparse(self)
            varargout = {[self.Iter.(s(1).subs)]};
        else
            [varargout{1:nargout}] = self.Iter{self.Dims == s(1).subs};
        end
        if numel(s) > 1
            [varargout{1:nargout}] = subsref(varargout{:}, s(2:end));
        end
    else
        [varargout{1:nargout}] = builtin('subsref', self, s);
    end
end

%#release exclude file
