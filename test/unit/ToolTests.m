classdef ToolTests < AbstractTestCase

    methods (Test)
        function it_can_use_makegrid(test)
            grid = makegrid(rand(5, 5, 5));
            test.verifyInstanceOf(grid, 'containers.Grid');
        end

        function it_has_makegrid_as_alias_for_grid(test)
            data = rand(3);
            expect = containers.Grid(data, {1:3, 2:4}, ["a", "b"]);
            actual = makegrid(data, {1:3, 2:4}, ["a", "b"]);

            test.verifyEqual(actual, expect);
        end

        function it_can_store_file_with_savegrid_and_loadgrid(test)
            temp = test.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture());
            file = temp.Folder + "/grid.mat";
            expect = containers.Grid(rand(3), {1:3, 2:4}, ["a", "b"]);

            savegrid(file, expect);
            actual = loadgrid(file);
            stored = load(file);

            test.verifyEqual(actual, expect);
            test.verifyEqual(stored, struct(expect));
        end

        function it_has_savegrid_that_can_be_chained(test)
            temp = test.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture());
            file = temp.Folder + "/grid.mat";

            expect = containers.Grid(rand(3), {1:3, 2:4}, ["a", "b"]);
            actual = savegrid(file, expect);

            test.verifyEqual(actual, expect);
        end

        function it_can_identify_grid_with_isgrid(test)
            test.verifyTrue(isgrid(containers.Grid(rand(3), {1:3, 2:4}, ["a", "b"])));
            test.verifyFalse(isgrid(rand(3)));
        end
    end
end