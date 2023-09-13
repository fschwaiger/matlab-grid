function varargout = size(self)
    % Like size(), but does not cut off trailing dims.

    if isempty(self.Dims)
        % work around error in case below if 2nd argument becomes empty
        varargout = {zeros(1, 0)};
    elseif nargout < 2 && issparse(self)
        % the 2nd argument prevents removal of trailing scalar dimensions
        varargout = {sparsesize(self, 1:numel(self.Dims))};
    elseif nargout < 2
        % the 2nd argument prevents removal of trailing scalar dimensions
        varargout = {size(self.Data, 1:numel(self.Dims))};
    elseif issparse(self)
        % the 2nd argument prevents removal of trailing scalar dimensions
        varargout = num2cell(sparsesize(self, 1:nargout));
    else
        % the 2nd argument prevents removal of trailing scalar dimensions
        varargout = num2cell(size(self.Data, 1:nargout));
    end

    function s = sparsesize(self, dims)
        s = ones(dims);
        names = self.Dims;
        for k = 1:numel(s)
            iter = unique(transpose([self.Iter.(names(k))]), 'rows');
            miss = all(ismissing(iter), 1);
            s(k) = size(iter, 1) - sum(miss) + any(miss);
        end
    end
end

%#release exclude file
