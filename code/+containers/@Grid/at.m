function [data, iter] = at(self, k)
    % Returns data and iterator struct at linear index k.
    %
    %    [data, iter] = grid.at(k)
    %
    % Returns data and iterator struct at linear index k. The iterator
    % struct contains the current iteration value for each dimension.
    %
    % See also containers.Grid

    arguments
        self
        k (1, 1) double {mustBeInteger, mustBePositive}
    end

    if issparse(self)
        data = self.Data(k);
        iter = self.Iter(k);
        return
    end

    % data can be retrieved by linear index, which is faster than subscripts
    data = self.Data(k);

    if nargout > 1
        iter = iter2struct(self.Iter, cellstr(self.Dims), k);
    end
end

%#release exclude file
