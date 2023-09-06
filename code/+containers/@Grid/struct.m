function data = struct(self)
    % Serializes data to be shared in a MAT file.

    data = struct();
    data.Data = self.Data;
    data.Iter = self.Iter;
    data.Dims = self.Dims;
    data.User = self.User;
end

%#release exclude file
