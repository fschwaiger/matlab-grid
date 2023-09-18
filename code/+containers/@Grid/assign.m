function self = assign(self, from)
    % Assigns values of other grid to self.

    arguments
        self containers.Grid
        from containers.Grid
    end

    self = subsasgn(self, substruct('()', {from.Iter}), from);
end

%#release exclude file
