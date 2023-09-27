function varargout = subsasgn(self, s, varargin)
    % SUBSASGN - Customizes indexing into the grid, setting data.

    % prevent errors below and allow recursive invokation with empty struct array
    if isempty(s)
        % nothing
    
    % select data and continue: grid(...) = other
    elseif s(1).type == "()"
        args = subs2args(self, s(1).subs);
        self.Data = subsasgn(self.Data, [substruct('()', args); s(2:end)], varargin{1}.Data);
    
    % select data and continue: grid{"a", "b"}.myfield = 42
    elseif s(1).type == "{}" && numel(s) > 1
        args = subs2args(self, s(1).subs);
        self.Data = subsasgn(self.Data, [substruct('()', args); s(2:end)], varargin{:});
    
    % select data and stop: grid{"a", "b"} = 42
    elseif s(1).type == "{}" 
        args = subs2args(self, s(1).subs);
        [self.Data(args{:})] = deal(varargin{:});
    
    % select Iter by name: grid.Iter("x1", "x2", ...)
    elseif isequal(s(1), substruct('.', 'Iter')) && length(s) > 1 ...
            && s(2).type == "()" && (ischar(s(2).subs{1}) || isstring(s(2).subs{1})) ...
            && any(ismember(cellstr(s(2).subs), self.Dims))
        self.Iter(cellfun(@(n) find(strcmp(self.Dims, n)), s(2).subs)) = varargin{:};
    
    % select Iter by name: grid.Iter{"x1", "x2", ...}
    elseif isequal(s(1), substruct('.', 'Iter')) && length(s) > 1 ...
            && s(2).type == "{}" && (ischar(s(2).subs{1}) || isstring(s(2).subs{1})) ...
            && any(ismember(cellstr(s(2).subs), self.Dims))
        [self.Iter{cellfun(@(n) find(strcmp(self.Dims, n)), s(2).subs)}] = varargin{:};
    
    % everything else
    else
        self = builtin('subsasgn', self, s, varargin{:});
    end

    varargout = {self};
end

%#release exclude file
