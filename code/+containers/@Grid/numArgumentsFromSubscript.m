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

    % cannot execute logic down below
    if isempty(s)
        n = 1;
        
    % slicing the grid never changes the dimensionality of the output
    elseif isequal(s(1), substruct('.', 'Iter')) ...
            && numel(s) > 1 ...
            && s(2).type == "()"
        n = 1;

    % slicing iter by name cannot be handled by builtin code
    elseif isequal(s(1), substruct('.', 'Iter')) ...
            && numel(s) > 1 ...
            && s(2).type == "{}" ...
            && iscellstr(s(2).subs) ...
            && not(ismember(':', s(2).subs))
        n = numel(s(2).subs);
        
    % everything else is normal
    else
        n = builtin('numArgumentsFromSubscript', self, s, indexingContext);
        
    end
end

%#release exclude file
