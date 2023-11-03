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
        self = collapse(self, fixed, @(v) v);
    end
end

%#release exclude file
