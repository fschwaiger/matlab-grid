classdef GridIteratorTests < matlab.perftest.TestCase %#ok<*NASGU,*ASGLU>

    methods (Test)
        function method1(test)
            grid = test.make_test_grid();

            while test.keepMeasuring()
                sz = [10, 10, 10, 10, 10];
                c = cell(sz);
                iter1 = struct(x1=c,x2=c,x3=c,x4=c,x5=c);
                iters = grid.Iter;
                dims = grid.Dims;
                subs = cell(1, 5);

                for k = 1:numel(c)
                    [subs{:}] = ind2sub(sz, k);
                    for iDim = 1:5
                        iter1(k).(dims(iDim)) = iters{iDim}(:, subs{iDim});
                    end
                end
            end
        end

        function method2(test)
            grid = test.make_test_grid();

            while test.keepMeasuring()
                sz = [10, 10, 10, 10, 10];
                c = cell(sz);
                iter2 = struct(x1=c,x2=c,x3=c,x4=c,x5=c);
                iters = grid.Iter;
                subs = cell(1, 5);

                for k = 1:numel(c)
                    [subs{:}] = ind2sub(sz, k);
                    iter2(k).x1 = iters{1}(:, subs{1});
                    iter2(k).x2 = iters{2}(:, subs{2});
                    iter2(k).x3 = iters{3}(:, subs{3});
                    iter2(k).x4 = iters{4}(:, subs{4});
                    iter2(k).x5 = iters{5}(:, subs{5});
                end
            end
        end

        function method3(test)
            grid = test.make_test_grid();

            while test.keepMeasuring()
                sz = [10, 10, 10, 10, 10];
                c = cell(sz);
                cc = {c, c, c, c, c};
                iter3 = struct(x1=c,x2=c,x3=c,x4=c,x5=c);
                iters = grid.Iter;
                dims = grid.Dims;
                subs = cell(1, 5);
                for k = 1:numel(c)
                    [subs{:}] = ind2sub(sz, k);
                    for j = 1:5
                        cc{j}{k} = iters{j}(:, subs{j});
                    end
                end
                for j = 1:5
                    [iter3.(dims(j))] = cc{j}{:};
                end
            end
        end

        function method4(test)
            grid = test.make_test_grid();

            while test.keepMeasuring()
                iter4 = iter2struct(grid.Iter, cellstr(grid.Dims));
            end
        end

        function method5(test)
            grid = test.make_test_grid();

            while test.keepMeasuring()
                iter5 = grid.map(@(~, it) it).data();
            end
        end
    end

    methods
        function grid = make_test_grid(~)
            grid = makegrid(true, {1:10, 1:10, 'abcdefghij', [1:10; 2:11], 1:10});
        end
    end
end
