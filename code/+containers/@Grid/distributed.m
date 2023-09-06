function self = distributed(self)
    % Distributes the data across parallel workers.
    %
    % If the data within this grid is distributed, then map()
    % will run in parallel across all parallel workers.
    %
    % See also distributed/distributed

    self.Data = distributed(self.Data);
end

%#release exclude file
