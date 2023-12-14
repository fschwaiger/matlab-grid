function [self, const] = squeeze(self)
    % Drops dimensions with scalar iterators.
    %
    %   grid = grid.squeeze()
    %   [grid, iter] = grid.squeeze()
    %
    % Optionally returns the constant iterators.
    %
    % See also containers.Grid/collapse

    dims = self.Dims;
    iter = self.Iter;

    if issparse(self)
        fixed = size(self) == 1;
        if numel(iter) > 0
            const = rmfield(iter(1), dims(not(fixed)));
        else
            const = struct();
        end
        self.Iter = rmfield(iter, dims(fixed));
    else
        fixed = size(self) == 1;
        const = cell2struct(iter(fixed), dims(fixed), 2);
        self.Data = squeeze(self.Data);
        self.Iter = self.Iter(not(fixed));
        self.Dims = self.Dims(not(fixed));

        % workaround for 2D matrix, which squeeze keeps as a row vector
        if isrow(self.Data)
            self.Data = transpose(self.Data);
        end
    end
end

%#release exclude file
