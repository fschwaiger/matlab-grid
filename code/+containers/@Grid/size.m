function varargout = size(self, dims)
    % Like size(), but does not cut off trailing dims.

    arguments
        self
        dims (1, :) double = 1:max(numel(self.Dims), 2)
    end

    if isempty(self.Dims)
        % work around error in case below if 2nd argument becomes empty
        varargout = {zeros(1, 2)};
    elseif nargout < 2 && issparse(self)
        % the 2nd argument prevents removal of trailing scalar dimensions
        varargout = {sparsesize(dims)};
    elseif nargout < 2
        % the 2nd argument prevents removal of trailing scalar dimensions
        varargout = {size(self.Data, dims)};
    elseif issparse(self)
        % the 2nd argument prevents removal of trailing scalar dimensions
        varargout = num2cell(sparsesize(1:nargout));
    else
        % the 2nd argument prevents removal of trailing scalar dimensions
        varargout = num2cell(size(self.Data, 1:nargout));
    end

    function s = sparsesize(dims)
        s = ones(size(dims));
        names = self.Dims;
        iters = self.Iter;
        for k = find(dims <= numel(names))
            iter = unique(transpose([iters.(names(dims(k)))]), 'rows');
            miss = all(ismissing(iter), 2);
            s(k) = size(iter, 1) - sum(miss) + any(miss);
        end
    end
end

%#release exclude file
