function [data, iter] = last(self, fcn)
    % Returns the last element where fcn is true.
    %
    %   [data, iter] = grid.last(fcn)

    arguments
        self tico.Grid
        fcn (1,1) function_handle = @(x) x ~= 0
    end

    [data, iter] = find(self, fcn, 1, "last");
end

%#release exclude file
