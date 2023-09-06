function self = except(self, keys)
    % Rejects fields from a struct-valued grid.
    %
    % See also rmfield

    arguments
        self tico.Grid
        keys (1,:) string
    end

    self.Data = rmfield(self.Data, keys);
end

%#release exclude file
