classdef GridTests < AbstractTestCase

    properties (TestParameter)
        nd = {1, 2, 3}
    end

    methods (Test, TestTags = "serial")
        function it_can_use_shorthand_constructor(test)
            grid = containers.Grid(true, x1 = 1:3, x2 = 4:6, x3 = 7:9);
            test.verifyEqual(grid.Data, true(3, 3, 3));
            test.verifyEqual(grid.Iter, {1:3, 4:6, 7:9});
            test.verifyEqual(grid.Dims, ["x1", "x2", "x3"]);
        end

        function it_can_use_shorthand_constructor_with_string(test)
            grid = containers.Grid(Data = true, x1 = 1:3, x2 = ["up", "down"], x3 = 7:9);
            test.verifyEqual(grid.Data, true(3, 2, 3));
            test.verifyEqual(grid.Iter, {1:3, ["up", "down"], 7:9});
            test.verifyEqual(grid.Dims, ["x1", "x2", "x3"]);
        end

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

        function it_can_store_file_with_save(test)
            file = tempname() + ".mat";
            finally = onCleanup(@() delete(file));
            grid = containers.Grid(rand(3), {1:3, 2:4}, ["a", "b"]);
            grid.save(file);
            test.verifyEqual(load(file), struct(grid));
        end

        function it_can_be_stored_directly(test)
            file = tempname() + ".mat";
            finally = onCleanup(@() delete(file));
            grid = containers.Grid(rand(3), {1:3, 2:4}, ["a", "b"]);
            save(file, "grid");
            test.verifyEqual(load(file).grid, grid);
        end

        function it_cannot_be_concatenated_when_iterators_are_the_same(test)
            grid = containers.Grid(0, {1:2, 3:4});

            test.verifyError(@() [grid, grid], "grid:GridConcat");
            test.verifyError(@() [grid; grid], "grid:GridConcat");
            test.verifyError(@() repmat(grid, 2, 2), "grid:GridConcat");
        end

        function it_can_be_concatenated_if_one_iterator_is_different(test)
            grid1 = containers.Grid(rand(2, 2, 2), {1:2, 3:4, 3:4});
            grid2 = containers.Grid(rand(2, 2, 2), {1:2, 5:6, 3:4});

            test.verifyEqual(cat(grid1, grid2), cat(1, grid1, grid2));
            test.verifyEqual(cat(grid1, grid2), [grid1, grid2]);
            test.verifyEqual(cat(grid1, grid2), [grid1; grid2]);

            grid = [grid1, grid2];
            test.verifyEqual(grid.Iter, {1:2, [3:4, 5:6], 3:4});
            test.verifyEqual(grid.Data, cat(2, grid1.Data, grid2.Data));
        end

        function it_can_be_concatenated_even_with_nan(test)
            grid1 = containers.Grid(rand(2, 2, 2), {1:2, 3:4, [3,nan]});
            grid2 = containers.Grid(rand(2, 2, 2), {1:2, 5:6, [3,nan]});

            test.verifyEqual(cat(grid1, grid2), cat(1, grid1, grid2));
            test.verifyEqual(cat(grid1, grid2), [grid1, grid2]);
            test.verifyEqual(cat(grid1, grid2), [grid1; grid2]);

            grid = [grid1, grid2];
            test.verifyEqual(grid.Iter, {1:2, [3:4, 5:6], [3, nan]});
            test.verifyEqual(grid.Data, cat(2, grid1.Data, grid2.Data));
        end

        function it_has_save_that_can_be_chained(test)
            file = tempname() + ".mat";
            finally = onCleanup(@() delete(file));
            grid = containers.Grid(rand(3), {1:3, 2:4}, ["a", "b"]);
            test.verifyEqual(grid.save(file), grid);
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

        function it_can_be_indexed_via_braces(test)
            t = rand(3, 2, 4);
            grid = containers.Grid(t, {5:7, 8:9, 10:13});
            data = grid{2:1, 1, :};
            test.verifyEqual(data, t(2:1, 1, :));
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

            % also linear indexing
            subs = grid(mask(:));
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

            test.verifyEqual(grid.iter("x2"), 3:4);
            test.verifyEqual(grid.iter("x1"), 1:2);

            [a, b] = grid.Iter{[2, 1]};
            test.verifyEqual(a, 3:4);
            test.verifyEqual(b, 1:2);
        end

        function it_can_subsref_iterators_if_sparse(test)
            grid = containers.Grid(rand(2, 2), {1:2, 3:4}).sparse();

            test.verifyEqual(grid.iter("x1"), [1,2,1,2]);
            test.verifyEqual(grid.iter("x2"), [3,3,4,4]);
        end

        function it_can_subsasgn_data(test)
            grid = containers.Grid(struct("a", {1,2;3,4}), {1:2, 3:4});
            grid{3}.a = 42;
            test.verifyEqual(grid.pluck("a").Data, [1,42;3,4]);

            grid = containers.Grid(struct("a", {1,2;3,4}), {1:2, 3:4});
            grid{1, 2}.a = 42;
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
            grid = containers.Grid(rand(10));
            grid = grid.collapse("x2", @mean);
            test.verifyEqual(size(grid), [10, 1]);
        end

        function it_can_reduce_a_dimension_if_sparse(test)
            grid = containers.Grid("Data", ['abc';'def';'ghi'], "Iter", {1:3, 4:6}, "Dims", ["a", "b"]).sparse();

            done = grid.collapse("b", @(c) string(c')).dense();
            test.verifyEqual(done.Iter, {1:3});
            test.verifyEqual(done.Data, ["abc"; "def"; "ghi"]);

            done = grid.collapse("a", @(c) string(c')).dense();
            test.verifyEqual(done.Iter, {4:6});
            test.verifyEqual(done.Data, ["adg"; "beh"; "cfi"]);
        end

        function it_can_reduce_a_dimension_if_sparse_with_nan(test)
            grid = containers.Grid("Data", ['abc';'def';'ghi'], "Iter", {1:3, [4,6,nan]}, "Dims", ["a", "b"]).sparse();

            done = grid.collapse("b", @(c) string(c')).dense();
            test.verifyEqual(done.Iter, {1:3});
            test.verifyEqual(done.Data, ["abc"; "def"; "ghi"]);

            done = grid.collapse("a", @(c) string(c')).dense();
            test.verifyEqual(done.Iter, {[4, 6, nan]});
            test.verifyEqual(done.Data, ["adg"; "beh"; "cfi"]);
        end

        function it_can_reduce_a_dimension_if_sparse_multidim(test)
            grid = containers.Grid("Data", ['abc';'def';'ghi'], "Iter", {[1:3;1:3], 4:6}, "Dims", ["a", "b"]).sparse();

            done = grid.collapse("b", @(c) string(c')).dense();
            test.verifyEqual(done.Iter, {[1:3;1:3]});
            test.verifyEqual(done.Data, ["abc"; "def"; "ghi"]);

            done = grid.collapse("a", @(c) string(c')).dense();
            test.verifyEqual(done.Iter, {4:6});
            test.verifyEqual(done.Data, ["adg"; "beh"; "cfi"]);
        end

        function it_can_reduce_a_dimension(test)
            grid = containers.Grid(rand(10));
            grid = grid.collapse(2, @mean);
            test.verifyEqual(size(grid), [10, 1]);
        end

        function it_can_reduce_a_dimension_by_logical_id(test)
            grid = containers.Grid(rand(10));
            grid = grid.collapse(grid.Dims == "x2", @mean);
            test.verifyEqual(size(grid), [10, 1]);
        end

        function it_can_retain_a_dimension_by_logical_id(test)
            grid = containers.Grid(rand(10));
            grid = grid.retain(grid.Dims == "x2", @mean);
            test.verifyEqual(size(grid), [10, 1]);
        end

        function it_validates_input_for_retain(test)
            grid = containers.Grid(rand(10));
            test.verifyWarningFree(@() grid.retain("x2", @mean));
            test.verifyWarningFree(@() grid.retain(2, @mean));
            test.verifyWarningFree(@() grid.retain([false, true], @mean));
            test.verifyError(@() grid.retain(false(1,3)), "grid:InvalidInput");
            test.verifyError(@() grid.retain(false(1,1)), "grid:InvalidInput");
            test.verifyError(@() grid.retain(3), "grid:InvalidInput");
            test.verifyError(@() grid.retain("x3"), "grid:InvalidInput");
        end

        function it_can_retain_dim_if_sparse(test)
            grid = makegrid(1, {0:3, 0:3, 0:3, 0:3});
            grid = sparse(grid);
            grid = grid.retain(["x2", "x3"], @max);
            test.verifyEqual(size(grid), [4, 4]);
            test.verifyEqual(grid.Dims, ["x2", "x3"]);
        end

        function it_can_reduce_a_dimension_changing_type(test)
            grid = containers.Grid(rand([10, 1, 10]));
            grid = grid.collapse(1, @(x) {x});
            test.verifyTrue(iscell(grid.Data));
            test.verifyEqual(size(grid), [1, 10]);
            test.verifyEqual(size(grid.Data{1}), [10, 1]);
        end

        function it_can_collapse_multiple_dimensions(test)
            n = 0;
            containers.Grid(rand([2, 2, 2, 4])).collapse(["x2", "x3"], @reduce);
            function v = reduce(v)
                test.verifySize(v, [1, 2, 2, 1]);
                v = mean(v, 'all');
                n = n + 1;
            end
            test.verifyEqual(n, 8);
        end

        function it_can_collapse_selected_singular_dims_without_fcn(test)
            grid = containers.Grid(rand([2, 1, 2, 1, 3]));
            grid = grid.collapse(["x2", "x4"]);
            test.verifyEqual(size(grid), [2, 2, 3]);
        end

        function it_can_collapse_selected_singular_dims_without_fcn_when_sparse(test)
            grid = containers.Grid(rand([2, 1, 2, 1, 3])).sparse();
            grid = grid.collapse(["x2", "x4"]);
            test.verifyEqual(size(grid), [2, 2, 3]);
        end

        function it_can_reduce_down_to_2D(test)
            grid = containers.Grid(rand(2, 2, 2, 2));
            grid = grid.retain([2, 3], @(x) mean(x, 'all'));
            test.verifyEqual(size(grid), [2, 2]);
        end

        function it_can_reduce_down_to_2D_by_dim_name(test)
            grid = containers.Grid(rand(2, 2, 2, 2));
            grid = grid.retain(["x1", "x4"], @(x) mean(x, 'all'));
            test.verifyEqual(size(grid), [2, 2]);
            test.verifyEqual(grid.Dims, ["x1", "x4"]);
        end

        function it_can_reduce_and_permute(test)
            grid = containers.Grid(rand(3, 4, 5, 6));
            grid = grid.retain(["x4", "x2", "x3"], @(x) mean(x, 'all'));
            test.verifyEqual(size(grid), [6, 4, 5]);
            test.verifyEqual(grid.Iter, {1:6, 1:4, 1:5});
            test.verifyEqual(grid.Dims, ["x4", "x2", "x3"]);
        end

        function it_retains_input_dim_order_as_well_when_sparse(test)
            grid = containers.Grid(rand(8, 1, 5)).sparse();
            grid = grid.retain(["x2", "x1"], @(x) mean(x, 'all'));
            test.verifyEqual(size(grid), [1, 8]);
            test.verifyEqual(grid.Dims, ["x2", "x1"]);
        end

        function it_can_permute(test)
            grid = containers.Grid(rand(3, 4, 5, 6));
            grid = grid.permute(["x4", "x2", "x1", "x3"]);
            test.verifyEqual(size(grid), [6, 4, 3, 5]);
            test.verifyEqual(grid.Iter, {1:6, 1:4, 1:3, 1:5});
            test.verifyEqual(grid.Dims, ["x4", "x2", "x1", "x3"]);
            test.verifyError(@() grid.permute(["x4", "x2", "x3"]), "grid:InvalidInput");
        end

        function it_can_map_values(test)
            grid = containers.Grid(rand(3, 3, 3, 3));
            grid = grid.map(@(v, k) sum(cell2mat(struct2cell(k))));
            test.verifyEqual(grid.Data(1), 4);
            test.verifyEqual(grid.Data(end), 12);
            test.verifyEqual(grid.Dims, ["x1", "x2", "x3", "x4"]);
        end

        function it_can_vector_map_values(test)
            grid = containers.Grid(rand(3, 3, 3, 3));
            grid = grid.vec(@(v) v + 1);
            test.verifyTrue(all(grid.Data >= 1.0, "all"));
            test.verifyEqual(grid.Dims, ["x1", "x2", "x3", "x4"]);
        end

        function it_can_map_values_if_sparse(test)
            grid = containers.Grid(rand(2, 2), {}, ["a", "b"]).sparse();
            grid = grid.map(@(v, k) sum(cell2mat(struct2cell(k))));
            test.verifyEqual(grid.Data(1), 2);
            test.verifyEqual(grid.Data(end), 4);
            test.verifyTrue(isstruct(grid.Iter));
            test.verifyEqual(grid.Dims, ["a", "b"]);
        end

        function it_can_partition_into_n_grids(test)
            grid = containers.Grid(rand(3, 4));
            [a, b, c] = grid.partition();

            test.verifyEqual(numel(a.Data) + numel(b.Data) + numel(c.Data), numel(grid.Data));
            test.verifyEqual(c.Dims, grid.Dims);
            test.verifyNotEqual(c.Iter, grid.Iter);
        end

        function it_can_partition_into_n_grids_with_less_dims(test)
            grid = containers.Grid(rand(4, 3));
            a = cell(1, 12);
            [a{:}] = grid.partition(12);
            for k = 1:12
                test.verifyTrue(isscalar(a{k}.Data));
            end
        end

        function it_can_partition_into_n_grids_with_undividable_numel(test)
            grid = containers.Grid(1, {[1 2 3], [1 2 3], [1 2 3]});
            [grids{1:5}] = grid.partition();
            test.verifyLength(grids, 5);
            test.verifyEqual(sum(cellfun(@numel, grids)), numel(grid));           
        end

        function it_can_partition_into_n_grids_with_vector_iter(test)
            grid = containers.Grid(1, {[1 2 3], [1 2 3], [1 2 3; 1 2 3; 1 2 3]});
            [grids{1:2}] = grid.partition();
            test.verifyLength(grids, 2);
            test.verifyEqual(sum(cellfun(@numel, grids)), numel(grid));           
        end

        function it_can_partition_by_function(test)
            grid = containers.Grid(rand(3, 6, 5, 4));
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
            grid = containers.Grid(rand(3, 6, 5, 4));
            [a, b] = grid.partition(@(v) {[v <= 0.5, v > 0.5]});

            test.verifyEqual(numel(a.Data) + numel(b.Data), numel(grid.Data));
            test.verifyTrue(all(a.Data <= 0.5, 'all'));
            test.verifyTrue(all(b.Data  > 0.5, 'all'));
        end

        function it_can_partition_by_slice(test)
            grid = containers.Grid(rand(3, 6, 5, 4));
            [a, b] = grid.partition("x1", 1:2);

            test.verifyEqual(numel(a.Data) + numel(b.Data), numel(grid.Data));
            test.verifyEqual(a.Dims, grid.Dims);
            test.verifyEqual(b.Dims, grid.Dims);
            test.verifyEqual(a.Iter, {1:2, 1:6, 1:5, 1:4});
            test.verifyEqual(b.Iter, {3, 1:6, 1:5, 1:4});
        end

        function it_can_partition_into_varargout(test)
            grid = containers.Grid(false, {1:2, 1:3, 1:1}, ["a", "b", "c"]);

            [a, b, c] = test.verifyWarningFree(@() grid.partition());
            test.verifyEqual(numel(a.Data), 2);
            test.verifyEqual(numel(b.Data), 2);
            test.verifyEqual(numel(c.Data), 2);
            test.verifyFalse(issparse(a) || issparse(b) || issparse(c));
            
            [a, b, c] = test.verifyWarningFree(@() grid.permute([2, 1, 3]).partition());
            test.verifyTrue(issparse(a) || issparse(b) || issparse(c));
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

        function it_can_slice_sparse_by_function(test)
            grid = containers.Grid(false, {1:2, 1:3, 1:3}, ["b", "a", "c"]).sparse();
            grid = test.verifyWarningFree(@() grid.slice(@(value, key) key.a == 3));
            test.verifySize(grid, [2, 1, 3]);
            test.verifyEqual(numel(grid.Data), 6);
        end

        function it_can_partition_only_if_rectangular(test)
            grid = containers.Grid(false, {1:2, 1:3, 1:3}, ["b", "a", "c"]);
            grid = grid.partition(@(value, key) key.a == key.b);
            test.verifyTrue(issparse(grid));
        end

        function it_can_partition_sparse_grid(test)
            grid = makegrid(1, {0:1000:10000, 0:50:200}, {'alt_ft', 'v_kts'});
            grid = sparse(grid);
            [grid1, grid2] = grid.partition();

            test.verifyEqual(numel(grid1) + numel(grid2), numel(grid));

            test.verifyEqual([grid1.Data; grid2.Data], grid.Data);
            test.verifyEqual([grid1.Iter; grid2.Iter], grid.Iter);
            test.verifyEqual(grid1.Dims, grid.Dims);
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
            test.verifyEqual(a("x2", [1, nan]).size(), [2, 2, 3])
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

        function it_fail_to_intersect_two_sparse_grids(test)
            a = containers.Grid(1, {1:3, 1:3, 1:3}, ["a", "b", "c"]).sparse();
            b = containers.Grid(2, {1:3, 1:3, 1:3}, ["f", "e", "d"]).sparse();
            test.verifyError(@() intersect(a, b, @plus), "grid:InvalidUse");
        end

        function it_joins_outer_with_overlap(test)
            a = containers.Grid(1, {1:3, 1:3, 1:3}, ["a", "b", "c"]);
            b = containers.Grid(2, {2:3, 3:3, 1:3}, ["a", "b", "c"]);
            c = union(a, b, @plus, 0);
            test.verifyEqual(c.Iter, {1:3, 1:3, 1:3});
            test.verifyEqual(c.Dims, a.Dims);
            test.verifyEqual(c{2:3, 3:3, 1:3}, 3 * ones(2, 1, 3));
            test.verifyEqual(c{1:1,  : ,  : }, ones(1, 3, 3));
            test.verifyEqual(c{ : , 1:2,  : }, ones(3, 2, 3));
        end

        function it_joins_struct_with_overlap(test)
            a = containers.Grid(struct(a=42), {1:3, 1:3, 1:3}, ["a", "b", "c"]);
            b = containers.Grid(struct(a=43), {2:3, 3:3, 1:3}, ["a", "b", "c"]);

            c = union(a, b, @(a,b) b, struct(a=0));
            test.verifyEqual(c{2:3, 3:3, 1:3}, repmat(struct(a=43), 2, 1, 3));
            test.verifyEqual(c{1:1,  : ,  : }, repmat(struct(a=0), 1, 3, 3));
            test.verifyEqual(c{ : , 1:2,  : }, repmat(struct(a=0), 3, 2, 3));

            c = union(a, b, @(a,b) b);
            test.verifyEqual(c{2:3, 3:3, 1:3}, repmat(struct(a=43), 2, 1, 3));
            test.verifyEqual(c{1:1,  : ,  : }, repmat(struct(a=missing), 1, 3, 3));
            test.verifyEqual(c{ : , 1:2,  : }, repmat(struct(a=missing), 3, 2, 3));
        end

        function it_joins_outer_without_overlap_and_function(test)
            a = containers.Grid(1, {1:2, 1:3, 1:3}, ["a", "b", "c"]);
            b = containers.Grid(2, {3:4, 1:3, 1:3}, ["a", "b", "c"]);
            c = union(a, b);
            test.verifyEqual(c.Iter, {1:4, 1:3, 1:3});
            test.verifyEqual(c.Dims, a.Dims);
            test.verifyEqual(c.Data(1:2, 1:3, 1:3), 1 * ones(2, 3, 3));
            test.verifyEqual(c.Data(3:4, 1:3, 1:3), 2 * ones(2, 3, 3));
        end

        function it_joins_multiple_grids_at_same_time(test)
            a = containers.Grid(1, {1:3, 1:3, 1:3}, ["a", "b", "c"]);
            b = containers.Grid(2, {2:3, 3:3, 1:3}, ["a", "b", "c"]);
            c = containers.Grid(3, {2:3, 3:3, 1:3}, ["a", "b", "c"]);
            d = union(a, {b, c}, @plus, 0);
            test.verifyEqual(d.Iter, {1:3, 1:3, 1:3});
            test.verifyEqual(d.Dims, a.Dims);
            test.verifyEqual(d.Data(2:3, 3:3, 1:3), 6 * ones(2, 1, 3));
            test.verifyEqual(d.Data(1:1,  : ,  : ), 1 * ones(1, 3, 3));
            test.verifyEqual(d.Data( : , 1:2,  : ), 1 * ones(3, 2, 3));
        end
        
        function it_joins_outer_with_vector(test)
            a = containers.Grid(1, {eye(3), 1:3, 1:3}, ["a", "b", "c"]);
            b = containers.Grid(2, {[0, 0; 1, 0; 0, 1], 3:3, 1:3}, ["a", "b", "c"]);
            c = union(a, b, @plus, 0);
            test.verifyEqual(c.Iter, {eye(3), 1:3, 1:3});
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
            d = union(b, a, @plus);

            test.verifyEqual(c.Iter, {1:3, 1:3, 1:5});
            test.verifyEqual(c.Dims, a.Dims);
            test.verifyEqual(c.Data(2:3, 3:3, 1:3), 3.0 * ones(2, 1, 3));
            test.verifyEqual(c.Data(1:1,  : ,  : ), nan * ones(1, 3, 5));
            test.verifyEqual(c.Data( : , 1:2,  : ), nan * ones(3, 2, 5));
            test.verifyEqual(c.Data( : ,  : , 4:5), nan * ones(3, 3, 2));

            % the order of the iterators will be determined by the 1st argument
            test.verifyNotEqual(d, c);
            test.verifyEqual(d.sort(), c.sort());
        end

        function it_joins_empty_grid_with_good_grid(test)
            a = makegrid();
            b = makegrid(2, {1:3}, "b");
            c = union(a, b, @plus);
            test.verifyEqual(c, b);
            c = union(b, a, @plus);
            test.verifyEqual(c, b);
        end

        function it_converts_iter_to_string_if_union_iter_is_already_string(test)
            a = containers.Grid(1, {1:3, [1:3,nan]}, ["a", "b"]);
            b = containers.Grid(2, {1:3, ["a","b","c",string(missing)]}, ["a", "b"]);
            c = union(a, b, @plus);
            test.verifyEqual(c.Dims, ["a", "b"]);
            test.verifyEqual(c.Iter, {1:3, ["1","2","3",string(missing),"a","b","c"]});
        end

        function it_avoids_bug_if_only_one_nan_is_in_2nd_grid(test)
            a = containers.Grid(1, {1:3, [1:3,nan]}, ["a", "b"]);
            b = containers.Grid(2, {1:3, nan}, ["a", "b"]);
            c = union(a, b, @plus);
            test.verifyEqual(c.Dims, ["a", "b"]);
            test.verifyEqual(c.Iter, {1:3, [1:3,nan]});
        end

        function it_fails_to_union_two_sparse_grids(test)
            a = containers.Grid(1, {1:3, 1:3, 1:3}, ["a", "b", "c"]).sparse();
            b = containers.Grid(2, {1:3, 1:3, 1:3}, ["f", "e", "d"]).sparse();
            test.verifyError(@() union(a, b, @plus), "grid:InvalidUse");
        end

        function it_can_be_extended(test)
            a = containers.Grid(1, {1:3, 1:3, 1:3}, ["a", "b", "c"]);
            b = extend(a, "f", 1:3, "e", 1:3, "d", 1:3);
            test.verifyEqual(b.Data, ones(3, 3, 3, 3, 3, 3));
            test.verifyEqual(b.Iter, repmat({1:3}, 1, 6));
            test.verifyEqual(b.Dims, ["a", "b", "c", "f", "e", "d"]);
        end

        function it_can_be_extended_with_nonscalar_iterator(test)
            a = containers.Grid(1, {1:3, 1:3, 1:3}, ["a", "b", "c"]);

            b = test.verifyWarning(@() extend(a, "d", [1; 2; 3]), 'grid:ColumnIterator');

            test.verifyEqual(b.Data, ones(3, 3, 3, 1));
            test.verifyEqual(b.Iter, {1:3, 1:3, 1:3, (1:3)'});
            test.verifyEqual(b.Dims, ["a", "b", "c", "d"]);
        end

        function it_can_be_extended_in_sparse_mode_to_produce_same_dense_grid(test)
            a = containers.Grid(1, {1:3, 1:3, 1:3}, ["a", "b", "c"]).sparse();
            b = extend(a, "f", 1:3, "e", 1:3, "d", 1:3).dense();
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

        function it_can_remove_struct_fields(test)
            grid = makegrid(struct('a', {1, 2, 3}, 'b', {4, 5, 6}));
            test.verifyEqual(grid.except('b').Data, struct('a', {1, 2, 3}));
        end

        function it_can_pluck_struct_fields(test)
            grid = makegrid(struct('a', {1, 2, 3}, 'b', {4, 5, 6}));
            test.verifyEqual(grid.pluck('b').Data, [4, 5, 6]);
        end

        function it_can_pluck_deep_struct_fields(test)
            grid = makegrid(struct('a', num2cell(struct('c', {1, 2, 3})), 'b', {4, 5, 6}));
            test.verifyEqual(grid.pluck('a', 'c').Data, [1, 2, 3]);
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

        function it_can_find_slice_where_value(test)
            grid = makegrid(43, {1:3, 1:3});
            grid{1, :} = 42;
            grid = grid.where(42);
            [~, mask] = grid.where(42);
            test.verifyEqual(grid.Data, repmat(42, 1, 3));
            test.verifyEqual(mask, {true, [true,true,true]});
            test.verifyEqual(grid.Dims, ["x1", "x2"]);
            test.verifyEqual(grid.Iter, {1:1, 1:3});
        end

        function it_can_sort_dimensions_and_iterators(test)
            actual = makegrid([1,2,3;4,5,6;7,8,9], {-1:+1:+1, +1:-1:-1}, ["b", "a"]);
            expect = makegrid([3,6,9;2,5,8;1,4,7], {-1:+1:+1, -1:+1:+1}, ["a", "b"]);
            actual = actual.sort();
            test.verifyEqual(actual.Data, expect.Data);
        end

        function it_can_sort_dimensions_in_sparse_mode(test)
            actual = makegrid([1,2,3;4,5,6;7,8,9], {-1:+1:+1, +1:-1:-1}, ["b", "a"]).sparse();
            actual = actual.sort();
            test.verifyEqual(actual.Dims, ["a", "b"]);
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
            data(1,1,2) = 42;
            grid = containers.Grid(data, {1:5, 1:5, ["up", "down"]}, ["a", "b", "flaps"]);
            test.verifyTrue(grid.contains(42));
            test.verifyFalse(grid.contains(43));

            [~, iter] = grid.contains(42);
            test.verifyEqual(iter, struct("a", 1, "b", 1, "flaps", "down"));
        end

        function it_can_assign_data(test)
            grid = containers.Grid(zeros(5, 2, 2), {1:5, 5:6, ["up", "down"]}, ["a", "b", "flaps"]);
            grid{"a", 1, "b", 5, "flaps", "up"} = 42;
            test.verifyEqual(grid{1, 1, 1}, 42);
            test.verifyEqual(grid{1, 1, 2}, 0);
            test.verifyEqual(sum(grid.Data, 'all'), 42);

            grid("a", 1, "b", 5, "flaps", "down") = makegrid(7, {1, 1, "down"}, ["a", "b", "flaps"]);
            test.verifyEqual(grid{1, 1,  2}, 7);
            test.verifyEqual(sum(grid.Data, 'all'), 49);

            grid{1, 1, 2} = makegrid(7, {1, 1, "down"}, ["a", "b", "flaps"]).Data;
            test.verifyEqual(grid{"a", 1, "b", 5, "flaps", "down"}, 7);
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

            test.verifyEqual(dense(actual, nan), expect);
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
            finally = onCleanup(feval(@(f) @() cd(f), cd(folder)));
            test.verifySize(testsuite('test.mldatx'), [1, 30]);
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
            data = grid.sample(2).sparse();
            test.verifyEqual(size(data.Data), [2, 1]);
            test.verifyInstanceOf(data.Data, 'double');
        end

        function it_can_draw_a_fraction_of_random_samples(test)
            grid = containers.Grid(1, {1:3, 1:4, [[1;2;3], [4;5;6]]}, ["a", "b", "c"]);
            data = grid.sample(0.5).sparse();
            test.verifyEqual(size(data.Data), [12, 1]);
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

        function it_can_define_colon_in_struct_iterator(test)
            expect = containers.Grid(1, {1:3, [[1;2;3], [4;5;6]]}, ["a", "b"]);
            actual = expect(struct("a", {':', ':'}, "b", {[1;2;3], [4;5;6]}));
            test.verifyEqual(actual, expect);
        end

        function it_can_get_size_at_dimension(test)
            grid = containers.Grid(1, {1:3, 1:4, [[1;2;3], [4;5;6]]}, ["a", "b", "c"]);
            test.verifyEqual(size(grid, 1), 3);
            test.verifyEqual(size(grid, 2), 4);
            test.verifyEqual(size(grid, 3), 2);
        end

        function it_can_assign_multiple_values(test)
            grid = containers.Grid(struct('Success', 0), {1:3, 1:4}, ["a", "b"]);
            [grid{"b", 2:3}.Success] = deal(1);
            test.verifyEqual([grid.Data.Success], [0 0 0 1 1 1 1 1 1 0 0 0]);
        end

        function it_can_linear_index_and_get_both_data_and_iterator(test)
            grid = containers.Grid(rand(3, 4), {1:3, 1:4}, ["a", "b"]);
            [data, iter] = grid.at(6);
            test.verifyEqual(data, grid.Data(6));
            test.verifyEqual(iter, struct("a", 3, "b", 2));
        end

        function it_can_linear_index_on_sparse_grid_as_well(test)
            grid = containers.Grid(rand(3, 4), {1:3, 1:4}, ["a", "b"]);
            grid = sparse(grid);
            [data, iter] = grid.at(6);
            test.verifyEqual(data, grid.Data(6));
            test.verifyEqual(iter, struct("a", 3, "b", 2));
        end

        function it_displays_iterator_information(test)
            grid = containers.Grid(true, {1:3, 1:4}, ["a", "b"]); %#ok<NASGU>
            text = evalc('grid');
            test.verifySubstring(text, "2-dimensional");
            test.verifySubstring(text, "a: [1 2 3]");
            test.verifySubstring(text, "b: [1 2 3 4]");
            test.verifySubstring(text, "= 12 iterations");
            test.verifySubstring(text, "logical");
            test.verifySubstring(text, "12 are <true>");
        end

        function it_displays_sparse_iterator_information(test)
            grid = containers.Grid(rand(3, 4), {1:3, 1:4}, ["a", "b"]).sparse(); %#ok<NASGU>
            text = evalc('grid');
            test.verifySubstring(text, "2-dimensional");
            test.verifySubstring(text, "sparse");
            test.verifySubstring(text, "{""a"":2,""b"":3}");
            test.verifySubstring(text, "= 12 iterations");
            test.verifySubstring(text, "double");
        end

        function it_display_data_bytes_size_in_human_readable_format(test)
            grid = makegrid(zeros(1, 1e1)); %#ok<NASGU>
            test.verifySubstring(evalc('grid'), " bytes");
            grid = makegrid(zeros(10, 10)); %#ok<NASGU>
            test.verifySubstring(evalc('grid'), "2 kB");
            grid = makegrid(zeros(10, 10, 10, 10, 10, 2)); %#ok<NASGU>
            test.verifySubstring(evalc('grid'), "2 MB");
            grid = makegrid(zeros(10, 10, 10, 10, 10, 10, 10, 10, 2)); %#ok<NASGU>
            test.verifySubstring(evalc('grid'), "2 GB");
        end

        function it_knows_if_empty(test)
            grid = makegrid();
            test.verifyTrue(grid.isempty());
        end

        function it_returns_empty_size_if_no_iterators(test)
            grid = makegrid();
            test.verifyEqual(size(grid), zeros(1, 2));
        end

        function it_can_assign_size_to_nargout(test)
            grid = makegrid(1, {1:3, 1:4}, ["a", "b"]);

            [a, b] = size(grid);
            test.verifyEqual(a, 3);
            test.verifyEqual(b, 4);

            grid = sparse(grid);

            [a, b] = size(grid);
            test.verifyEqual(a, 3);
            test.verifyEqual(b, 4);
        end

        function it_can_pipe_function_with_zero_nargout(test)
            a = containers.Grid(rand(3, 4), {1:3, 1:4}, ["a", "b"]);
            b = a.pipe(@silent);
            test.verifyEqual(a, b);

            function silent(~)
            end
        end

        function it_can_squeeze_out_singular_dimensions(test)
            [grid, iter] = makegrid(1, {1:3, 1:1, 1:4}, ["a", "b", "c"]).squeeze();
            test.verifyEqual(size(grid), [3, 4]);
            test.verifyEqual(grid.Dims, ["a", "c"]);
            test.verifyEqual(iter, struct("b", 1));
        end

        function it_can_squeeze_out_singular_dimensions_with_nonscalar_iter(test)
            test.applyFixture(matlab.unittest.fixtures.SuppressedWarningsFixture("grid:ColumnIterator"));
            [grid, iter] = makegrid(1, {1:3, [1; 2], 1:4}, ["a", "b", "c"]).squeeze();
            test.verifyEqual(size(grid), [3, 4]);
            test.verifyEqual(grid.Dims, ["a", "c"]);
            test.verifyEqual(iter, struct("b", [1; 2]));
        end

        function it_can_squeeze_out_singular_dimensions_sparse(test)
            [grid, iter] = makegrid(1, {1:3, 1:1, 1:4}, ["a", "b", "c"]).sparse().squeeze();
            test.verifyEqual(size(grid), [3, 4]);
            test.verifyEqual(grid.Dims, ["a", "c"]);
            test.verifyEqual(iter, struct("b", 1));
        end

        function it_can_squeeze_out_singular_dimensions_sparse_with_nonscalar_it(test)
            test.applyFixture(matlab.unittest.fixtures.SuppressedWarningsFixture("grid:ColumnIterator"));
            [grid, iter] = makegrid(1, {1:3, [1; 2], 1:4}, ["a", "b", "c"]).sparse().squeeze();
            test.verifyEqual(size(grid), [3, 4]);
            test.verifyEqual(grid.Dims, ["a", "c"]);
            test.verifyEqual(iter, struct("b", [1; 2]));
        end

        function it_can_squeeze_out_singular_nan_dimensions_sparse(test)
            [grid, iter] = makegrid(1, {1:3, nan, 1:4}, ["a", "b", "c"]).sparse().squeeze();
            test.verifyEqual(size(grid), [3, 4]);
            test.verifyEqual(grid.Dims, ["a", "c"]);
            test.verifyEqual(iter, struct("b", nan));
        end

        function it_leaves_single_nonsingular_dimension_in_dim_1(test)
            [grid, iter] = makegrid(1, {1:1, 1:1, 1:4}, ["a", "b", "c"]).squeeze();
            test.verifyEqual(size(grid), [4, 1]);
            test.verifyEqual(size(grid.Data), [4, 1]);
            test.verifyEqual(grid.Dims, "c");
            test.verifyEqual(grid.Iter, {1:4});
            test.verifyEqual(iter, struct("a", 1, "b", 1));
        end

        function it_leaves_single_nonsingular_dimension_from_2d_in_dim_1(test)
            [grid, iter] = makegrid(1, {1:1, 1:4}, ["a", "b"]).squeeze();
            test.verifyEqual(size(grid), [4, 1]);
            test.verifyEqual(size(grid.Data), [4, 1]);
            test.verifyEqual(grid.Dims, "b");
            test.verifyEqual(grid.Iter, {1:4});
            test.verifyEqual(iter, struct("a", 1));
        end

        function it_can_slice_by_value_in_struct_field(test)
            grid = makegrid(struct('a', {1, 2; 1, 2}, 'b', {4, 4; 5, 5}));
            grid = grid(".a", 2);
            test.verifyEqual(grid.Data, struct('a', {2; 2}, 'b', {4; 5}));
        end

        function it_can_use_a_2d_celll_to_define_grid_with_iter(test)
            grid = makegrid(1, {
                'a', 1:3
                'b', 1:4
            });
            test.verifyEqual(grid.Data, ones(3, 4));
            test.verifyEqual(grid.Dims, ["a", "b"]);
            test.verifyEqual(grid.Iter, {1:3, 1:4});
        end

        function it_cannot_have_two_nan_in_one_iter(test)
            test.verifyError(@() makegrid(1, {1:3, [1, nan, nan]}), "grid:InvalidInput");
            test.verifyError(@() makegrid(1, {1:3, ["1", nan, nan]}), "grid:InvalidInput");
        end

        function it_assigns_struct_field_correctly(test)
            grid = makegrid(struct('a', {1, 2; 1, 2}, 'b', {4, 4; 5, 5}));
            grid.Data(1, 1).a = 42;
            test.verifyEqual(grid.Data(1, 1).a, 42);
        end

        function it_extracts_deep_struct_field_via_subsref(test)
            grid = makegrid(struct('a', num2cell(struct('c', {[1;2], [3;4], [5;6]})), 'b', {4, 5, 6}));

            test.verifyEqual(grid.pluck("a", "c", 2).data(), [2, 4, 6]);
            test.verifyEqual(grid.pluck("a", "c", 2).data(), grid.pluck('a', 'c', 2).Data);
        end

        function it_has_functional_accessors_for_data_and_iter(test)
            grid = makegrid(1, {1:3, 1:4}, ["a", "b"], User = struct(A = 42));

            test.verifyEqual(grid.Data, grid.data());
            test.verifyEqual(grid.Iter{2}, grid.iter("b"));
            test.verifyEqual(grid.User, grid.user());

            test.verifyEqual(grid.data(zeros(3, 4)).data(), zeros(3, 4));
            test.verifyEqual(grid.iter("b", 6:9).iter(), {1:3, 6:9});
            test.verifyEqual(grid.user(A = 43).user().A, 43);
        end

        function it_can_index_sparse_with_iter_array(test)
            envelope = makegrid(0, {[-2,0,2,10],[-2,0,2],[-2,0,2],[0:100:100]}, {'u','v','w','h'});
            evidence = envelope.sample(0.4);
            test.assertTrue(evidence.issparse());

            % Indexing using iterStruct is working when envelope grid is dense AND evidence grid is sparse
            plots1 = envelope(evidence.Iter);
            test.verifyTrue(iscompatible(plots1, evidence));

            % Indexing using iterStruct is NOT working when envelope grid is sparse
            envelopeSparse = envelope.sparse();
            plots2 = envelopeSparse(evidence.Iter);
            test.verifyEqual(plots1, plots2);
        end

        function it_can_add_hint_for_map_function_nargin(test)
            % calc mean([point1, point2]) instead of mean(point1, point2) by forcing nargin == 1
            test.verifyError(@() map(makegrid(rand(5, 5)), makegrid(rand(5, 5)), @mymean), "MATLAB:getdimarg:invalidDim");
            test.verifyWarningFree(@() map(makegrid(rand(5, 5)), makegrid(rand(5, 5)), @mymean, 1));
        end

        function iter2struct_returns_correct_structs(test)
            a = iter2struct({1:5, 1:5, ["up","down"]}, ["a", "b", "c"]);
            test.verifyEqual(fieldnames(a), {'a';'b';'c'});
            test.verifyEqual(numel(a), 50);
        end

        function it_indexes_correctly(test)
            grid = makegrid(struct('x', [1 2 3 4 5 6]), {1:3, 1:3, 1:3}, ["a", "b", "c"]);

            test.verifyEqual(grid{1}.x(1), grid.Data(1).x(1));
        end

        function it_indexes_sparse_with_keyvalue(test)
            d = makegrid(rand(2, 2, 2), {1:2, 3:4, 5:6});
            s = sparse(d);
            test.verifyEqual(s(x1=1, x2=4).Data, reshape(d.Data(1, 2, :), [], 1));
            test.verifyEqual(s(struct(x1=1, x2=4)).Data, reshape(d.Data(1, 2, :), [], 1));
        end

        function it_can_extract_dims_in_functional_way(test)
            grid = makegrid(1, {1:3, 1:4}, ["a", "b"]);
            test.verifyEqual(["a", "b"], grid.dims());
        end

        function it_can_set_dims_in_functional_way(test)
            grid = makegrid(1, {1:3, 1:4}, ["a", "b"]);
            grid = grid.dims(["x", "y"]);
            test.verifyEqual(["x", "y"], grid.Dims);
        end

        function it_can_rename_one_dim_in_functional_way(test)
            grid = makegrid(1, {1:3, 1:4}, ["a", "b"]);
            grid = grid.dims(a = "x");
            test.verifyEqual(["x", "b"], grid.Dims);
        end
    end

    methods (Test, TestTags = "parpool")
        function it_can_be_parallelized(test)
            test.assumeTrue(exist("parpool", "file") == 2);

            if isempty(gcp('nocreate'))
                pool = parpool('local', 2);
                finally = onCleanup(@() delete(pool));
            end

            grid = containers.Grid(false(2, 2, 2, 2, 'distributed'));
            grid = test.verifyWarningFree(@() grid.map(@not));
            test.verifyTrue(all(grid.Data, 'all'));

            grid = containers.Grid(false(2, 2, 2, 2));
            test.verifyFalse(isdistributed(grid.Data));

            grid = distributed(containers.Grid(false(2, 2, 2, 2)));
            test.verifyTrue(isdistributed(grid.Data));

            grid = gather(grid);
            test.verifyFalse(isdistributed(grid.Data));

            sz = [2, 2, 1, 2, 1];
            grid1 = containers.Grid(rand(sz));
            grid2 = containers.Grid(rand(sz));
            parallelResult = map(distributed(grid1), distributed(grid2), @(a, b, k) a + b + k.x1).gather();
            serialResult = map(grid1, grid2, @(a, b, k) a + b + k.x1);
            test.verifyEqual(parallelResult, serialResult);
        end
    end
end

function x = mymean(x, d)
    arguments
        x
        d = []
    end

    assert(isempty(d), "MATLAB:getdimarg:invalidDim", "fake the R2021a version");
    x = mean(x);
end
