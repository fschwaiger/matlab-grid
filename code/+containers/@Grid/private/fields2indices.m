function tf = fields2indices(~, data, fields, values)
    % convert values into index arrays by search
    
    tf = true;
    for k = 1:numel(fields)
        tf = tf & data.(fields{k}) == values{k};
    end
end

%#release exclude file
