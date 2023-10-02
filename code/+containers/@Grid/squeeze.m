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
        fixed = false(size(dims));
        const = cell(size(fixed));
        for iDim = 1:numel(dims)
            const{iDim} = unique([iter.(dims(iDim))]);
            if isscalar(const{iDim})
                fixed(iDim) = true;
            elseif all(ismissing(const{iDim}))
                fixed(iDim) = true;
                const{iDim} = const{iDim}(1);
            end
        end
        
        const = cell2struct(const(fixed), dims(fixed), 2);
        self.Iter = rmfield(iter, dims(fixed));
    else
        fixed = find(cellfun(@isscalar, iter));
        const = cell2struct(iter(fixed), dims(fixed), 2);
        self = collapse(self, fixed, @(v) v);
    end
end

%#release exclude file
