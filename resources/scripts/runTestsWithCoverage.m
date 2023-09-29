if isempty(gcp('nocreate'))
    parpool(2)
end

cd(fileparts(fileparts(fileparts(mfilename('fullpath')))));

ts = matlab.unittest.TestSuite.fromFolder('test/unit');
tr = matlab.unittest.TestRunner.withTextOutput();
tr.addPlugin(matlab.unittest.plugins.CodeCoveragePlugin.forFolder('code', 'IncludingSubfolders', true, 'Producing', matlab.unittest.plugins.codecoverage.CoberturaFormat('coverage.xml')));
tr.run(ts)
