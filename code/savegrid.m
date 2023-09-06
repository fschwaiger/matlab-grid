function varargout = savegrid(file, grid, varargin)
    % Saves a MAT file with the grid properties as variables.
    %
    %    savegrid(file, grid)
    %    savegrid(file, grid, '-v7.3')
    %
    % See also containers.Grid/save, containers.Grid/struct, loadgrid

    data = struct(grid);
    save(file, '-struct', 'data', varargin{:});

    if nargout > 0
        varargout = {grid};
    end
end
