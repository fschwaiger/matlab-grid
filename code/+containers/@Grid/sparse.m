function self = sparse(self)
    % Flattens the grid so it has a single struct iterator.
    %
    %   grid = sparse(grid)
    %
    % See also containers.Grid

    if not(issparse(self))
        self.Iter = iter2struct(self.Iter, cellstr(self.Dims));
        self.Data = reshape(self.Data, [], 1);
    end
end

%#release exclude file
