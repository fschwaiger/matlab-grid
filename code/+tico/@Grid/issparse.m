function tf = issparse(self)
    % Returns true if this grid is a sparse grid

    tf = isstruct(self.Iter);
end

%#release exclude file
