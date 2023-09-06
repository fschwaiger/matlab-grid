function varargout = makegrid(varargin)
    % Alias for containers.Grid().
    %
    % See also containers.Grid

    %#release include file ../resources/licenseHeader.m

    [varargout{1:nargout}] = containers.Grid(varargin{:});
end
