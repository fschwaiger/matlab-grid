function varargout = makegrid(varargin)
    % Alias for tico.Grid().
    %
    % See also tico.Grid

    %#release include file ../resources/licenseHeader.m

    [varargout{1:nargout}] = tico.Grid(varargin{:});
end
