classdef (Sealed) Grid < matlab.mixin.CustomDisplay
    % A high-dimension grid object with named dimension iterators.
    %
    %   grid = containers.Grid(default, iterators, dimensions)
    %   grid = containers.Grid(true, {-100:50:100, ["down", "up"]}, ["speed", "flaps"])
    %   grid = containers.Grid(true, {-100:50:100, ["down", "up"]}, ["speed", "flaps"])
    %   grid = containers.Grid(true, {-100:50:100, ["down", "up"]})
    %   grid = containers.Grid(true, {-100:50:100, ["down", "up"]})
    %   grid = containers.Grid(rand(3, 3, 3))
    %
    % Grid properties:
    %   Data  -  High-dimensional data container.
    %   Iter  -  Cell array of iterator arrays.
    %   Dims  -  String array of iterator names.
    %   User  -  User-defined properties.
    %
    % Grid methods:
    %   at            -  Returns data and iterator struct at linear index k.
    %   applyTo       -  Adds the iterations from the grid to a simulink test case.
    %   collapse      -  Removes dimensions from the grid using a reducer.
    %   contains      -  Returns whether it contains the given value (at iterator).
    %   distributed   -  Distributes the data across parallel workers.
    %   dense         -  Reconstructs a rectangular grid from sparse iterator list.
    %   each          -  Alias for map() with no output arguments.
    %   every         -  True, if @fcn evaluates true for all data points.
    %   extend        -  Adds grid dimensions and iterators, repeating data.
    %   except        -  Rejects fields from a struct-valued grid.
    %   filter        -  Filters the grid using a closure, the result is again a grid.
    %   find          -  Finds and returns data where fcn is true.
    %   first         -  Returns the first element where fcn is true.
    %   gather        -  Collects distributed data from parallel workers.
    %   size          -  Like size(), but does not cut off trailing dims.
    %   intersect     -  The common subspace of two or more grids.
    %   iscompatible  -  Tests two grids for compatible iterators and dimensions.
    %   isempty       -  Returns true iff any iterator is empty.
    %   issparse      -  Returns true if this grid is a sparse grid.
    %   last          -  Returns the last element where fcn is true.
    %   map           -  Transforms the grid(s) into (a) new one(s).
    %   ndims         -  Returns the number of grid dimensions.
    %   only          -  Keeps only given fields from a struct-valued grid.
    %   union         -  The combined superspace of two or more grids.
    %   partition     -  Splits grid into multiple parts.
    %   permute       -  Reorders grid dimensions.
    %   pipe          -  Pipes the grid through the given function handle.
    %   pluck         -  Extracts values from a given struct field into a new grid.
    %   reject        -  Inverse of filter(), rejects entries.
    %   retain        -  Reduces the grid to given dimensions using a reducer.
    %   slice         -  Extracts a subspace from this grid using indices or masks.
    %   save          -  Saves the grid to the given filename.
    %   sort          -  Sorts the grid dimensions and iterators.
    %   sparse        -  Flattens the grid so it has a single struct iterator.
    %   squeeze       -  Drops dimensions with scalar iterators.
    %   struct        -  Serializes data to be shared in a MAT file.
    %   vec           -  Vectorized map() function.
    %   where         -  Filters the grid using a value, the result is again a grid.
    %
    % See also makegrid

    properties (SetAccess = protected)
        % High-dimensional data container.
        Data = []

        % Cell array of iterator arrays.
        Iter {mustBeCellOrStruct} = {}

        % String array of iterator names.
        Dims (1,:) string = strings(1, 0)

        % User-defined properties.
        User = []
    end

    methods
        function self = Grid(varargin)
            if nargin > 0 && isa(varargin{1}, "containers.Grid")
                % skip setup, copy constructor
                self = varargin{1};
                parser.Results.Distributed = "no";
            else
                % init with common interface
                parser = inputParser();
                parser.addOptional("Data", []);
                parser.addOptional("Iter", {}, @mustBeCellOrStruct);
                parser.addOptional("Dims", [], @(s) iscellstr(s) || isstring(s));
                parser.addOptional("User", []);
                parser.addOptional("Distributed", [], @(s) isstring(s) || ischar(s) || islogical(s));
                parser.StructExpand = (nargin == 1) && isstruct(varargin{1}) && isfield(varargin{1}, "Data");
                parser.parse(varargin{:});

                % if the user did not specify DIMS, will have ["x1", "x2", ...]
                if isempty(parser.Results.Dims) && not(isempty(parser.Results.Iter))
                    self.Dims = compose("x%d", transpose(1:numel(parser.Results.Iter)));
                elseif isequal(parser.Results.Dims, [])
                    self.Dims = compose("x%d", transpose(1:ndims(parser.Results.Data)));
                else
                    self.Dims = parser.Results.Dims;
                end

                % if the user did not specify ITER, will have {1:k1, 1:k2, ...}
                if isempty(parser.Results.Iter) && not(isempty(self.Dims))
                    self.Iter = arrayfun(@(k) 1:k, size(parser.Results.Data, 1:ndims(self)), "Uni", 0);
                elseif isstruct(parser.Results.Iter)
                    self.Iter = reshape(parser.Results.Iter, [], 1);
                else
                    self.Iter = cellfun(@(iter) reshape(iter, 1, []), parser.Results.Iter, "Uni", 0);
                end

                % zeros / repmat would produce square matrices with only one argument.
                % Instead, we must force the mising trailing dimensions to be correct
                if issparse(self)
                    realGridSizes = [numel(self.Iter), 1];
                else
                    realGridSizes = repmat(numel(self.Iter), 1, 2);
                    realGridSizes(1:numel(self.Iter)) = cellfun(@numel, self.Iter);
                end

                if isempty(parser.Results.Data)
                    % if the user specified data as [], it creates a zeros() matrix
                    self.Data = reshape(parser.Results.Data, realGridSizes);
                elseif isscalar(parser.Results.Data)
                    % if the user specified a scalar, the value is repeated as a constant
                    self.Data = repmat(parser.Results.Data, realGridSizes);
                else
                    % else repeats only required dimensions
                    required = realGridSizes;
                    provided = size(parser.Results.Data, 1:numel(required));
                    self.Data = repmat(parser.Results.Data, required ./ provided);
                end

                % if the user did not specify custom meta data, will have []
                self.User = parser.Results.User;
            end

            % ITER, DIMS and DATA must be consistent in size
            assert((isempty(self.Data) && isempty(self.Iter)) || ...
                (issparse(self) && isequal(size(self.Data), size(self.Iter))) || ...
                (not(issparse(self)) && isequal(size(self.Data, 1:numel(self.Iter)), cellfun(@numel, self.Iter))), ...
                "grid:InvalidInput", "The grid data size was different from the iterators.");
            assert(issparse(self) || (numel(self.Iter) == ndims(self)), ...
                "grid:InvalidInput", "Not all iterators have a name, or too many names given.");
            assert(not(any(ismissing(self.Dims))), ...
                "grid:InvalidInput", "Some iterator names are missing strings.");
            assert(issparse(self) || all(cellfun(@(iter) isstruct(iter) || ...
                (numel(unique(iter)) == numel(iter) && sum(ismissing(iter)) < 2), self.Iter)), ...
                "grid:InvalidInput", "Some iterators have non-unique values.");

            % distribute data array
            if strcmpi(parser.Results.Distributed, "distributed") || isequal(parser.Results.Distributed, true)
                self = distributed(self);
            end
        end

        function self = set.Iter(self, value)
            if iscell(value)
                self.Iter = reshape(value, 1, []);
            else
                self.Iter = reshape(value, [], 1);
            end
        end

        function self = set.Dims(self, value)
            if issparse(self)
                self.Iter = cell2struct(struct2cell(self.Iter), value); %#ok
                self.Dims = strings(1, 0);
            else
                self.Dims = value;
            end
        end

        function value = get.Dims(self)
            if issparse(self)
                value = transpose(string(fieldnames(self.Iter)));
            else
                value = self.Dims;
            end
        end

        function data = saveobj(self)
            % Uses the STRUCT function when serializing the object

            data = struct(self);
        end

        function varargin = cat(varargin)
            % Fails, because grids cannot be concatenated into arrays.

            error("grid:GridConcat", "containers.Grid cannot be concatenated " + ...
                "into arrays. Use 'union(g1, g2)' instead if you " + ...
                "intend to merge the contents of two grids.");
        end

        function varargin = vertcat(varargin)
            % Fails, because grids cannot be concatenated into arrays.

            cat(1, varargin{:});
        end

        function varargin = horzcat(varargin)
            % Fails, because grids cannot be concatenated into arrays.

            cat(2, varargin{:});
        end

        function varargin = repmat(varargin)
            % Fails, because grids cannot be concatenated into arrays.

            cat(1, varargin{:});
        end
        
        %#release include file at.m

        %#release include file applyTo.m

        %#release include file collapse.m

        %#release include file contains.m

        %#release include file dense.m

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

        %#release include file last.m

        %#release include file map.m

        %#release include file ndims.m

        %#release include file numArgumentsFromSubscript.m

        %#release include file numel.m

        %#release include file only.m

        %#release include file partition.m

        %#release include file permute.m

        %#release include file pipe.m

        %#release include file pluck.m

        %#release include file reject.m

        %#release include file retain.m

        %#release include file slice.m

        %#release include file save.m

        %#release include file sort.m

        %#release include file sparse.m

        %#release include file squeeze.m

        %#release include file struct.m

        %#release include file subsref.m

        %#release include file subsasgn.m

        %#release include file union.m

        %#release include file vec.m

        %#release include file where.m
    end

    %#release exclude
    methods % deferred to file, signatures only
        [data, iter] = at(self, k);
        self = applyTo(self, testCase, options);
        self = collapse(self, dims, reduceFcn);
        [tf, index] = contains(self, value, varargin);
        self = dense(self, default);
        self = distributed(self);
        each(self, fcn);
        tf = every(self, fcn);
        self = except(self, keys);
        self = extend(self, dims, iter);
        self = filter(self, fcn);
        [data, iter] = find(self, fcn, k, direction);
        [data, iter] = first(self, fcn);
        self = gather(self);
        varargout = size(self);
        self = intersect(self, with, joinFcn, reduceFcnSelf, reduceFcnWith);
        [isCompatible, areCompatible] = iscompatible(self, varargin);
        tf = isempty(self);
        tf = issparse(self);
        [data, iter] = last(self, fcn);
        varargout = map(self, varargin);
        n = ndims(self);
        n = numArgumentsFromSubscript(self, s, indexingContext);
        n = numel(self);
        self = only(self, keys);
        varargout = partition(self, N);
        self = permute(self, dims);
        varargout = pipe(self, fcn);
        self = pluck(self, key);
        self = reject(self, fcn);
        self = retain(self, dims, reduceFcn);
        self = slice(self, varargin);
        self = save(self, file, varargin);
        self = sort(self);
        self = sparse(self);
        [self, const] = squeeze(self);
        data = struct(self);
        varargout = subsref(self, s);
        varargout = subsasgn(self, s, varargin);
        self = union(self, with, joinFcn, missingSelf, missingWith);
        varargout = vec(self, varargin);
        self = where(self, value);
    end

    methods (Static)
        function self = loadobj(data)
            % Reinstantiates an object from given struct data

            self = containers.Grid(data);
        end
    end

    methods (Access = protected)
        function text = getHeader(self)
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
        %#release include file private/struct2mask.m
        
        %#release include file private/values2indices.m
    end
end

function mustBeCellOrStruct(s)
    assert(iscell(s) || isstruct(s), "grid:InvalidInput", "Property must be either cell or struct array.");
end

