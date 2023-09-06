function n = numArgumentsFromSubscript(self, s, indexingContext)
    % Returns 1, to make brace {} indexing work

    % slicing the grid never changes the dimensionality of the output
    if any(s(1).type(1) == '({')
        s = s(2:end);
    end

    % cannot execute logic down below
    if isempty(s)
        n = 1;
        return
    end

    % slicing iter by name cannot be handled by builtin code
    if s(1).type == "." && s(1).subs == "Iter"
        if numel(s) > 1 && s(2).type == "{}"
            n = numel(s(2).subs);
        else
            n = 1;
        end
        return
    end

    % everything else is normal
    n = builtin('numArgumentsFromSubscript', self, s, indexingContext);
end

%#release exclude file
