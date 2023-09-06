function varargout = save(self, file, varargin)
    % Saves the grid to the given filename.
    %
    %    grid = save(grid, file)
    %
    % See also savegrid, loadgrid

    data = struct(self);
    save(file, '-struct', 'data', varargin{:});

    if nargout > 0
        varargout = {self};
    end
end

%#release exclude file
