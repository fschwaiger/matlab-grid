function self = subsasgn(self, s, varargin)
    % SUBSASGN - Customizes indexing into the grid, setting data.

    % subsequent indexing
    if numel(s) > 1
        data = subsasgn(subsref(self, s(1)), s(2:end), varargin{:});
    else
        data = varargin{1};
    end

    if s(1).type == "()"
        % select data and continue: grid(...) = ...
        args = subs2args(self, s(1).subs);
        self.Data(args{:}) = data.Data;
    elseif s(1).type == "{}"
        % select data and continue: grid{"a", "b"} = ...
        args = subs2args(self, s(1).subs);
        self.Data(args{:}) = data;
    elseif s(1).type == "." && ismember(s(1).subs, self.Dims)
        % assign single Iter by name: grid.x1 = ...
        if issparse(self)
            data = mat2cell(data, size(data, 1), ones(1, size(data, 2)));
            [self.Iter.(s(1).subs)] = deal(data{:});
        else
            self.Iter{self.Dims == s(1).subs} = data;
        end
    else
        % property access
        self = builtin('subsasgn', self, s, data);
    end
end

%#release exclude file
