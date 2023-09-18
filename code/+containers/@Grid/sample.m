function self = sample(self, k)
    % Reduce the grid to k random samples.
    %
    %   grid = grid.sample(k)
    %
    % Parameters
    %   k  -  number (>= 1) or fraction (< 1) of samples
    %
    % Returns
    %   grid  -  reduced grid

    arguments
        self
        k (1, 1) {mustBeNonnegative}
    end

    if k < 1
        k = floor(k * numel(self));
    end

    assert(k <= numel(self), "tico:InvalidArgument", ...
        "k must be less than or equal to the number of elements in the grid.");

    indices = randperm(numel(self), k);
    mask = false(size(self));
    mask(indices) = true;
    self = slice(self, mask);
end

%#release exclude file
