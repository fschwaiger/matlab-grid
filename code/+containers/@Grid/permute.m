function self = permute(self, dims)
    % Reorders grid dimensions.
    %
    %   grid = containers.Grid(rand(8, 9, 10), "Dims", ["a", "b", "c"])
    %   permute(grid, [3, 1, 2])
    %   permute(grid, ["c", "a", "b"])

    self = retain(self, dims, @failIfIncomoplete);

    function x = failIfIncomoplete(varargin) %#ok
        % should never be called, if the user specified all dims

        error("grid:InvalidInput", "Input argument 'dims' is incomplete.");
    end
end

%#release exclude file
