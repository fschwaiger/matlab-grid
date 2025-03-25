classdef (Sealed) Grid < matlab.mixin.CustomDisplay ...
                       & matlab.mixin.indexing.RedefinesParen ...
                       & matlab.mixin.indexing.RedefinesBrace
    % A high-dimension grid object with named dimension iterators.
    %
    %   grid = containers.Grid(matrix)
    %   grid = containers.Grid(default, iterators)
    %   grid = containers.Grid(default, iterators, dimensions)
    %   grid = containers.Grid(default, iterators, dimensions, userData)
    %   grid = containers.Grid(propertyName, propertyValue, ...)
    %   grid = containers.Grid(Data=data, Iter=iter, Dims=dims, User=user)
    %   grid = containers.Grid(serializedAsStruct)
    %
    % Grid properties:
    %   Data  -  High-dimensional data container.
    %   Iter  -  Cell array of iterator arrays (dense) or struct array (sparse).
    %   Dims  -  String array of iterator names.
    %   User  -  User-defined properties.
    %
    % Grid methods:
    %   applyTo       -  Adds the iterations from the grid to a simulink test case.
    %   assign        -  Assigns values of other grid to self.
    %   at            -  Returns data and iterator struct at linear index k.
    %   cat           -  Concatenates two grid along the only iterator they have not in common.
    %   collapse      -  Removes dimensions from the grid using a reducer.
    %   contains      -  Returns whether it contains the given value (at iterator).
    %   data          -  Gets or sets the data of the object.
    %   dense         -  Reconstructs a rectangular grid from sparse iterator list.
    %   dims          -  Read or write dimension names.
    %   distributed   -  Distributes the data across parallel workers.
    %   each          -  Alias for map() with no output arguments.
    %   every         -  True, if @fcn evaluates true for all data points.
    %   except        -  Rejects fields from a struct-valued grid.
    %   extend        -  Adds grid dimensions and iterators, repeating data.
    %   filter        -  Filters the grid using a closure, the result is again a grid.
    %   find          -  Finds and returns data where fcn is true.
    %   first         -  Returns the first element where fcn is true.
    %   gather        -  Collects distributed data from parallel workers.
    %   intersect     -  The common subspace of two or more grids.
    %   iscompatible  -  Tests two grids for compatible iterators and dimensions.
    %   isempty       -  Returns true iff any iterator is empty.
    %   issparse      -  Returns true if this grid is a sparse grid.
    %   iter          -  Gets or sets the iter of the object by name.
    %   last          -  Returns the last element where fcn is true.
    %   map           -  Transforms the grid(s) into (a) new one(s).
    %   ndims         -  Returns the number of grid dimensions.
    %   numel         -  Returns number of grid iterations.
    %   only          -  Keeps only given fields from a struct-valued grid.
    %   partition     -  Splits grid into multiple parts.
    %   permute       -  Reorders grid dimensions.
    %   pipe          -  Pipes the grid through the given function handle.
    %   pluck         -  Extracts values from a given struct field into a new grid.
    %   reject        -  Inverse of filter(), rejects entries.
    %   retain        -  Reduces the grid to given dimensions using a reducer.
    %   sample        -  Reduce the grid to k random samples.
    %   save          -  Saves the grid to the given filename.
    %   size          -  Like size(), but does not cut off trailing dims.
    %   slice         -  Extracts a subspace from this grid using indices or masks.
    %   sort          -  Sorts the grid dimensions and iterators.
    %   sparse        -  Flattens the grid so it has a single struct iterator.
    %   squeeze       -  Drops dimensions with scalar iterators.
    %   struct        -  Serializes data to be shared in a MAT file.
    %   union         -  The combined superspace of two or more grids.
    %   user          -  Gets or sets custom user data on the grid.
    %   vec           -  Vectorized map() function.
    %   where         -  Filters the grid using a value, the result is again a grid.
    %
    % There are several ways to construct a grid object. They all boild down to
    % injecting the data, iter, dims and user properties. If left out or empty,
    % default values will be used to construct the grid (e.g., empty dims will
    % be filled with "x1", "x2", ...). The following examples are equivalent:
    %
    %   grid = containers.Grid(true, {-100:50:100, ["down", "up"]}, ["speed", "flaps"])
    %   grid = containers.Grid(true, Iter={-100:50:100, ["down", "up"]}, Dims=["speed", "flaps"])
    %   grid = containers.Grid(true, {
    %       "speed", -100:50:100
    %       "flaps", ["down", "up"]
    %   })
    %
    % The following examples are also equivalent, but have dims ["x1", "x2"]:
    %
    %   grid = containers.Grid(true, {-100:50:100, ["down", "up"]})
    %   grid = containers.Grid(Data=true, Iter={-100:50:100, ["down", "up"]})
    %   grid = containers.Grid("Data", true, "Iter", {-100:50:100, ["down", "up"]})
    %
    % You can put any kind of matrix data in the grid, as long as the matrix dimensions
    % remain consistent with the iterators - event struct, object and cell matrices.
    %
    % The iterators in the cell array can have an arbitrary 1st dimension, most likely == 1,
    % but columns are allowed. The 2nd dimension is the one that is iterated over. Any
    % further dimensions in the iterator cell array are unsupported. That is, iter{n}
    % defines size(iter{n}, 2) iterations for the n-th dimension.
    %
    % Grids can be sliced in several ways using () or {} indexing. The ()
    % indexing operator returns a new grid, while the {} indexing operator
    % returns the data at the given indices. This behavior is similar to
    % the built-in cell arrays, or the table class. Inside () or {}, the same
    % arguments can be used:
    %
    %   % returns a rectangular grid, matching INDEX from all iterators
    %   grid = grid(iDim1, iDim2, ...)
    %   grid = grid.slice(iDim1, iDim2, ...)
    %   data = grid{iDim1, iDim2, ...}
    %   data = grid.Data(iDim1, iDim2, ...)
    %
    %   % matches only VALUES from selected iterators, keeps others ':' (all)
    %   grid = grid("Dim1", iter1, "Dim2", iter2, ...)
    %   data = grid{"Dim1", iter1, "Dim2", iter2, ...}
    %
    %   % returns a sparse grid at all points where data property matches value
    %   % (notice the leading dot, which is required to distinguish from iterators)
    %   grid = grid(".DataProp1", value1, ...)
    %   data = grid{".DataProp1", value1, ...}
    %
    %   % returns a sparse grid at all given iterator combinations
    %   grid = grid(iterStructs)
    %   data = grid{iterStructs}
    %
    %   % returns a sparse grid at all marked locations
    %   grid = grid(logicalMask)
    %   data = grid{logicalMask}
    %
    %   % returns a sparse grid at all locations where function evaluates true
    %   grid = grid(@matchingFcn)
    %   data = grid{@matchingFcn}
    %
    %   % data with struct iterator at one linear index
    %   [data, iter] = grid.at(iLinear)
    %
    % Some examples for slicing operations:
    %
    %   forwardWithoutFlaps = grid(0:50:100, "up")
    %   dataAtFlapsUp = grid{"flaps", "up"}
    %   [grid{".Success", -1}.Success] = deal(0);
    %
    % See also makegrid

    % %#release include file ../../../LICENSE.txt

    properties
        % High-dimensional data container.
        Data = []
        % Cell array of iterator arrays.
        Iter = {}
        % String array of iterator names.
        Dims = strings(1, 0)
        % User-defined properties.
        User = []
    end

    methods
        function self = Grid(varargin)
            if nargin == 0
                return
            end

            args = {[], {}, strings(1, 0), []};
            iNamedField = 0;
            iImplicitField = 1;
            adhocIterator = [];
            for k = 1:nargin
                arg = varargin{k};
                if k < nargin && iNamedField == 0 && isempty(adhocIterator) && ((ischar(arg) && isrow(arg)) || (isstring(arg) && isscalar(arg)))
                    [~, iNamedField] = ismember(arg, ["Data", "Iter", "Dims", "User"]);
                    if iNamedField == 0
                        adhocIterator = arg;
                    end
                    iImplicitField = [];
                elseif iNamedField ~= 0
                    args{iNamedField} = arg;
                    iNamedField = 0;
                elseif ~isempty(adhocIterator)
                    args{3}(end + 1) = string(adhocIterator);
                    args{2}{end + 1} = arg;
                    adhocIterator = [];
                elseif ~isempty(iImplicitField) && iImplicitField > 4
                    error("grid:InvalidInput", "Too many arguments given.");
                elseif ~isempty(iImplicitField)
                    args{iImplicitField} = arg;
                    iImplicitField = iImplicitField + 1;
                else
                    error("grid:InvalidInput", "Cannot set value without a field name.");
                end
            end
            options = cell2struct(args, ["Data", "Iter", "Dims", "User"], 2);
            options.Dims = string(options.Dims(:)');
            mustBeCellOrStruct(options.Iter);
            mustBeVarname(options.Dims);

            % This variant is called when the grid is loaded from a MAT file
            % or deserialized on its way to a parallel pool worker. We do not
            % want to run the constructor again, but just copy the data.
            if isstruct(options.Data) && isscalar(options.Data) && isequal(fieldnames(options.Data), fieldnames(options))
                self.Data = options.Data.Data;
                self.Iter = options.Data.Iter;
                self.Dims = options.Data.Dims;
                self.User = options.Data.User;
                return
            end
            
            % skip setup, copy constructor
            if isa(options.Data, class(self))
                self = options.Data;
                return
            end
            
            % the user specified a compact table of iterators and dimensions
            if size(options.Iter, 1) > 1 && size(options.Iter, 2) == 2 && isempty(options.Dims)
                options.Dims = string(options.Iter(:, 1)');
                options.Iter = options.Iter(:, 2)';
            end

            % if the user did not specify DIMS, will have ["x1", "x2", ...]
            if isempty(options.Dims) && not(isempty(options.Iter))
                self.Dims = compose("x%d", transpose(1:numel(options.Iter)))';
            elseif isempty(options.Dims) && not(isempty(options.Data))
                self.Dims = compose("x%d", transpose(1:ndims(options.Data)))';
            else
                self.Dims = options.Dims;
            end

            % if the user did not specify ITER, will have {1:k1, 1:k2, ...}
            if isempty(options.Iter) && not(isempty(self.Dims))
                self.Iter = arrayfun(@(k) 1:k, size(options.Data, 1:ndims(self)), "Uni", 0);
            elseif isstruct(options.Iter)
                self.Iter = reshape(options.Iter, [], 1);
            else
                self.Iter = options.Iter;
            end

            % zeros / repmat would produce square matrices with only one argument.
            % Instead, we must force the mising trailing dimensions to be correct
            if issparse(self)
                realGridSizes = [numel(self.Iter), 1];
            else
                realGridSizes = repmat(numel(self.Iter), 1, 2);
                realGridSizes(1:numel(self.Iter)) = cellfun(@(it) size(it, 2), self.Iter);
            end

            if isempty(options.Data)
                % if the user specified data as [], it creates a zeros() matrix
                self.Data = reshape(options.Data, realGridSizes);
            elseif isscalar(options.Data)
                % if the user specified a scalar, the value is repeated as a constant
                self.Data = repmat(options.Data, realGridSizes);
            else
                % else repeats only required dimensions
                required = realGridSizes;
                provided = size(options.Data, 1:numel(required));
                self.Data = repmat(options.Data, required ./ provided);
            end

            % if the user did not specify custom meta data, will have []
            self.User = options.User;

            % ITER, DIMS and DATA must be consistent in size
            assert((isempty(self.Data) && isempty(self.Iter)) || ...
                (issparse(self) && isequal(size(self.Data), size(self.Iter))) || ...
                (not(issparse(self)) && isequal(size(self.Data, 1:numel(self.Iter)), cellfun(@(it) size(it, 2), self.Iter))), ...
                "grid:InvalidInput", "The grid data size was different from the iterators.");
            assert(issparse(self) || (numel(self.Iter) == ndims(self)), ...
                "grid:InvalidInput", "Not all iterators have a name, or too many names given.");
            assert(not(any(ismissing(self.Dims))), ...
                "grid:InvalidInput", "Some iterator names are missing strings.");
            assert(issparse(self) || all(cellfun(@(it) isstruct(it) || ((iscell(it) || isstring(it)) && numel(unique(it)) == numel(it) && sum(ismissing(it)) < 2) || ...
                (ismatrix(it) && size(unique(it', 'rows'), 1) == size(it, 2) && sum(all(ismissing(it), 1), 2) < 2), self.Iter)), ...
                "grid:InvalidInput", "Some iterators have non-unique values.");

            % if any iterator is a column vector, warn that the user might want to transpose it
            if iscell(self.Iter) && any(cellfun(@(it) size(it, 1) > 1 && size(it, 2) == 1, self.Iter))
                warning("grid:ColumnIterator", "Some iterators are column vectors. " + ...
                    "You might want to transpose them to row vectors. You can silence " + ...
                    "this warning via 'warning('off', 'grid:ColumnIterator')'.");
            end
        end

        function self = set.Iter(self, value)
            if iscell(value)
                self.Iter = reshape(value, 1, []);
            else
                self.Iter = reshape(value, [], 1);
                self.Dims = transpose(string(fieldnames(value))); %#ok
            end
        end

        function self = set.Dims(self, value)
            self.Dims = string(reshape(value, 1, []));
        end

        function data = saveobj(self)
            % Uses the STRUCT function when serializing the object

            data = struct(self);
        end

        function self = vertcat(varargin)
            % Fails, because grids cannot be concatenated into arrays.

            self = cat(varargin{:});
        end

        function self = horzcat(varargin)
            % Fails, because grids cannot be concatenated into arrays.

            self = cat(varargin{:});
        end

        function varargin = repmat(varargin)
            % Fails, because grids cannot be concatenated into arrays.

            error("grid:GridConcat", "containers.Grid cannot be replicated.");
        end

        %#release include file assign.m
        
        %#release include file at.m

        %#release include file applyTo.m

        %#release include file cat.m

        %#release include file collapse.m

        %#release include file contains.m

        %#release include file data.m

        %#release include file dense.m

        %#release include file dims.m

        %#release include file distributed.m

        %#release include file each.m

        %#release include file every.m

        %#release include file except.m

        %#release include file extend.m

        %#release include file filter.m

        %#release include file find.m

        %#release include file first.m

        %#release include file gather.m

        %#release include file size.m

        %#release include file intersect.m

        %#release include file iscompatible.m

        %#release include file isempty.m

        %#release include file issparse.m

        %#release include file iter.m

        %#release include file last.m

        %#release include file map.m

        %#release include file ndims.m

        %#release include file numel.m

        %#release include file only.m

        %#release include file partition.m

        %#release include file permute.m

        %#release include file pipe.m

        %#release include file pluck.m

        %#release include file reject.m

        %#release include file retain.m

        %#release include file slice.m

        %#release include file sample.m

        %#release include file save.m

        %#release include file sort.m

        %#release include file sparse.m

        %#release include file squeeze.m

        %#release include file struct.m

        %#release include file union.m

        %#release include file user.m

        %#release include file vec.m

        %#release include file where.m
    end

    %#release exclude
    methods
        self = assign(self, from);
        [data, iter] = at(self, k);
        self = applyTo(self, testCase, options);
        self = cat(self, grids);
        self = collapse(self, dims, reduceFcn);
        [tf, index] = contains(self, value);
        self = data(self, data);
        self = dense(self, default);
        self = dims(self, dim, new);
        self = distributed(self);
        self = each(self, varargin);
        tf = every(self, fcn);
        self = except(self, keys);
        self = extend(self, dims, iter);
        self = filter(self, fcn);
        [data, iter] = find(self, fcn, k, direction);
        [data, iter] = first(self, fcn);
        self = gather(self);
        varargout = size(self, dims);
        self = intersect(self, with, joinFcn, reduceFcnSelf, reduceFcnWith);
        [isCompatible, areCompatible] = iscompatible(self, varargin);
        tf = isempty(self);
        tf = issparse(self);
        self = iter(self, varargin);
        [data, iter] = last(self, fcn);
        varargout = map(self, varargin);
        n = ndims(self);
        n = numel(self);
        self = only(self, keys);
        varargout = partition(self, varargin);
        self = permute(self, dims);
        varargout = pipe(self, fcn);
        self = pluck(self, varargin);
        self = reject(self, fcn);
        self = retain(self, dims, reduceFcn);
        [self, args] = slice(self, varargin);
        self = sample(self, k);
        varargout = save(self, file, varargin)
        self = sort(self);
        self = sparse(self);
        [self, const] = squeeze(self);
        data = struct(self);
        self = union(self, with, joinFcn, missingSelf, missingWith);
        self = user(self, varargin);
        varargout = vec(self, varargin);
        [self, args] = where(self, keyOrValue, value);
    end

    methods (Static)
        function self = loadobj(data)
            % Reinstantiates an object from given struct data

            self = containers.Grid(data);
        end
    end

    methods (Access = protected)
        function n = parenListLength(~, ~, ~)
            n = 1;
        end

        function n = braceListLength(self, s, ~)
            n = 1;
            if numel(s) > 1 && s(2).Type == matlab.indexing.IndexingOperationType.Dot
                args = subs2args(self, s(1).Indices);
                n = numel(self.Data(args{:}));
            end
        end

        function varargout = parenReference(self, s)
            self = slice(self, s(1).Indices{:});
            if isscalar(s)
                [varargout{1:nargout}] = self;
            else
                [varargout{1:nargout}] = self.(s(2:end));
            end
        end

        function varargout = braceReference(self, s)
            args = subs2args(self, s(1).Indices);
            if isscalar(s)
                [varargout{1:nargout}] = self.Data(args{:});
            else
                [varargout{1:nargout}] = self.Data(args{:}).(s(2:end));
            end
        end

        function self = parenAssign(self, s, varargin)
            self = braceAssign(self, s, varargin{1}.Data);
        end

        function self = braceAssign(self, s, varargin)
            args = subs2args(self, s(1).Indices);
            if isscalar(s)
                [self.Data(args{:})] = varargin{:};
            else
                [self.Data(args{:}).(s(2:end))] = varargin{:};
            end
        end

        function self = parenDelete(self, ~)
            error('not implemented');
        end

        function text = getHeader(self)
            % Customizes the command line object display header.

            link = @(x) ['''' x ''''];
            if usejava('desktop')
                link = @(x) sprintf('<a href="matlab:helpPopup %s">%s</a>', x, regexprep(x, ".*\.", ""));
            end

            if issparse(self)
                d = numel(fieldnames(self.Iter));
                s = ' sparse';
            else
                d = ndims(self);
                s = '';
            end
            text = sprintf('  %d-dimensional%s %s containing %s with iterators:\n', d, s, link('containers.Grid'), link(class(self.Data)));
        end

        function text = getFooter(self)
            % Customizes the command line object display footer.

            suffix = '';
            if islogical(self.Data)
                suffix = sprintf(' (%d are <true>)', sum(self.Data, 'all'));
            end

            bytes = whos('self').bytes;
            unit = 'bytes';
            if bytes > 1000
                bytes = bytes / 1000;
                unit = 'kB';
            end
            if bytes > 1000
                bytes = bytes / 1000;
                unit = 'MB';
            end
            if bytes > 1000
                bytes = bytes / 1000;
                unit = 'GB';
            end

            text = sprintf('\n  = %d iterations%s, %d %s\n\n', numel(self), suffix, ceil(bytes), unit);
        end

        function g = getPropertyGroups(self)
            % Customizes the command line object display property groups.

            if issparse(self)
                n = min(10, numel(self.Iter));
                d = "- " + arrayfun(@jsonencode, self.Iter(1:n), "Uniform", false);
            else
                d = cell2struct(self.Iter, self.Dims, 2);
            end
            g = matlab.mixin.util.PropertyGroup(d);
        end
    end

    methods (Access = private)
        %#release include file private/fields2indices.m
        
        %#release include file private/struct2args.m
        
        %#release include file private/subs2args.m
        
        %#release include file private/values2indices.m
        
        %#release include file private/isMethodOrProp.m
    end
end

function mustBeCellOrStruct(s)
    % Checks whether the given value is a cell array or struct array.

    assert(iscell(s) || isstruct(s), "grid:InvalidInput", "Iter must be either cell or struct array.");
end

function mustBeVarname(s)
    % Checks whether the given value is a valid variable name.
    
    assert(all(arrayfun(@isvarname, s)), "grid:InvalidInput", "Dims must be valid variable names.");
end

%#release rename file ../Grid.m
