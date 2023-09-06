classdef (SharedTestFixtures = {
    matlab.unittest.fixtures.ProjectFixture([fileparts(mfilename('fullpath')), '/../..'])
}) DemoTests < matlab.unittest.TestCase

    properties (TestParameter)
        name = strsplit(strip(ls([fileparts(mfilename('fullpath')), '/../../demo'])))
    end

    methods (Test)
        function demo_case_runs(test, name)
            folder = [fileparts(mfilename('fullpath')), '/../../demo/', name];
            test.applyFixture(matlab.unittest.fixtures.CurrentFolderFixture(folder));
            finally = onCleanup(@() clean_up());

            evalc("run('main');");
        end
    end
end

function clean_up()
    close all
    bdclose all
    !git clean -dxf
end
