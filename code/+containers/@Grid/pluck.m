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
        data = reshape({self.Data.(key)}, size(self.Data));
        if all(cellfun(@isscalar, data), 'all')
            self.Data = reshape([data{:}], size(self.Data));
        else
            self.Data = data;
        end
    end
end

%#release exclude file
