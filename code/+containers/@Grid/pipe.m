function varargout = pipe(self, fcn)
    % Pipes the grid through the given function handle.
    %
    %   grid.pipe(fcn)
    %   grid.filter(@(x) x > 5).pipe(@modifyGrid).filter(@(x) x == "Success")

    try
        [varargout{1:nargout}] = fcn(self);
    catch e
        if ismember(e.identifier, ["MATLAB:TooManyOutputs", "MATLAB:UndefinedFunction"])
            fcn(self);
            varargout = {self};
        else
            rethrow(e);
        end
    end
end

%#release exclude file
