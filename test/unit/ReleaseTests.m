classdef ReleaseTests < AbstractTestCase

    methods (Test)
        function all_functions_have_proper_pragmas(test)
            base = currentProject().RootFolder + "/code/+containers/@Grid/";
            main = fileread(base + "Grid.m");

            for file = dir(base + "*.m")'
                if file.name == "Grid.m"
                    continue
                end

                test.verifySubstring(main, "%#release include file " + file.name);

                code = fileread(base + file.name);

                test.verifySubstring(code, "%#release exclude file");

                line = extractBefore(code, sprintf("\r\n") | newline);
                test.verifyTrue(strlength(line) > 0, "Bad function header in " + file.name);
                test.verifySubstring(main, replace(line, "function ", ""), "Missing abstract function " + file.name);

                if not(ismember(file.name, ["subsref.m", "subsasgn.m", "numArgumentsFromSubscript.m"]))
                    test.verifySubstring(main, sprintf("%%   %-12s  -  ", extractBefore(file.name, ".")));
                end
            end
        end
    end
end
