function varargout = makegrid(varargin)
    % Alias for containers.Grid().
    %
    % See also containers.Grid

    [varargout{1:nargout}] = containers.Grid(varargin{:});
end
