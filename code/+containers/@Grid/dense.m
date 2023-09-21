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

    % typically zero, if not specified
    if nargin >= 2
        % keep default
    elseif isstruct(self.Data)
        names = fieldnames(self.Data);
        default = cell2struct(cell(size(names)), names);
    elseif ischar(self.Data)
        default = char(0);
    elseif isstring(self.Data)
        default = "";
    else
        default = zeros(1, 1, class(self.Data));
    end

    % save the original data for later
    data = self.Data;
    iter = self.Iter;
    dims = transpose(string(fieldnames(iter)));
    sz = size(self);

    % make the matrix full of missing entries
    self.Data = repmat(default, [sz, 1, 1]);
    self.Iter = arrayfun(@(name) createiter(iter.(name)), dims, 'Uniform', false);
    self.Dims = dims;

    % assign the sparse entries
    self = subsasgn(self, substruct('{}', {iter}), data);

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
