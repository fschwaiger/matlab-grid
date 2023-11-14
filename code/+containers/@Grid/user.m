function self = user(self, varargin)
    % Function get and set accessor for custom user data.
    %
    %   data = grid.user()
    %   grid = grid.user(data)
    %   grid = grid.user(key, value, ...)
    %
    % Examples:
    %   grid = grid.user(mydata = 1)
    %   mydata = grid.user().mydata

    if nargin == 1
        self = self.User;
    elseif nargin == 2
        self.User = varargin{1};
    else
        for k = 1:2:length(varargin)
            self.User.(varargin{k}) = varargin{k+1};
        end
    end
end

%#release exclude file
