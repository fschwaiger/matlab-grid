function n = numel(self)
    % Returns number of grid iterations.
    %
    %   n = numel(grid)
    %
    % See also containers.Grid/size

    n = numel(self.Data);
end

%#release exclude file
