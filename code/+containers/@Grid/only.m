function self = only(self, keys)
    % Keeps only given fields from a struct-valued grid.
    %
    % See also rmfield

    arguments
        self containers.Grid
        keys (1,:) string
    end

    self.Data = rmfield(self.Data, setdiff(fieldnames(self.Data), keys));
end

%#release exclude file
