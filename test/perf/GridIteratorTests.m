classdef GridIteratorTests < matlab.perftest.TestCase %#ok<*NASGU,*ASGLU>

    methods (Test)
        function assign_by_name(test)
            grid = test.make_test_grid();

            while test.keepMeasuring()
                sz = [10, 10, 5, 2];
                c = cell(sz);
                iter = struct(x1=c,x2=c,x3=c,x4=c);
                orig = grid.Iter;
                dims = grid.Dims;
                subs = cell(1, 4);

                for k = 1:numel(c)
                    [subs{:}] = ind2sub(sz, k);
                    for iDim = 1:4
                        iter(k).(dims(iDim)) = orig{iDim}(:, subs{iDim});
                    end
                end
            end

            test.assertEqual(iter(42), struct(x1=2,x2='e',x3=[1;2],x4="up"));
        end

        function assign_with_jit(test)
            grid = test.make_test_grid();

            while test.keepMeasuring()
                sz = [10, 10, 5, 2];
                c = cell(sz);
                iter = struct(x1=c,x2=c,x3=c,x4=c);
                orig = grid.Iter;
                subs = cell(1, 4);

                for k = 1:numel(c)
                    [subs{:}] = ind2sub(sz, k);
                    iter(k).x1 = orig{1}(:, subs{1});
                    iter(k).x2 = orig{2}(:, subs{2});
                    iter(k).x3 = orig{3}(:, subs{3});
                    iter(k).x4 = orig{4}(:, subs{4});
                end
            end

            test.assertEqual(iter(42), struct(x1=2,x2='e',x3=[1;2],x4="up"));
        end

        function use_mex(test)
            grid = test.make_test_grid();

            while test.keepMeasuring()
                iter = iter2struct(grid.Iter, grid.Dims);
            end

            test.assertEqual(iter(42), struct(x1=2,x2='e',x3=[1;2],x4="up"));
        end

        function use_map_might_use_mex(test)
            grid = test.make_test_grid();

            while test.keepMeasuring()
                iter = grid.map(@(~, it) it).data();
            end

            test.assertEqual(iter(42), struct(x1=2,x2='e',x3=[1;2],x4="up"));
        end
    end

    methods
        function grid = make_test_grid(~)
            grid = makegrid(true, {1:10, 'abcdefghij', [1:5; 2:6], ["up", "down"]});
        end
    end
end
