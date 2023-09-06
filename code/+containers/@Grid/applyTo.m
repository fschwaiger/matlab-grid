function self = applyTo(self, testCase, options)
    % Adds the iterations from the grid to a simulink test case.
    %
    %   grid.applyTo(testCase, Name, Value)
    %   loadgrid('enevelope.mat').applyTo(testCase)
    %
    % Positional arguments:
    %   testCase  -  sltest.TestCase instance
    %
    % Name, Value arguments:
    %   FilterDisabled  -  Logical flag to filter out
    %                      disabled iterations, default false.
    %
    % See also sltest.TestCase

    arguments
        self containers.Grid
        testCase (1,1) sltest.testmanager.TestCase
        options.FilterDisabled (1,1) logical = false
    end

    assert(islogical(self.Data), "grid:InvalidUse", ...
        "Can only apply test grid iterations if the grid contains " + ...
        "true/false values to select iteration points.");

    % iterate over all value / key pairs
    self.each(@makeAndAddIteration);

    function makeAndAddIteration(enabled, values)
        % do not process this iteration, the user wanted less noise
        if options.FilterDisabled && not(enabled)
            return
        end

        % this is the data type we need to add to the test case
        iter = sltestiteration();

        % instead of filtering iterations, we transfer them all,
        % then enable / disable based on the logical envelope.
        iter.Enabled = enabled;

        % currently we can only set Simulink.Parameter values by name
        for name = transpose(string(fieldnames(values)))
            if not(ismissing(values.(name)))
                iter.setVariable("Name", name, "Value", values.(name));
            end
        end

        % register the iteration with the test case
        testCase.addIteration(iter);
    end
end

%#release exclude file
