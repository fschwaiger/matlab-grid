function self = each(self, varargin)
    % Alias for map() with no output arguments.
    %
    % See also containers.Grid/map

    map(self, varargin{:});
end

%#release exclude file
