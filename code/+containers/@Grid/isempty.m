function tf = isempty(self)
    % Returns true iff any iterator is empty.

    tf = numel(self) == 0;
end

%#release exclude file
