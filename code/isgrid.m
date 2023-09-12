function tf = isgrid(grid)
    % True for containers.Grid instances.

    tf = isa(grid, 'containers.Grid');
end
