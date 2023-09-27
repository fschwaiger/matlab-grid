function varargout = subsref(self, s)
    % SUBSREF - Customizes indexing into the grid, getting data.

    % prevent errors below and allow recursive invokation with empty struct array
    if isempty(s)
        [varargout{1:nargout}] = self;

    % select data and continue: grid(...) = other
    elseif s(1).type == "()"
        args = subs2args(self, s(1).subs);
        [varargout{1:nargout}] = subsref(slice(self, args{:}), s(2:end));

    % select data and continue: grid{"a", "b"}.myfield = 42
    elseif s(1).type == "{}" && numel(s) > 1
        args = subs2args(self, s(1).subs);
        [varargout{1:nargout}] = subsref(self.Data(args{:}), s(2:end));

    % select data and stop: grid{"a", "b"} = 42
    elseif s(1).type == "{}" 
        args = subs2args(self, s(1).subs);
        [varargout{1:nargout}] = self.Data(args{:});
    
    % select Iter by name, return cell array: grid.Iter("x1", "x2", ...)
    elseif isequal(s(1), substruct('.', 'Iter')) && numel(s) > 1 ...
            && s(2).type == "()"  && (ischar(s(2).subs{1}) || isstring(s(2).subs{1})) ...
            && any(ismember(cellstr(s(2).subs), self.Dims))
        [varargout{1:nargout}] = self.Iter(cellfun(@(n) find(strcmp(self.Dims, n)), s(2).subs));
    
    % select Iter by name, return varargout: grid.Iter{"x1", "x2", ...}
    elseif isequal(s(1), substruct('.', 'Iter')) && numel(s) == 2 ...
            && s(2).type == "{}" && (ischar(s(2).subs{1}) || isstring(s(2).subs{1})) ...
            && any(ismember(cellstr(s(2).subs), self.Dims))
        if issparse(self)
            varargout = cellfun(@(n) [self.Iter.(n)], s(2).subs, 'Uniform', false);
        else
            [varargout{1:nargout}] = self.Iter{cellfun(@(n) find(strcmp(self.Dims, n)), s(2).subs)};
        end
    
    % select Iter by name, return varargout: grid.Iter{"x1", "x2", ...}
    elseif isequal(s(1), substruct('.', 'Iter')) && numel(s) > 2 ...
            && s(2).type == "{}" && (ischar(s(2).subs{1}) || isstring(s(2).subs{1})) ...
            && any(ismember(cellstr(s(2).subs), self.Dims))
        if issparse(self)
            [varargout{1:nargout}] = subsref(self.Iter.(s(3).subs{1}), s(3:end));
        else
            [varargout{1:nargout}] = subsref(self.Iter{cellfun(@(n) find(strcmp(self.Dims, n)), s(2).subs)}, s(3:end));
        end
    
    % everything else
    else
        [varargout{1:nargout}] = builtin('subsref', self, s);
    end
end

%#release exclude file
