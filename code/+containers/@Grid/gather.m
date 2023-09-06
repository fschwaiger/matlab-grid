function self = gather(self)
    % Collects distributed data from parallel workers.
    %
    % This function is the functional opposite of distributed().
    % You must also gather results before saving the grid to a file.
    %
    % See also matlab/gather

    self.Data = gather(self.Data);
end

%#release exclude file
