function self = sparse(self)
    % Flattens the grid so it has a single struct iterator.
    %
    %   grid = sparse(grid)
    %
    % See also containers.Grid

    if not(issparse(self))
        self.Iter = map(self, @(~, at) at).Data(:);
        self.Data = self.Data(:);
    end
end

%#release exclude file
