function self = subsasgn(self, s, varargin)
    % SUBSASGN - Customizes indexing into the grid, setting data.
    
    if s(1).type(1) ~= '.'
        if s(1).type(1) == '('
            varargin = {varargin{1}.Data};
        end
        
        s = [ ...
            substruct('.', 'Data'), ...
            substruct('()', subs2args(self, s(1).subs)), ...
            s(2:end) ...
        ];
    end
    
    self = builtin('subsasgn', self, s, varargin{:});
end

%#release exclude file
