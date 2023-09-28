function self = pluck(self, keys)
    % Extracts values from a given struct field into a new grid.
    %
    %   grid = grid.pluck(key)
    %   result = evidence.pluck("result")
    %   result = evidence.pluck("Analysis", "Margin")

    arguments
        self containers.Grid
        keys (1, 1) string
    end

    for key = strsplit(keys, ".")
        try
            % try as typed array
            self.Data = reshape([self.Data.(key{1})], size(self.Data));
        catch
            % fall back to cell array
            self.Data = reshape({self.Data.(key{1})}, size(self.Data));
        end
    end
end

%#release exclude file
