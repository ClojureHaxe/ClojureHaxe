import utest.Runner;
import utest.ui.Report;

class Tests {
	static function main() {
		// utest.UTest.run([new test.EdnReaderTest()]);

		// the long way
		var runner = new Runner();
		runner.addCases(test);
		Report.create(runner);
		runner.run();
	}
}
