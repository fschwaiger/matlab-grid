function self = sort(self)
    % Sorts the grid dimensions and iterators.
    %
    %   grid = grid.sort()

    if issparse(self)
        % order iterator fields
        self.Iter = orderfields(self.Iter);
    else
        % order dimensions first
        self = permute(self, sort(self.Dims));
        % order iterators next
        [~, iter] = cellfun(@(kk) sort(kk), self.Iter, "UniformOutput", false);
        self = slice(self, iter{:});
    end
end

%#release exclude file
