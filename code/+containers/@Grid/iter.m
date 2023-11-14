function self = iter(self, varargin)
    % Gets or sets the iter of the object by name.
    %
    %   iter = iter(self, iter)
    %
    % Examples:
    %   iter = grid.iter()
    %   grid.iter(iter).map(@fcn)...

    if issparse(self)
        if nargin == 1
            self = self.Iter;
        else
            self.Iter = varargin{1};
        end
    else
        if nargin == 1
            self = self.Iter;
        elseif nargin == 2
            self = self.Iter{self.Dims == string(varargin{1})};
        else
            iDim = self.Dims == string(varargin{1});
            self.Iter{iDim} = varargin{2};
        end
    end
end

%#release exclude file
