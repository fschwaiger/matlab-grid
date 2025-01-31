function varargout = partition(self, varargin)
    % Splits grid into multiple parts.
    %
    %   partitions = grid.partition(3)
    %   [p1, p2, p3] = grid.partition()
    %   [myVarIs5, other] = grid.partition(@(key) key.myVar == 5)
    %   [a, b, c] = grid.partition(@(key) ismember(["a", "b", "c"], key.abc))
    %   [a, b, c] = grid.partition(@(key) find(ismember(["a", "b", "c"], key.abc)))
    %
    % The number of partitions is optional and if omitted, inferred from the
    % number of output arguments.
    %
    % See also distributed

    if nargin < 2
        % assume N from number of requested outputs
        varargin{1} = nargout;
    end

    if nargin == 2 && isa(varargin{1}, 'function_handle')
        % specify splits dynamically
        [varargout{1:nargout}] = partitionByFunction(varargin{1});
    elseif nargin > 2
        % specify splits by dimension slice
        [varargout{1:nargout}] = partitionBySlice(varargin);
    else
        % specify splits automatically
        [varargout{1:nargout}] = partitionIntoMostlyEqualParts(varargin{1});
    end
    
    function varargout = partitionBySlice(subs)
        % Partitions the grid by giving slice arguments. The defined slice
        % goes into output 1, while output 2 will have all the rest.
        
        mask = false(size(self.Data));
        args = subs2args(self, subs);
        mask(args{:}) = true;
        varargout = {slice(self, mask), slice(self, ~mask)};
    end

    function varargout = partitionByFunction(fcn)
        % Partitions the grid by an indexing function.

        % apply user partitioning function, return either numerical, or {logical}
        mask = map(self, fcn).Data;

        if iscell(mask)
            % user returned a logical array with one element 'true'
            % cellfun() will fail if more that one element was 'true'
            nParts = numel(mask{1});
            mask = cellfun(@find, mask);
        elseif islogical(mask)
            % user returned a logical scalar, output 'true' into first output
            nParts = 2;
            mask = 2 - mask;
        else
            % user returned an index
            assert(isnumeric(mask), "grid:InvalidInput", ...
                "Partitioning function returned a non-numerical value, should be index.");
            nParts = max(mask, [], 'all');
        end

        varargout = arrayfun(@(iPart) {slice(self, mask == iPart)}, 1:nParts);
    end

    function varargout = partitionIntoMostlyEqualParts(nParts)
        % Partitions the grid into N mostly equal parts.
        
        mask = reshape(ceil(linspace(eps, nParts, numel(self))), size(self.Data));
        varargout = arrayfun(@(iPart) slice(self, mask == iPart), 1:nParts, Uniform=false);
    end
end

%#release exclude file
