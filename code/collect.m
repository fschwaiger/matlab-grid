function list = collect(data, keys)
    % Creates a 1D collection array (uses tico.Grid internally).
    %
    %    list = collect(data)
    %    list = collect(data, keys)

    %#release include file ../resources/licenseHeader.m

    if nargin < 2
        keys = {1:numel(data)};
    else
        keys = {reshape(keys, 1, [])};
    end

    list = makegrid(reshape(data, [], 1), keys, "key");
end
