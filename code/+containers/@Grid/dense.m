function self = dense(self, default)
    % Reconstructs a rectangular grid from sparse iterator list.
    %
    %   grid = dense(grid)
    %   grid = dense(grid, default)
    %
    % See also containers.Grid/sparse

    % nothing to do
    if not(issparse(self))
        return
    end

    % save the original data for later
    data = self.Data;
    iter = self.Iter;
    dims = transpose(string(fieldnames(iter)));
    sz = [size(self), 1, 1];

    % make the matrix full of missing entries
    self.Data = cell(sz);
    self.Iter = arrayfun(@(name) createiter(iter.(name)), dims, 'Uniform', false);
    self.Dims = dims;

    % find out if we need the 2nd function input, we would like to avoid that
    args = subs2args(self, {iter});
    needsDefault = true(sz);
    needsDefault(args{:}) = false;

    % fill the missing entries with the default value and assign data over it
    if any(needsDefault, "all")
        self.Data = repmat(default, sz);
        self.Data(args{:}) = data;
    else
        self.Data = repmat(data(1), sz);
        self.Data(args{:}) = data;
    end

    function iter = createiter(varargin)
        % translates varargin to an iterator array

        if ischar(varargin{1}) || isstring(varargin{1})
            iter = unique(string(varargin));
        else
            iter = unique([varargin{:}]', 'rows')';
        end

        % omit multiple NaN values (unique does not remove them)
        mask = all(ismissing(iter), 1);
        iter(:, mask & (cumsum(mask) > 1)) = [];
    end
end

%#release exclude file
