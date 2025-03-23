classdef (SharedTestFixtures = {
    matlab.unittest.fixtures.ProjectFixture(fileparts(fileparts(fileparts(mfilename('fullpath')))))
}) GridMappingTests < matlab.perftest.TestCase %#ok<*NASGU,*ASGLU>

    methods (Test)
        function it_maps_variant_1(test)
            data = zeros(3, 3, 3, 3, 3, 3, 3, 3, 3, 3);
            sizes = size(data);
            N = numel(sizes);
            dims = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j"];
            it1 = 1:3;
            it2 = ["a", "b", "c"];
            iter = {it1, it2, it1, it2, it1, it2, it1, it2, it1, it2};
            fcn = @(v, it) it;

            %%
            while test.keepMeasuring()
                i = cell(1, N);
                [i{:}] = ndgrid(iter{:});
                f = @(varargin) fcn(varargin{N+1:end}, cell2struct(varargin(1:N), dims, 2));
                result = arrayfun(f, i{:}, data);
            end
        end

        function it_maps_variant_2(test)
            data = zeros(3, 3, 3, 3, 3, 3, 3, 3, 3, 3);
            sizes = size(data);
            N = numel(sizes);
            dims = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j"];
            it1 = 1:3;
            it2 = ["a", "b", "c"];
            iter = {it1, it2, it1, it2, it1, it2, it1, it2, it1, it2};
            fcn = @(v, it) it;

            %%
            while test.keepMeasuring()
                result = arrayfun(fcn, data, reshape(iter2struct(iter, dims), sizes));
            end
        end

        function it_maps_variant_3(test)
            data = zeros(3, 3, 3, 3, 3, 3, 3, 3, 3, 3);
            sizes = size(data);
            N = numel(sizes);
            dims = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j"];
            it1 = 1:3;
            it2 = ["a", "b", "c"];
            iter = {it1, it2, it1, it2, it1, it2, it1, it2, it1, it2};
            fcn = @(v, it) it;

            %%
            while test.keepMeasuring()
                v = cell(N, 1);
                f = @(k, varargin) fcn(varargin{:}, iterator(k));
                k = reshape(1:prod(sizes), [sizes, 1, 1]);
                result = arrayfun(f, k, data);
            end

            function s = iterator(k)
                k = k - 1;
                for iDim = 1:N
                    n = sizes(iDim);
                    i = mod(k, n);
                    k = (k - i) / n;
                    v{iDim} = iter{iDim}(:, i + 1);
                end
                s = cell2struct(v, dims);
            end
        end
    end
end