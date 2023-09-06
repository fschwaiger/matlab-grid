function tf = every(self, fcn)
    % True, if @fcn evaluates true for all data points.
    %
    %  tf = grid.every(@fcn)

    arguments
        self containers.Grid
        fcn (1,1) function_handle = @(x) x ~= 0;
    end

    tf = all(map(self, fcn).Data, 'all');
end

%#release exclude file
