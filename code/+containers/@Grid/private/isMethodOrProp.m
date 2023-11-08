function tf = isMethodOrProp(self, name)
    % Returns true, if the given name points to a grid property or method.
    
    persistent PROPS_AND_METHODS
    if isempty(PROPS_AND_METHODS)
        PROPS_AND_METHODS = reshape(string(methods(self)), 1, []);
        PROPS_AND_METHODS = ["Data", "Iter", "Dims", "User", PROPS_AND_METHODS];
    end
    
    tf = ismember(name, PROPS_AND_METHODS);
end

%#release exclude file
