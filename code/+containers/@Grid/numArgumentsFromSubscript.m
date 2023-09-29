function n = numArgumentsFromSubscript(self, s, indexingContext)
    % Returns 1, to make brace {} indexing work
    
    % we are accessing a struct field or property from the data matrix
    if s(1).type == "{}" && numel(s) > 1 && s(2).type == "."
        args = subs2args(self, s(1).subs);
        n = numel(self.Data(args{:}));
        return
    end

    % slicing the grid never changes the dimensionality of the output
    if any(s(1).type(1) == '({')
        s = s(2:end);
    end
    
    if isempty(s) || s(1).type == "." && ismember(s(1).subs, self.Dims)
        % if it is custom access, we do not output vararg
        n = 1;
    else
        % everything else is normal
        n = builtin('numArgumentsFromSubscript', self, s, indexingContext);
    end
end

%#release exclude file
