function varargout = subsasgn(self, s, varargin)
    % SUBSASGN - Customizes indexing into the grid, setting data.

    % prevent errors below and allow recursive invokation with empty struct array
    if isempty(s)
        varargout = {self};
        return
    end
    
    if any(s(1).type(1) == '({')
        args = subs2args(self, s(1).subs);

        if s(1).type(1) == '('
            % select data and continue: grid(...) = other
            self.Data = subsasgn(self.Data, [substruct('()', args); s(2:end)], varargin{1}.Data);
        elseif s(1).type(1) == '{' && numel(s) > 1
            % select data and continue: grid{"a", "b"}.myfield = 42
            self.Data = subsasgn(self.Data, [substruct('()', args); s(2:end)], varargin{:});
        else
            % select data and stop: grid{"a", "b"} = 42
            [self.Data(args{:})] = deal(varargin{:});
        end
    elseif isequal(s(1), substruct('.', 'Iter')) && length(s) > 1 ...
        && s(2).type == "()" && (ischar(s(2).subs{1}) || isstring(s(2).subs{1})) ...
        && any(ismember(cellstr(s(2).subs), self.Dims))
        % select Iter by name: grid.Iter("x1", "x2", ...)
        self.Iter(cellfun(@(n) find(strcmp(self.Dims, n)), s(2).subs)) = varargin{:};
    elseif isequal(s(1), substruct('.', 'Iter')) && length(s) > 1 ...
        && s(2).type == "{}" && (ischar(s(2).subs{1}) || isstring(s(2).subs{1})) ...
        && any(ismember(cellstr(s(2).subs), self.Dims))
        % select Iter by name: grid.Iter{"x1", "x2", ...}
        [self.Iter{cellfun(@(n) find(strcmp(self.Dims, n)), s(2).subs)}] = varargin{:};
    else
        % everything else
        self = builtin('subsasgn', self, s, varargin{:});
    end

    varargout = {self};
end

%#release exclude file
