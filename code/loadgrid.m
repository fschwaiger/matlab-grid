function grid = loadgrid(file)
    % Loads a containers.Grid from a MAT file with the properties as variables.
    %
    % See also load, containers.Grid

    grid = containers.Grid(load(file, 'Data', 'Iter', 'Dims'));
end
