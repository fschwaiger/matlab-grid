function self = pluck(self, varargin)
    % Extracts values from a given struct field into a new grid.
    %
    %   grid = grid.pluck(key)
    %   result = evidence.pluck("result")
    %   result = evidence.pluck("Analysis", "Margin")
    
    data = self.Data;
    sz = size(data);
    
    for arg = varargin
        a = arg{1};
        
        if isstruct(data)
            data = {data.(a)};
        elseif iscell(a)
            data = cellfun(@(d) d(a{:}), data, 'UniformOutput', false);
        else
            data = cellfun(@(d) d(a), data, 'UniformOutput', false);
        end
        
        if isscalar(data{1})
            data = reshape([data{:}], sz);
        else
            data = reshape(data, sz);
        end
    end
    
    self.Data = data;
end

%#release exclude file
