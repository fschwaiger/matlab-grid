function self = cat(self, grids)
    % Concatenates two grid along the only iterator they have not in common.
    %
    %   grid = cat(grid1, grid2)
    %   grid = [grid1, grid2]
    %   grid = [grid1; grid2]
    %
    % Sparse grids can be concatenated only if they have they have mutually
    % exclusive iterators, but over the same dimensions.
    %
    % Dense grids can be concatenated only if they have one single iterator
    % that is mutually exclusive, and the other iterators are the same.
    %
    % See also: horzcat, vertcat

    arguments
        self
    end

    arguments (Repeating)
        grids containers.Grid
    end
    
    if not(isgrid(self))
        self = grids{1};
        grids(1) = [];
    end
    
    assert(all(cellfun(@(grid) isequal(self.Dims, grid.Dims), grids)), ...
        "grid:GridConcat", "Grids must have the same dimensions");

    if issparse(self)
        datas = cellfun(@(grid) grid.Data, grids, "UniformOutput", false);
        iters = cellfun(@(grid) grid.Iter, grids, "UniformOutput", false);
        datas = vertcat(self.Data, datas{:});
        iters = vertcat(self.Iter, iters{:});

        for k1 = 1:numel(iters) - 1
            for k2 = k1+1:numel(iters)
                if isequal(iters(k1), iters(k2))
                    error("grid:Concat", "Grids must have different iterators");
                end
            end
        end

        self.Data = datas;
        self.Iter = iters;
        return
    end

    concatDimensions = cellfun(@(grid) find(not(cellfun(@(it1, it2) ...
        isequal(it1, it2), self.Iter, grid.Iter))), grids, "UniformOutput", false);
        
    assert(all(cellfun(@(dim) numel(dim) == 1, concatDimensions)), ...
        "grid:GridConcat", "Grids must have one single mutually exclusive iterator");
    concatDimension = [concatDimensions{:}];

    assert(all(concatDimension == concatDimension(1)), ...
        "grid:GridConcat", "Grids must have the same mutually exclusive iterator");
    concatDimension = concatDimension(1);
    
    iters = cellfun(@(grid) grid.Iter{concatDimension}, grids, "UniformOutput", false);
    iters = horzcat(self.Iter{concatDimension}, iters{:});
    assert(isequal(iters, transpose(unique(transpose(iters), 'rows', 'stable'))), ...
        "grid:GridConcat", "Grids must have the same mutually exclusive iterator");

    datas = cellfun(@(grid) grid.Data, grids, "UniformOutput", false);
    self.Data = cat(concatDimension, self.Data, datas{:});
    self.Iter{concatDimension} = iters;

    for k = 1:numel(grids)
        if not(isempty(grids{k}.User)) || isstruct(grids{k}.User) && not(isempty(fieldnames(grids{k}.User)))
            warning("grid:GridConcatUserLoss", "User data is not concatenated");
        end
    end
end

%#release exclude file
