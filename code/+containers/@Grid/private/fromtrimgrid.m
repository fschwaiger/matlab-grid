function self = fromtrimgrid(~, tg)
    % Init grid from tulrfsd.tlmpc.trim.TrimGrid object.
    %
    % See also TrimGrid, tulrfsd.tlmpc.trim.TrimGrid

    % constants may not be vector values or we risk creating more iterators
    constants = serializevectorconstants(tg.Constants);

    dims = num2cell(tg.GridDimensions);
    self = containers.Grid( ...
        "Data", struct( ...
            "TrimConditions",   splitstruct(tg.TrimConditions, dims), ...
            "TrimSolverOutput", splitstruct(tg.TrimSolverOutput, dims), ...
            "States",           splitstruct(tg.States, dims), ...
            "Inputs",           splitstruct(tg.Inputs, dims), ...
            "StatesDot",        splitstruct(tg.StatesDot, dims), ...
            "Outputs",          splitstruct(tg.Outputs, dims), ...
            "Additionals",      splitstruct(tg.Additionals, dims), ...
            "SolverVariables",  splitstruct(tg.SolverVariables, dims), ...
            "TrimResiduals",    splitstruct(tg.TrimResiduals, dims), ...
            "Cost",             splitstruct(tg.Cost, dims), ...
            "Success",          splitstruct(tg.Success, dims) ...
        ), ...
        "Iter", {tg.Iterators.IteratorValues, constants.Value}, ...
        "Dims", {tg.Iterators.Name, constants.Name} ...
    );

    function c = splitstruct(x, dims)
        % Splits a struct array into a cell array with given dims.

        % array of 111... for each grid dimension
        args = cellfun(@(d) ones(1, d), dims, 'Uniform', false);

        % force first dimension 1 if missing, else take given
        x = reshape(x, [], dims{:});

        % eliminate first dimension == 1 by left shift
        c = shiftdim(mat2cell(x, size(x, 1), args{:}), 1);
    end

    function c = serializevectorconstants(c)
        % for each nonscalar constant, serialize to a string
        % 
        % Using cell arrays would technically be possible as well,
        % but we chose strings for the time being.

        for k = 1:numel(c)
            if not(isscalar(c(k).Value))
                try
                    c(k).Value = "[" + tico.util.num2str(c(k).Value) + "]";
                catch
                    c(k).Value = "[" + strjoin(string(c(k).Value), ",") + "]";
                end
            end
        end
    end
end

%#release exclude file
