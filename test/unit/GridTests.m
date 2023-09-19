classdef GridTests < AbstractTestCase

    properties (TestParameter)
        nd = {1, 2, 3}
    end

    methods (Test)
        function it_can_create_empty_grid(test)
            grid = containers.Grid(0, {1:2, 3:4}, ["a", "b"]);
            test.verifyEqual(grid.Data, zeros(2));
        end

        function it_can_copy_grid(test)
            expect = containers.Grid(0, {1:2, 3:4}, ["a", "b"]);
            actual = containers.Grid(expect);
            test.verifyEqual(actual, expect);
            expect{1,3} = 42;
            test.verifyNotEqual(actual, expect);
        end

        function it_can_store_file_with_savegrid(test)
            temp = test.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture());
            file = temp.Folder + "/grid.mat";
            expect = containers.Grid(rand(3), {1:3, 2:4}, ["a", "b"]);

            savegrid(file, expect);
            actual = loadgrid(file);
            stored = load(file);

            test.verifyEqual(actual, expect);
            test.verifyEqual(stored, struct(expect));
        end

        function it_can_store_file_with_save(test)
            temp = test.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture());
            file = temp.Folder + "/grid.mat";
            grid = containers.Grid(rand(3), {1:3, 2:4}, ["a", "b"]);
            grid.save(file);
            test.verifyEqual(load(file), struct(grid));
        end

        function it_can_be_stored_directly(test)
            temp = test.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture());
            file = temp.Folder + "/grid.mat";
            grid = containers.Grid(rand(3), {1:3, 2:4}, ["a", "b"]);
            save(file, "grid");
            test.verifyEqual(load(file).grid, grid);
        end

        function it_cannot_be_concatenated(test)
            grid = containers.Grid(0, {1:2, 3:4});

            test.verifyError(@() [grid, grid], "grid:GridConcat");
            test.verifyError(@() [grid; grid], "grid:GridConcat");
            test.verifyError(@() repmat(grid, 2, 2), "grid:GridConcat");
        end

        function it_has_savegrid_that_can_be_chained(test)
            temp = test.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture());
            file = temp.Folder + "/grid.mat";

            expect = containers.Grid(rand(3), {1:3, 2:4}, ["a", "b"]);
            actual = savegrid(file, expect);

            test.verifyEqual(actual, expect);
        end

        function it_has_save_that_can_be_chained(test)
            temp = test.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture());
            file = temp.Folder + "/grid.mat";
            grid = containers.Grid(rand(3), {1:3, 2:4}, ["a", "b"]);
            test.verifyEqual(grid.save(file), grid);
        end

        function it_has_makegrid_as_alias_for_grid(test)
            data = rand(3);
            expect = containers.Grid(data, {1:3, 2:4}, ["a", "b"]);
            actual = makegrid(data, {1:3, 2:4}, ["a", "b"]);

            test.verifyEqual(actual, expect);
        end

        function it_collects_into_1d_grid(test)
            data = rand(3);
            keys = num2cell('a':'i');

            actual = collect(data);
            expect = containers.Grid(reshape(data, [], 1), {1:9}, "key");
            test.verifyEqual(actual, expect)

            actual = collect(data, keys);
            expect = containers.Grid(reshape(data, [], 1), {keys}, "key");
            test.verifyEqual(actual, expect)
        end

        function it_creates_from_matrix(test)
            data = false(3, 2, 4);
            iter = {1:3, 1:2, 1:4};
            dims = ["lat", "lon", "alt"];
            grid = containers.Grid(data, iter, dims);

            test.verifyEqual(grid.Data, data);
            test.verifyEqual(grid.Iter, iter);
            test.verifyEqual(grid.Dims, dims);
        end

        function it_can_omit_optionals(test)
            grid = containers.Grid(false(3, 2, 4));
            test.verifyEqual(grid.Iter, {1:3, 1:2, 1:4});
            test.verifyEqual(grid.Dims, ["x1", "x2", "x3"]);
        end

        function it_can_be_indexed_by_number(test)
            grid = containers.Grid(false(3, 2, 4));
            test.verifyEqual(grid.slice(1, 2, 2).Data, false);
        end

        function it_can_be_indexed_by_value(test)
            grid = containers.Grid(false(3, 2, 4), {5:7, 8:9, 10:13});
            data = grid{5:6, 8, :};
            test.verifyEqual(size(data), [2, 1, 4]);
        end

        function it_can_be_sliced(test, nd)
            s = {':', ':', ':'};
            s{nd} = 1;

            data = false(3, 2, 4);
            grid = containers.Grid(data);
            subs = grid.slice(s{:});
            data = subsref(data, substruct('()', s));

            expectSize = size(data);
            expectIter = arrayfun(@(k) 1:k, size(data), 'Uni', 0);
            expectIter{nd} = 1;

            test.verifyClass(subs, 'containers.Grid');
            test.verifyEqual(size(subs.Data), expectSize);
            test.verifyEqual(subs.Iter, expectIter);
            test.verifyEqual(subs.Dims, ["x1", "x2", "x3"]);
        end

        function it_can_be_sliced_with_logical_mask(test)
            data = rand(3, 2, 4);
            mask = logical(repmat(eye(3, 2), 1, 1, 4));
            grid = containers.Grid(data);

            subs = grid(mask);
            test.verifyEqual(subs.Data, data(mask));
            test.verifyTrue(isstruct(subs.Iter));

            subs = grid{mask};
            test.verifyEqual(subs, data(mask));
        end

        function it_can_directly_subsref_into_struct(test)
            grid = containers.Grid(struct("a", {1, 2; 3, 4}));
            test.verifyEqual(grid{1, 2}.a, 2);
        end

        function it_can_subsref_iterators(test)
            grid = containers.Grid(rand(2, 2), {1:2, 3:4});

            test.verifyEqual(grid.Iter{"x2"}, 3:4);
            test.verifyEqual(grid.Iter("x2"), {3:4});
            test.verifyEqual(grid.Iter("x2", "x1"), {3:4, 1:2});

            [a, b] = grid.Iter{"x2", "x1"};
            test.verifyEqual(a, 3:4);
            test.verifyEqual(b, 1:2);
        end

        function it_can_subsasgn_iterators(test)
            grid = containers.Grid(rand(2, 2), {1:2, 3:4});

            grid.Iter("x2") = {5:6};
            test.verifyEqual(grid.Iter{2}, 5:6);

            grid.Iter{"x2"} = 7:8;
            test.verifyEqual(grid.Iter{2}, 7:8);
        end

        function it_can_subsasgn_data(test)
            grid = containers.Grid(struct("a", {1,2;3,4}), {1:2, 3:4});
            grid{1,4}.a = 42;
            test.verifyEqual(grid.pluck("a").Data, [1,42;3,4]);

            grid = containers.Grid(struct("a", {1,2;3,4}), {1:2, 3:4});
            grid{@(v) v.a == 3}.a = 42;
            test.verifyEqual(grid.pluck("a").Data, [1,2;42,4]);

            grid = containers.Grid(struct("a", {1,2;3,4}), {1:2, 3:4});
            grid{[false, false; false, true]}.a = 42;
            test.verifyEqual(grid.pluck("a").Data, [1,2;3,42]);

            grid = containers.Grid(struct("a", {1,2;3,4}), {1:2, 3:4});
            grid{struct("x1", 2, "x2", 3)}.a = 42;
            test.verifyEqual(grid.pluck("a").Data, [1,2;42,4]);

            grid = containers.Grid(struct("a", {1,2;3,4}), {1:2, 3:4});
            grid{"x1", 2, "x2", 4}.a = 42;
            test.verifyEqual(grid.pluck("a").Data, [1,2;3,42]);
        end

        function it_can_get_number_of_dims(test)
            grid = containers.Grid(false(3, 2, 4));
            test.verifyEqual(ndims(grid), 3);
        end

        function it_can_get_grid_size(test)
            grid = containers.Grid(false(3, 2, 4));
            test.verifyEqual(size(grid), [3, 2, 4]);
        end

        function it_can_get_number_of_dims_trailing_1(test)
            grid = containers.Grid(false(3, 2, 4, 1), {}, ["a", "b", "c", "d"]);
            test.verifyEqual(size(grid), [3, 2, 4, 1]);
        end

        function it_can_reduce_a_dimension_by_name(test)
            grid = containers.Grid(rand(30));
            grid = grid.collapse("x2", @mean);
            test.verifyEqual(size(grid), 30);
        end

        function it_can_reduce_a_dimension_if_sparse(test)
            grid = containers.Grid("Data", ['abc';'def';'ghi'], "Iter", {1:3, 4:6}, "Dims", ["a", "b"]).sparse();
            test.verifyEqual(grid.collapse("b", @(c) string(c')).dense().Data, ["abc"; "def"; "ghi"]);
            test.verifyEqual(grid.collapse("a", @(c) string(c')).dense().Data, ["adg"; "beh"; "cfi"]);
        end

        function it_can_reduce_a_dimension(test)
            grid = containers.Grid(rand(30));
            grid = grid.collapse(2, @mean);
            test.verifyEqual(size(grid), 30);
        end

        function it_can_reduce_a_dimension_changing_type(test)
            grid = containers.Grid(rand([30, 1, 30]));
            grid = grid.collapse(1, @(x) {x});
            test.verifyTrue(iscell(grid.Data));
            test.verifyEqual(size(grid), [1, 30]);
            test.verifyEqual(size(grid.Data{1}), [30, 1]);
        end

        function it_can_reduce_down_to_2D(test)
            grid = containers.Grid(rand(10, 10, 10, 10));
            grid = grid.retain([2, 3], @(x) mean(x, 'all'));
            test.verifyEqual(size(grid), [10, 10]);
        end

        function it_can_reduce_down_to_2D_by_dim_name(test)
            grid = containers.Grid(rand(10, 10, 10, 10));
            grid = grid.retain(["x1", "x4"], @(x) mean(x, 'all'));
            test.verifyEqual(size(grid), [10, 10]);
            test.verifyEqual(grid.Dims, ["x1", "x4"]);
        end

        function it_can_reduce_and_permute(test)
            grid = containers.Grid(rand(8, 9, 10, 11));
            grid = grid.retain(["x4", "x2", "x3"], @(x) mean(x, 'all'));
            test.verifyEqual(size(grid), [11, 9, 10]);
            test.verifyEqual(grid.Iter, {1:11, 1:9, 1:10});
            test.verifyEqual(grid.Dims, ["x4", "x2", "x3"]);
        end

        function it_can_permute(test)
            grid = containers.Grid(rand(8, 9, 10, 11));
            grid = grid.permute(["x4", "x2", "x1", "x3"]);
            test.verifyEqual(size(grid), [11, 9, 8, 10]);
            test.verifyEqual(grid.Iter, {1:11, 1:9, 1:8, 1:10});
            test.verifyEqual(grid.Dims, ["x4", "x2", "x1", "x3"]);
            test.verifyError(@() grid.permute(["x4", "x2", "x3"]), "grid:InvalidInput");
        end

        function it_can_map_values(test)
            grid = containers.Grid(rand(10, 10, 10, 10));
            grid = grid.map(@(v, k) sum(cell2mat(struct2cell(k))));
            test.verifyEqual(grid.Data(1), 4);
            test.verifyEqual(grid.Data(end), 40);
            test.verifyEqual(grid.Dims, ["x1", "x2", "x3", "x4"]);
        end

        function it_can_map_values_if_sparse(test)
            grid = containers.Grid(rand(10, 10), {}, ["a", "b"]).sparse();
            grid = grid.map(@(v, k) sum(cell2mat(struct2cell(k))));
            test.verifyEqual(grid.Data(1), 2);
            test.verifyEqual(grid.Data(end), 20);
            test.verifyTrue(isstruct(grid.Iter));
            test.verifyEqual(grid.Dims, ["a", "b"]);
        end

        function it_can_map_values_with_error(test)
            grid = containers.Grid(ones(10, 10));

            a = map(grid, grid, @myfunc1, @(e, vv) sum(vv));
            test.verifyTrue(all(a.Data == 2, 'all'));

            b = map(grid, grid, @myfunc2, @(e, v1, v2) v1 + v2);
            test.verifyTrue(all(b.Data == 2, 'all'));

            c = map(grid, grid, @myfunc3, @(e, v1, v2, it) v1 + v2);
            test.verifyTrue(all(c.Data == 2, 'all'));

            d = map(sparse(grid), sparse(grid), @myfunc3, @(e, v1, v2, it) v1 + v2);
            test.verifyTrue(all(d.Data == 2, 'all'));

            function y = myfunc1(x) %#ok
                error("it:fails", "test");
            end
            function y = myfunc2(x1, x2) %#ok
                error("it:fails", "test");
            end
            function y = myfunc3(x1, x2, it) %#ok
                error("it:fails", "test");
            end
        end

        function it_can_partition_into_n_grids(test)
            grid = containers.Grid(rand(8, 12));
            [a, b, c] = grid.partition();

            test.verifyEqual(numel(a.Data) + numel(b.Data) + numel(c.Data), numel(grid.Data));
            test.verifyEqual(c.Dims, grid.Dims);
            test.verifyNotEqual(c.Iter, grid.Iter);
        end

        function it_can_partition_by_function(test)
            grid = containers.Grid(rand(8, 12, 10, 9));
            [a, b] = grid.partition(@(v) (v > 0.5) + 1);

            test.verifyEqual(numel(a.Data) + numel(b.Data), numel(grid.Data));
            test.verifyTrue(all(a.Data <= 0.5, 'all'));
            test.verifyTrue(all(b.Data  > 0.5, 'all'));
        end

        function it_can_partition_by_function_on_iterator(test)
            grid = containers.Grid(false, {1:2, 1:3, 1:3}, ["b", "a", "c"]);

            [a_eq_3, a_ne_3] = test.verifyWarningFree(@() grid.partition(@(value, key) key.a == 3));
            test.verifyEqual(numel(a_eq_3.Data),  6);
            test.verifyEqual(numel(a_ne_3.Data), 12);
        end

        function it_can_partition_by_function_into_bins(test)
            grid = containers.Grid(rand(8, 12, 10, 9));
            [a, b] = grid.partition(@(v) {[v <= 0.5, v > 0.5]});

            test.verifyEqual(numel(a.Data) + numel(b.Data), numel(grid.Data));
            test.verifyTrue(all(a.Data <= 0.5, 'all'));
            test.verifyTrue(all(b.Data  > 0.5, 'all'));
        end

        function it_can_be_parallelized(test)
            if isempty(gcp('nocreate'))
                pool = parpool('local', 2);
                finally = onCleanup(@() delete(pool));
            end

            grid = containers.Grid(false(10, 10, 10, 10, 'distributed'));
            grid = test.verifyWarningFree(@() grid.map(@not));
            test.verifyTrue(all(grid.Data, 'all'));

            grid = containers.Grid(false(10, 10, 10, 10));
            test.verifyFalse(isdistributed(grid.Data));

            grid = containers.Grid(false(10, 10, 10, 10), {}, {}, 'distributed');
            test.verifyTrue(isdistributed(grid.Data));

            grid = distributed(containers.Grid(false(10, 10, 10, 10)));
            test.verifyTrue(isdistributed(grid.Data));

            grid = gather(grid);
            test.verifyFalse(isdistributed(grid.Data));
            
            sz = [2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2];
            grid1 = containers.Grid(rand(sz));
            grid2 = containers.Grid(rand(sz));
            parallelResult = map(distributed(grid1), distributed(grid2), @(a, b, k) a + b + k.x1).gather();
            serialResult = map(grid1, grid2, @(a, b, k) a + b + k.x1);
            test.verifyEqual(parallelResult, serialResult);
        end

        function it_can_partition_into_varargout(test)
            grid = containers.Grid(false, {1:2, 1:3, 1:1}, ["a", "b", "c"]);

            [a, b, c] = test.verifyWarningFree(@() grid.partition());
            test.verifyEqual(numel(a.Data), 2);
            test.verifyEqual(numel(b.Data), 2);
            test.verifyEqual(numel(c.Data), 2);
        end

        function it_can_map_over_multiple_grids(test)
            f = containers.Grid(false, {1:3, 1:3, 1:3}, ["a", "b", "c"]);
            t = containers.Grid(true,  {1:3, 1:3, 1:3}, ["a", "b", "c"]);

            r = map(t, f, @(a, b, ~) any([a, b]));
            test.verifyEqual(r, t);

            r = map(t, f, @(a, b) any([a, b]));
            test.verifyEqual(r, t);

            r = map(t, f, @(array) any(array));
            test.verifyEqual(r, t);

            [r1, r2] = map(t, f, @(a, b) deal(a, b));
            test.verifyEqual(r1, t);
            test.verifyEqual(r2, f);
        end

        function it_cannot_map_over_noncompatible_iter(test)
            t = containers.Grid(false, {1:3, 1:3, 1:3}, ["a", "b", "c"]);
            f = containers.Grid(false, {1:3, 1:3, 1  }, ["a", "b", "c"]);

            test.verifyError(@() map(t, f, @(a, b, ~) any([a, b])), ...
                "grid:InvalidInput");
        end

        function it_cannot_map_over_noncompatible_dims(test)
            t = containers.Grid(false, {1:3, 1:3, 1:3}, ["a", "b", "c"]);
            f = containers.Grid(false, {1:3, 1:3     }, ["a", "b"     ]);

            test.verifyError(@() map(t, f, @(a, b, ~) any([a, b])), ...
                "grid:InvalidInput");
        end

        function it_can_check_for_compatibility(test)
            a = containers.Grid(false, {1:3, 1:3, 1:3}, ["a", "b", "c"]);
            b = containers.Grid(false, {1:3, 1:3, 1:3}, ["a", "b", "c"]);

            [s, m] = iscompatible(a, b);
            test.verifyTrue(s);
            test.verifyEqual(m, [true, true]);

            b = containers.Grid(false, {1:3, 1:3, 1:3}, ["a", "b", "d"]);

            [s, m] = iscompatible(a, b);
            test.verifyFalse(s);
            test.verifyEqual(m, [true, false]);

            b = containers.Grid(false, {1:3, 1:3, 1  }, ["a", "b", "c"]);

            [s, m] = iscompatible(a, b);
            test.verifyFalse(s);
            test.verifyEqual(m, [true, false]);
        end

        function it_can_slice_by_function(test)
            grid = containers.Grid(false, {1:2, 1:3, 1:3}, ["b", "a", "c"]);

            grid = test.verifyWarningFree(@() grid.slice(@(value, key) key.a == 3));
            test.verifySize(grid, [2, 1, 3]);
            test.verifyEqual(numel(grid.Data), 6);
        end

        function it_can_partition_only_if_rectangular(test)
            grid = containers.Grid(false, {1:2, 1:3, 1:3}, ["b", "a", "c"]);
            grid = grid.partition(@(value, key) key.a == key.b);
            test.verifyTrue(issparse(grid));
        end

        function it_must_have_unique_values_in_iterator(test)
            test.verifyError(@() containers.Grid(false, {1:2, [1, 1, nan], 1:3}), ...
                "grid:InvalidInput");
            test.verifyError(@() containers.Grid(false, {1:2, [1, nan, nan], 1:3}), ...
                "grid:InvalidInput");
        end

        function it_can_have_single_nan_in_iterator(test)
            a = containers.Grid(false, {1:2, [1, nan, 3], 1:3});
            b = containers.Grid(true,  {1:2, [1, nan, 3], 1:3});

            test.verifyTrue(iscompatible(a, b));
            test.verifyEqual(a([1, 2], [1, nan], :).size(), [2, 2, 3])
        end

        function it_can_have_missing_in_string_iterator(test)
            a = containers.Grid(false, {1:2, ["a", missing, "c"], 1:3});
            b = containers.Grid(true,  {1:2, ["a", missing, "c"], 1:3});

            test.verifyTrue(iscompatible(a, b));
        end

        function it_joins(test)
            a = containers.Grid(1, {1:3, 1:3, 1:3}, ["a", "b", "c"]);
            b = containers.Grid(2, {2:3, 3:3, 1:3}, ["a", "b", "c"]);
            c = intersect(a, b, @plus);
            test.verifyEqual(c.Iter, {2:3, 3:3, 1:3});
            test.verifyEqual(c.Dims, a.Dims);
            test.verifyEqual(c.Data, repmat(3, 2, 1, 3));
        end

        function it_joins_inner_with_overlap(test)
            a = containers.Grid(1, {1:3, 1:3, 1:3}, ["a", "b", "c"]);
            b = containers.Grid(2, {2:5, 3:3, 1:3}, ["a", "b", "c"]);
            c = intersect(a, b, @plus);
            test.verifyEqual(c.Iter, {2:3, 3:3, 1:3});
            test.verifyEqual(c.Dims, a.Dims);
            test.verifyEqual(c.Data, repmat(3, 2, 1, 3));
        end

        function it_joins_inner_with_partial_overlap_less_dims(test)
            a = containers.Grid(1, {1:3, 1:3, 1:3}, ["a", "b", "c"]);
            b = containers.Grid(2, {2:5, 3:3     }, ["a", "b"     ]);
            c = intersect(a, b, @plus, @prod);
            test.verifyEqual(c.Iter, {2:3, 3:3});
            test.verifyEqual(c.Dims, b.Dims);
            test.verifyEqual(c.Data, repmat(3, 2, 1));
        end

        function it_joins_inner_without_overlap_on_iter(test)
            a = containers.Grid(1, {1:3, 1:3, 1:3}, ["a", "b", "c"]);
            b = containers.Grid(2, {4:6, 1:3, 1:3}, ["a", "b", "c"]);
            c = intersect(a, b, @plus);
            test.verifyEqual(c.Iter, {zeros(1,0), 1:3, 1:3});
            test.verifyEqual(c.Dims, a.Dims);
            test.verifyTrue(isempty(c.Data));
        end

        function it_joins_inner_without_overlap_on_dims(test)
            a = containers.Grid(1, {1:3, 1:3, 1:3}, ["a", "b", "c"]);
            b = containers.Grid(2, {1:3, 1:3, 1:3}, ["f", "e", "d"]);
            c = intersect(a, b, @plus);
            test.verifyEqual(c.Iter, cell(1, 0));
            test.verifyEqual(c.Dims, string.empty(1, 0));
            test.verifyTrue(isempty(c.Data));
        end

        function it_joins_outer_with_overlap(test)
            a = containers.Grid(1, {1:3, 1:3, 1:3}, ["a", "b", "c"]);
            b = containers.Grid(2, {2:3, 3:3, 1:3}, ["a", "b", "c"]);
            c = union(a, b, @plus, 0);
            test.verifyEqual(c.Iter, {1:3, 1:3, 1:3});
            test.verifyEqual(c.Dims, a.Dims);
            test.verifyEqual(c.Data(2:3, 3:3, 1:3), 3 * ones(2, 1, 3));
            test.verifyEqual(c.Data(1:1,  : ,  : ), 1 * ones(1, 3, 3));
            test.verifyEqual(c.Data( : , 1:2,  : ), 1 * ones(3, 2, 3));
        end

        function it_joins_outer_with_partial_overlap(test)
            a = containers.Grid(1, {1:3, 1:3, 1:3}, ["a", "b", "c"]);
            b = containers.Grid(2, {1:3, 4:6, 1:3}, ["a", "b", "c"]);
            c = union(a, b, @plus, 0);
            test.verifyEqual(c.Iter, {1:3, 1:6, 1:3});
            test.verifyEqual(c.Dims, a.Dims);
            test.verifyEqual(c.Data(:, 1:3, :), 1 * ones(3, 3, 3));
            test.verifyEqual(c.Data(:, 4:6, :), 2 * ones(3, 3, 3));
        end

        function it_joins_outer_without_overlap_on_iter(test)
            a = containers.Grid(1, {1:3, 1:3, 1:3}, ["a", "b", "c"]);
            b = containers.Grid(2, {4:6, 4:6, 4:6}, ["a", "b", "c"]);
            c = union(a, b, @plus);
            test.verifyEqual(c.Iter, {1:6, 1:6, 1:6});
            test.verifyEqual(c.Dims, a.Dims);
            test.verifyEqual(c.Data, nan(6, 6, 6));
        end

        function it_joins_outer_without_overlap_on_dims(test)
            a = containers.Grid(1, {1:3, 1:3, 1:3}, ["a", "b", "c"]);
            b = containers.Grid(2, {1:3, 1:3, 1:3}, ["f", "e", "d"]);
            c = union(a, b, @plus, 0, 0);
            test.verifyEqual(c.Iter, {1:3, 1:3, 1:3, 1:3, 1:3, 1:3});
            test.verifyEqual(c.Dims, [a.Dims, b.Dims]);
            test.verifyEqual(c.Data, repmat(3, 3, 3, 3, 3, 3, 3));
        end

        function it_joins_outer_without_missing(test)
            a = containers.Grid(1, {1:3, 1:3, 1:3}, ["a", "b", "c"]);
            b = containers.Grid(2, {2:3, 3:3, 1:5}, ["a", "b", "c"]);
            c = union(a, b, @plus);
            test.verifyEqual(c.Iter, {1:3, 1:3, 1:5});
            test.verifyEqual(c.Dims, a.Dims);
            test.verifyEqual(c.Data(2:3, 3:3, 1:3), 3.0 * ones(2, 1, 3));
            test.verifyEqual(c.Data(1:1,  : ,  : ), nan * ones(1, 3, 5));
            test.verifyEqual(c.Data( : , 1:2,  : ), nan * ones(3, 2, 5));
            test.verifyEqual(c.Data( : ,  : , 4:5), nan * ones(3, 3, 2));
        end

        function it_can_be_extended(test)
            a = containers.Grid(1, {1:3, 1:3, 1:3}, ["a", "b", "c"]);
            b = extend(a, "f", 1:3, "e", 1:3, "d", 1:3);
            test.verifyEqual(b.Data, ones(3, 3, 3, 3, 3, 3));
            test.verifyEqual(b.Iter, repmat({1:3}, 1, 6));
            test.verifyEqual(b.Dims, ["a", "b", "c", "f", "e", "d"]);
        end

        function it_can_filter(test)
            a = containers.Grid(rand(3, 3, 3), {1:3, 1:3, 1:3}, ["a", "b", "c"]);
            b = test.verifyWarningFree(@() a.filter(@(x) x > 0.5));
            test.verifyInstanceOf(b, 'containers.Grid');
            test.verifyTrue(isstruct(b.Iter));
            test.verifyTrue(iscolumn(b.Iter));
            test.verifyTrue(iscolumn(b.Data));
            test.verifyFalse(isempty(b.Data));
            test.verifyEqual(b.Data, a.Data(a.Data > 0.5));
        end

        function it_can_reject(test)
            a = containers.Grid(rand(3, 3, 3), {1:3, 1:3, 1:3}, ["a", "b", "c"]);
            b = test.verifyWarningFree(@() a.reject(@(x) x <= 0.5));
            test.verifyInstanceOf(b, 'containers.Grid');
            test.verifyTrue(isstruct(b.Iter));
            test.verifyTrue(iscolumn(b.Iter));
            test.verifyTrue(iscolumn(b.Data));
            test.verifyFalse(isempty(b.Data));
            test.verifyEqual(b.Data, a.Data(a.Data > 0.5));
        end

        function it_can_use_makegrid(test)
            grid = makegrid(rand(5, 5, 5));
            test.verifyInstanceOf(grid, 'containers.Grid');
        end

        function it_can_remove_struct_fields(test)
            grid = makegrid(struct('a', {1, 2, 3}, 'b', {4, 5, 6}));
            test.verifyEqual(grid.except('b').Data, struct('a', {1, 2, 3}));
        end

        function it_can_pluck_struct_fields(test)
            grid = makegrid(struct('a', {1, 2, 3}, 'b', {4, 5, 6}));
            test.verifyEqual(grid.pluck('b').Data, [4, 5, 6]);
        end

        function it_can_pluck_struct_fields_with_cell(test)
            grid = makegrid(struct('a', {'ab', 'b', 'c'}, 'b', {4, 5, 6}));
            test.verifyEqual(grid.pluck('a').Data, {'ab', 'b', 'c'});
        end

        function it_can_check_if_every_value_is_trueish(test)
            grid = makegrid(rand(5, 5, 5));
            test.verifyTrue(grid.every(@(x) x > 0));
            test.verifyFalse(grid.every(@(x) x > 0.9));
        end

        function it_can_find_entries(test)
            grid = makegrid(rand(5, 5, 5));

            [data, iter1] = grid.first(@(x) x > 0.5);
            test.verifySize(data, [1, 1]);
            test.verifyGreaterThan(data, 0.5);
            test.verifyTrue(isstruct(iter1));
            test.verifyEqual(grid{iter1}, data);

            [data, iter2] = grid.last(@(x) x > 0.5);
            test.verifySize(data, [1, 1]);
            test.verifyGreaterThan(data, 0.5);
            test.verifyTrue(isstruct(iter2));
            test.verifyEqual(grid{iter2}, data);
        end

        function it_can_sort_dimensions_and_iterators(test)
            actual = makegrid([1,2,3;4,5,6;7,8,9], {-1:+1:+1, +1:-1:-1}, ["b", "a"]);
            expect = makegrid([3,6,9;2,5,8;1,4,7], {-1:+1:+1, -1:+1:+1}, ["a", "b"]);
            actual = actual.sort();
            test.verifyEqual(actual.Data, expect.Data);
        end

        function it_can_iterate_with_each(test)
            called = 0;
            function call(~)
                called = called + 1;
            end
            grid = containers.Grid(rand(3, 3));
            grid.each(@call);
            test.verifyEqual(called, 9);
        end

        function it_can_check_if_value_is_contained(test)
            data = rand(5, 5, 2);
            data(1,1,1) = 42;
            iter = {1:5, 1:5, ["up", "down"]};
            dims = ["a", "b", "flaps"];
            grid = containers.Grid(data, iter, dims);
            test.verifyTrue(grid.contains(42));
            test.verifyTrue(grid.contains(42, 1, 1, "up"));
            test.verifyTrue(grid.contains(42, {1, 1, "up"}));
            test.verifyTrue(grid.contains(42, struct("flaps", "up")));
            test.verifyFalse(grid.contains(42, 1, 1, "down"));
            test.verifyFalse(grid.contains(42, {1, 1, "down"}));
            test.verifyFalse(grid.contains(42, struct("flaps", "down")));
            test.verifyFalse(grid.contains(42, "flaps", "down"));

            [~, iter] = grid.contains(42);
            test.verifyEqual(iter, struct("a", 1, "b", 1, "flaps", "up"));
        end

        function it_can_assign_data(test)
            grid = containers.Grid(zeros(5, 5, 2), {1:5, 1:5, ["up", "down"]}, ["a", "b", "flaps"]);
            grid{1, 1, "up"} = 42;
            test.verifyEqual(grid{1, 1,  "up" }, 42);
            test.verifyEqual(grid{1, 1,  "down" }, 0);
            test.verifyEqual(sum(grid.Data, 'all'), 42);

            grid(1, 1, "down") = makegrid(7, {1, 1, "down"}, ["a", "b", "flaps"]);
            test.verifyEqual(grid{1, 1,  "down"}, 7);
            test.verifyEqual(sum(grid.Data, 'all'), 49);

            grid(1, 1, "down").Data = makegrid(7, {1, 1, "down"}, ["a", "b", "flaps"]).Data;
            test.verifyEqual(grid{1, 1,  "down"}, 7);
            test.verifyEqual(sum(grid.Data, 'all'), 49);
        end

        function it_can_undo_sparse_with_dense(test)
            expect = containers.Grid(rand(5, 5, 2), {1:5, 1:5, ["down", "up"]}, ["a", "b", "flaps"]);
            actual = dense(sparse(expect));

            test.verifyEqual(actual, expect);
        end

        function it_can_apply_dense_on_struct_without_default(test)
            expect = containers.Grid(struct('a', cell(5,5), 'b', cell(5,5)), {1:5, 1:5}, ["a", "b"]);
            actual = dense(sparse(expect));

            test.verifyEqual(actual, expect);
        end

        function it_can_apply_dense_twice_without_side_effect(test)
            expect = containers.Grid(rand(5, 5, 2), {1:5, 1:5, ["down", "up"]}, ["a", "b", "flaps"]);
            actual = dense(expect);

            test.verifyEqual(actual, expect);
        end

        function it_can_apply_sparse_twice_without_side_effect(test)
            expect = containers.Grid(rand(5, 5, 2), {1:5, 1:5, ["down", "up"]}, ["a", "b", "flaps"]);
            actual = sparse(sparse(expect));

            test.verifyTrue(issparse(actual));
        end

        function it_can_make_sparse_grid_rectangular_with_dense(test)
            expect = containers.Grid([nan, 2; 3, nan], {1:2, 3:4}, ["a", "b"]);
            actual = containers.Grid([2; 3], struct("a", {1, 2}, "b", {4, 3}));

            test.verifyEqual(dense(actual, nan).Data, expect.Data);
        end

        function it_collects_1D_array(test)
            grid = collect(4:6);
            test.verifyEqual(grid.Data, [4; 5; 6]);
            test.verifyEqual(grid.Iter, { 1 : 3 });
            test.verifyEqual(grid.Dims, "key");
        end

        function it_can_filter_a_1D_array(test)
            grid = collect(4:6);
            grid = grid.filter(@(x) x > 4);
            test.verifyEqual(grid.Data, [5; 6]);
        end

        function it_can_be_piped(test)
            a = containers.Grid([nan, 2; 3, nan], {1:2, 3:4}, ["a", "b"]);
            b = a.pipe(@myfunc);
            test.verifyNotEqual(b, a);
            test.verifyEqual(b.Iter, a.Iter);
            test.verifyEqual(b.Dims, a.Dims);
            test.verifyEqual(b.Data, a.Data * 3);

            function grid = myfunc(grid)
                grid.Data = grid.Data * 3;
            end
        end

        function it_can_select_fields_with_only(test)
            grid = collect(struct('a', {1,2,3}, 'b', {4,5,6}));
            a = grid.only("a");
            test.verifyEqual(fields(a.Data), {'a'});
            b = grid.only(["b", "c"]);
            test.verifyEqual(fields(b.Data), {'b'});
        end

        function it_can_be_applied_to_simulink_test_case(test)
            folder = currentProject().RootFolder + "/test/data/iter";
            test.applyFixture(matlab.unittest.fixtures.CurrentFolderFixture(folder));
            test.verifySize(testsuite('test.mldatx'), [1, 15]);
        end

        function it_can_create_a_mixed_sparse_dense_grid(test)
            test.verifyWarningFree(@() containers.Grid(1, {struct("a", {1, 2, 3})}, "iter"));
            test.verifyWarningFree(@() containers.Grid(1, {[1, 2, 3]}, "b"));
            test.verifyWarningFree(@() containers.Grid(1, {struct("a", {1, 2, 3}), [1, 2, 3]}, ["iter", "b"]));
        end

        function it_will_have_correct_dims_in_sparse_form(test)
            grid = containers.Grid(1, {1:3, 1:4}, ["a", "b"]);
            test.verifyEqual(size(grid.Data), [3, 4]);
            test.verifyEqual(size(grid.Iter{1}), [1, 3]);
            test.verifyEqual(size(grid.Iter{2}), [1, 4]);

            grid = grid.sparse();
            test.verifyEqual(size(grid.Data), [12, 1]);
            test.verifyEqual(size(grid.Iter), [12, 1]);
        end

        function it_can_specify_user_data_in_constructor(test)
            grid = containers.Grid(1, {1:3, 1:4}, ["a", "b"], "User", 42);
            test.verifyEqual(grid.User, 42);
        end
        
        function it_can_be_distributed_via_constructor(test)
            grid = containers.Grid(1, {1:3, 1:4}, ["a", "b"], "distributed");
            test.verifyTrue(isdistributed(grid.Data));
        end

        function it_can_be_both_distributed_and_have_user_data(test)
            grid = containers.Grid(1, {1:3, 1:4}, ["a", "b"], "distributed", "User", 42);
            test.verifyTrue(isdistributed(grid.Data));
            test.verifyEqual(grid.User, 42);
        end

        function it_can_use_named_assignment_in_constructor(test)
            grid = containers.Grid("Data", 1, "Iter", {1:3, 1:4}, "Dims", ["a", "b"], "User", 42);
            test.verifyEqual(grid.Data, ones(3, 4));
            test.verifyEqual(grid.Iter, {1:3, 1:4});
            test.verifyEqual(grid.Dims, ["a", "b"]);
            test.verifyEqual(grid.User, 42);
        end

        function it_can_have_vector_iterators(test)
            iter = {1:3, 1:4, [[1;2;3], [4;5;6]]};
            dims = ["a", "b", "c"];
            grid = containers.Grid(1, iter, dims);
            test.verifyEqual(size(grid), [3, 4, 2]);
            test.verifyEqual(grid.Iter, iter);
            test.verifyEqual(grid.Dims, dims);
            test.verifyEqual(grid.Data, ones(3, 4, 2));
        end

        function it_can_map_over_vector_iterators(test)
            grid = containers.Grid(1, {1:3, 1:4, [[1;2;3], [4;5;6]]}, ["a", "b", "c"]);
            grid = grid.map(@(x, p) p);
            test.verifyEqual(size(grid), [3, 4, 2]);
            test.verifyEqual(grid.at(1), struct("a", 1, "b", 1, "c", [1;2;3]));
        end

        function it_throws_warning_when_column_iterators_are_used(test)
            test.verifyWarning(@() containers.Grid(1, {1:3, [1;2;3]}), "grid:ColumnIterator");
            test.verifyWarningFree(@() containers.Grid(1, {1:3, [[1;2;3], [4;5;6]]}));
        end

        function it_can_draw_k_random_samples(test)
            grid = containers.Grid(1, {1:3, 1:4, [[1;2;3], [4;5;6]]}, ["a", "b", "c"]);
            data = grid.sample(2);
            test.verifyEqual(size(data.Data), [2, 1]);
            test.verifyInstanceOf(data.Data, 'double');
        end

        function it_can_compute_size_with_nonscalar_iterator(test)
            grid = makegrid(1, {1:3, 1:4, [[1;2;3], [4;5;6]]}, ["a", "b", "c"]);
            grid = sparse(grid);
            test.verifyEqual(size(grid), [3, 4, 2]);
        end

        function it_assigns_via_struct_iterators_in_correct_order(test)
            grid = containers.Grid(1, {1:3, 'abcd'}, ["a", "b"]);
            temp = containers.Grid(rand(2, 2), {2:3, 'bc'}, ["a", "b"]).sparse();
            grid = assign(grid, temp);
            test.verifyEqual(grid.Data(2:3, 2:3), temp.dense().Data);
        end
        
        function it_can_slice_grid_with_nonscalar_iterator_with_struct_iter(test)
            grid = containers.Grid(1, {1:3, [[1;2;3], [4;5;6]]}, ["a", "b"]);
            grid = grid(struct("a", {2, 3}, "b", {[1;2;3], [4;5;6]}));
            test.verifyEqual(numel(grid.Data), 2);
        end
    end
end
