function self = dense(self, default)
    % Reconstructs a rectangular grid from sparse iterator list.
    %
    %   grid = dense(grid)
    %   grid = dense(grid, default)
    %
    % See also tico.Grid/sparse

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

    % create a new dense grid
    self = tico.Grid( ...
        "Data", default, ...
        "Iter", arrayfun(@(name) createiter(iter.(name)), dims, 'Uniform', false), ...
        "Dims", dims, ...
        "Dist", isdistributed(self.Data) ...
    );

    % assign the sparse entries
    self = subsasgn(self, substruct('{}', {iter}), data);

    function iter = createiter(varargin)
        % translates varargin to an iterator array

        if ischar(varargin{1}) || isstring(varargin{1})
            iter = unique(string(varargin));
        else
            iter = unique(cell2mat(varargin));
        end

        % omit multiple NaN values (unique does not remove them)
        mask = ismissing(iter);
        iter(mask & (cumsum(mask) > 1)) = [];
    end
end

%#release exclude file
