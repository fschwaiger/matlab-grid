
function varargout = pipe(self, fcn)
    % Pipes the grid through the given function handle.
    %
    %   grid.pipe(fcn)
    %   grid.filter(@(x) x > 5).pipe(@modifyGrid).filter(@(x) x == "Success")

    n = nargout(fcn);
    
    [varargout{1:min(n, nargout)}] = fcn(self);

    if isempty(varargout)
        varargout = {self};
    end
end

%#release exclude file
