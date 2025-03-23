classdef (SharedTestFixtures = {
        matlab.unittest.fixtures.ProjectFixture(fileparts(fileparts(fileparts(mfilename('fullpath')))))
    }) GridSubsrefTests < matlab.perftest.TestCase %#ok<*NASGU,*ASGLU>

    methods (Test)
        function subref_dims(test)
            grid = test.make_test_grid();
            
            while test.keepMeasuring()
                x1 = grid.x1;
                x2 = grid.x2;
            end
        end

        function subsref_data(test)
            grid = test.make_test_grid();
            
            while test.keepMeasuring()
                a = grid.Data(randi(50)).a;
                b = grid.Data(randi(50)).b;
            end
        end

        function subsref_data_cell(test)
            grid = test.make_test_grid();
            
            while test.keepMeasuring()
                data = grid{"x1", randi(5), "x2", randi(10)};
            end
        end

        function subsref_data_parentheses(test)
            grid = test.make_test_grid();
            
            while test.keepMeasuring()
                data = grid("x1", randi(5), "x2", randi(10)).Data;
            end
        end

        function subsref_data_linear(test)
            grid = test.make_test_grid();
            
            while test.keepMeasuring()
                data = grid{randi(50)};
            end
        end

        function select_data_at(test)
            grid = test.make_test_grid();
            
            while test.keepMeasuring()
                data = grid.at(randi(50));
            end
        end

        function subsref_data_at_with_iter(test)
            grid = test.make_test_grid();
            
            while test.keepMeasuring()
                [data, iter] = grid.at(randi(50));
            end
        end

        function subsref_data_struct(test)
            grid = test.make_test_grid();
            
            while test.keepMeasuring()
                a = grid.a(4);
                b = grid.b;
            end
        end

        function raer1_read_baseline(test)
            grid = makegrid(0, {1:10, 1:10, 1:10});
            data = grid.Data;

            while test.keepMeasuring()
                for k = 1:1e3
                    r = data(k);
                end
            end
        end

        function raer1_read_overhead_with_braces(test)
            grid = makegrid(0, {1:10, 1:10, 1:10});

            while test.keepMeasuring()
                for k = 1:1e3
                    r = grid{k};
                end
            end
        end

        function raer1_read_overhead_with_props(test)
            grid = makegrid(0, {1:10, 1:10, 1:10});

            while test.keepMeasuring()
                for k = 1:1e3
                    r = grid.Data(k);
                end
            end
        end

        function raer2_write_baseline(test)
            grid = makegrid(0, {1:10, 1:10, 1:10});
            data = grid.Data;

            while test.keepMeasuring()
                for k = 1:1e3
                    data(k) = 1;
                end
            end
        end

        function raer2_write_overhead_with_braces(test)
            grid = makegrid(0, {1:10, 1:10, 1:10});
            
            while test.keepMeasuring()
                for k = 1:1e3
                    grid{k} = 1;
                end
            end
        end
        
        function raer2_write_overhead_with_props(test)
            grid = makegrid(0, {1:10, 1:10, 1:10});
            
            while test.keepMeasuring()
                for k = 1:1e3
                    grid.Data(k) = false;
                end
            end
        end
    end

    methods
        function grid = make_test_grid(~)
            grid = makegrid(struct( ...
                'a', mat2cell(rand(25, 10), [5,5,5,5,5], ones(1, 10)), ...
                'b', num2cell(repmat({struct('c', rand(1, 1))}, 5, 10)) ...
            ));
        end
    end
end
