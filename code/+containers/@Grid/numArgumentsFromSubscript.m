function n = numArgumentsFromSubscript(self, s, indexingContext)
    % Returns 1, to make brace {} indexing work
    
    s1t = s(1).type;
    s1s = s(1).subs;
    
    if s1t == "." && isMethodOrProp(self, s1s)
        % if it is a property or method, we do not output vararg
        n = builtin('numArgumentsFromSubscript', self, s, indexingContext);
        return
    end
    
    % we are accessing a struct field or property from the data matrix
    if s1t == "{}" && numel(s) > 1 && s(2).type == "."
        args = subs2args(self, s1s);
        n = numel(self.Data(args{:}));
        return
    end
    
    n = 1;
end

%#release exclude file
