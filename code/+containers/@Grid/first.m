function [data, iter] = first(self, fcn)
    % Returns the first element where fcn is true.
    %
    %   data = grid.first(fcn)

    arguments
        self containers.Grid
        fcn (1,1) function_handle = @(x) x ~= 0
    end

    [data, iter] = find(self, fcn, 1, "first");
end

%#release exclude file
