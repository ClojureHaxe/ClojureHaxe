import utest.Runner;
import utest.ui.Report;

import lang.*;

private var init:Bool = Init.init();

class Tests {
	static function main() {
		RT.staticInit();

		// utest.UTest.run([new test.CompilerTest()]);
		// utest.UTest.run([new test.NamespaceTest()]);
		// the long way

		var runner = new Runner();
		runner.addCases(test);
		Report.create(runner);
		runner.run();
	}
}
