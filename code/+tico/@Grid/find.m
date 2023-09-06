function [data, iter] = find(self, fcn, k, direction)
    % Finds and returns data where fcn is true.
    %
    %   data = grid.find(fcn)
    %   data = grid.find(fcn, k)
    %   data = grid.find(fcn, k, direction)
    %   first = grid.find(fcn, 1, 'first')
    %   last = grid.find(fcn, 1, 'last')

    arguments
        self tico.Grid
        fcn (1,1) function_handle = @(x) x ~= 0
        k (1,1) double {mustBeNonnegative, mustBeInteger} = 0
        direction (1,1) string {mustBeMember(direction, ["first", "last"])} = "first"
    end

    mask = sparse(self.map(fcn));
    data = self.Data(mask.Data);
    iter = mask.Iter(mask.Data);

    % select in either direction
    if strcmp(direction, "last")
        data = flip(data);
        iter = flip(iter);
    end

    % select only up to k elements
    if k > 0
        data = data(1:k);
        iter = iter(1:k);
    end
end

%#release exclude file
