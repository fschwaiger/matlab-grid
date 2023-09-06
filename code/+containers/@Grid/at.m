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
    
    % translate linear index in subscripts
    subs = cell(1, ndims(self));
    [subs{:}] = ind2sub(size(self), k);
    
    % data can be retrieved by linear index, which is faster than subscripts
    data = self.Data(k);
    
    % cell array of iterators needs to be subscripted
    iter = cellfun(@(it, kk) it(kk), self.Iter, subs, "Uniform", false);
    iter = cell2struct(iter, self.Dims, 2);
end

%#release exclude file
