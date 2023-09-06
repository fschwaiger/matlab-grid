function grid = loadgrid(file)
    % Loads a tico.Grid from a MAT file with the properties as variables.
    %
    % See also load, tico.Grid

    %#release include file ../resources/licenseHeader.m

    grid = tico.Grid(load(file, 'Data', 'Iter', 'Dims'));
end
