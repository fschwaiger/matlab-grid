function varargout = savegrid(file, grid)
    % Saves a MAT file with the grid properties as variables.
    %
    % See also save, struct

    data = struct(grid);
    save(file, '-struct', 'data');

    if nargout > 0
        varargout = {grid};
    end
end
