function varargout = subsref(self, s)
    % SUBSREF - Customizes indexing into the grid, getting data.

    % prevent errors below and allow recursive invokation with empty struct array
    if isempty(s)
        varargout = {self};
        return
    end

    if any(s(1).type(1) == '({')
        args = subs2args(self, s(1).subs);

        if s(1).type == "()"
            % slice and continue: grid("a", "b").Data
            [varargout{1:nargout}] = subsref(slice(self, args{:}), s(2:end));
        elseif s(1).type == "{}" && numel(s) > 1
            % select data and continue: grid{"a", "b"}.myfield
            [varargout{1:nargout}] = subsref(self.Data(args{:}), s(2:end));
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
