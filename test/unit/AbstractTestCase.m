classdef (Abstract, SharedTestFixtures = {
        matlab.unittest.fixtures.ProjectFixture(fileparts(fileparts(fileparts(mfilename('fullpath')))))
    }) AbstractTestCase < matlab.mock.TestCase

    % superclass with shared test fixture
end
