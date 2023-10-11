function self = extend(self, dims, iter)
    % Adds grid dimensions and iterators, repeating data.
    %
    %   grid = grid.extend(name1, iter1, ...)
    %
    % Extends the grid onto new dimensions or extends existing
    % dimension iterators.
    %
    % See also containers.Grid/retain

    arguments
        self
    end

    arguments (Repeating)
        dims (1,1) string
        iter (:,:)
    end

    with = containers.Grid(nan, iter, [dims{:}]);
    nIter = cellfun(@(it) size(it, 2), with.Iter);

    assert(isempty(intersect(with.Dims, self.Dims)), "grid:InvalidInput", ...
        "Cannot extend the grid onto existing dimensions.");

    if issparse(self)
        self.Data = repmat(self.Data, [prod(nIter), 1]);
        self.Iter = vertcat(map(with, @(~, iter) additer(self.Iter, iter)).Data{:});
    else
        self.Data = repmat(self.Data, [ones(1, ndims(self)), nIter]);
        self.Iter = [self.Iter, with.Iter];
        self.Dims = [self.Dims, with.Dims];
    end
    
    function onto = additer(onto, iter)
        names = string(fieldnames(iter));
        for k = 1:numel(names)
            [onto.(names(k))] = deal(iter.(names(k)));
        end
        onto = {onto};
    end
end

%#release exclude file
