function self = data(self, data)
    % Gets or sets the data of the object.
    %
    %   data = data(self, data)
    %
    % Examples:
    %   data = grid.data()
    %   grid.data(data).map(@fcn)...

    if nargin > 1
        self.Data = data;
    else
        self = self.Data;
    end
end

%#release exclude file
