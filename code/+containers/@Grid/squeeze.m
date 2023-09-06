function [self, const] = squeeze(self)
    % Drops dimensions with scalar iterators.
    %
    %   grid = grid.squeeze()
    %   [grid, iter] = grid.squeeze()
    %
    % Optionally returns the constant iterators.
    %
    % See also containers.Grid/collapse

    if issparse(self)
        fixed = false(size(self.Dims));
        const = cell(size(fixed));
        for iDim = 1:numel(self.Dims)
            const{iDim} = unique([self.Iter.(self.Dims(iDim))]);
            if isscalar(const{iDim})
                fixed(iDim) = true;
            elseif all(ismissing(const{iDim}))
                fixed(iDim) = true;
                const{iDim} = const{iDim}(1);
            end
        end
        
        const = cell2struct(const(fixed), self.Dims(fixed), 2);
        self.Iter = rmfield(self.Iter, self.Dims(fixed));
    else
        fixed = find(cellfun(@isscalar, self.Iter));
        const = cell2struct(self.Iter(fixed), self.Dims(fixed), 2);
        self = collapse(self, fixed, @(v) v);
    end
end

%#release exclude file
