function varargout = save(self, file)
    % Saves the grid to the given filename.
    %
    %    grid = save(grid, file)

    data = struct(self);
    save(file, '-struct', 'data');

    if nargout > 0
        varargout = {self};
    end
end

%#release exclude file
