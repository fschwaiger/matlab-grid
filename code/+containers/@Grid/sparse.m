function self = sparse(self)
    % Flattens the grid so it has a single struct iterator.
    %
    %   grid = sparse(grid)
    %
    % See also containers.Grid

    if not(issparse(self))
        self.Iter = reshape(map(self, @(~, at) at).Data, [], 1);
        self.Data = reshape(self.Data, [], 1);
    end
end

%#release exclude file
