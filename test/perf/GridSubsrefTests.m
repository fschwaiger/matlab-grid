classdef GridSubsrefTests < matlab.perftest.TestCase %#ok<*NASGU,*ASGLU>

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

        function subsasgn_with_braces(test)
            grid = makegrid(true, {1:10, 1:10, 1:10, 1:10, 1:10});
            
            while test.keepMeasuring()
                grid{randi(10000)+1} = false;
            end
        end

        function subsasgn_with_data(test)
            grid = makegrid(true, {1:10, 1:10, 1:10, 1:10, 1:10});
            
            while test.keepMeasuring()
                grid.Data(randi(10000)+1) = false;
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
