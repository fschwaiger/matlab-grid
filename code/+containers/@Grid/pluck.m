function self = pluck(self, key)
    % Extracts values from a given struct field into a new grid.
    %
    %   grid = grid.pluck(key)
    %   result = evidence.pluck("result")

    arguments
        self containers.Grid
        key (1,1) string
    end

    try
        % try as typed array
        self.Data = reshape([self.Data.(key)], size(self.Data));
    catch
        % fall back to cell array
        self.Data = reshape({self.Data.(key)}, size(self.Data));
    end
end

%#release exclude file
