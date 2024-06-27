function varargout = subsref(self, s)
    % SUBSREF - Customizes indexing into the grid, getting data.
    
    s1t = s(1).type;
    s1s = s(1).subs;

    if s1t == "." && isMethodOrProp(self, s1s)
        % access property or method: e.g. grid.size
        [varargout{1:nargout}] = builtin('subsref', self, s);
    elseif s1t == "()"
        % select data and continue: e.g. grid(...)
        varargout{1} = slice(self, s1s{:});
        if numel(s) > 1
            [varargout{1:nargout}] = subsref(varargout{:}, s(2:end));
        end
    elseif s1t == "{}"
        % select data via named iterators: e.g. grid{"a", "b"}
        varargout = {slice(self, s1s{:}).Data};
        if numel(s) > 1
            margout = numArgumentsFromSubscript(self, s, []);
            [varargout{1:margout}] = subsref(varargout{:}, s(2:end));
        end
    elseif s1t == "." && ismember(s1s, self.Dims)
        % select Iter by name, return values: e.g. grid.a
        if issparse(self)
            varargout{1} = [self.Iter.(s1s)];
        else
            varargout{1} = self.Iter{self.Dims == s1s};
        end
        if numel(s) > 1
            [varargout{1:nargout}] = subsref(varargout{:}, s(2:end));
        end
    else
        % apply the subsref to each grid point and collect the results
        [varargout{1:nargout}] = map(self, @(d) subsref(d, s)).Data;
    end
end

%#release exclude file
