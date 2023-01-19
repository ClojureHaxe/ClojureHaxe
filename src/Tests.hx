import utest.Runner;
import utest.ui.Report;
// import lang.PersistentTreeMap;
import lang.PersistentHashMap;
// import lang.RT;
import lang.*;


// Initialization order
// To initialize all static fields in class it is enough to make access to some static field 
// of that class
private var init:Bool = {

	PersistentHashMap.BitmapIndexedNode.EMPTY;
	PersistentHashMap.EMPTY;
	
	PersistentList.EMPTY;
	//PersistentHashMap.EMPTY;
	//
	true;
}

class Tests {
	static function main() {
		RT.staticInit();

		// utest.UTest.run([new test.EdnReaderTest()]);

		// the long way
		var runner = new Runner();
		runner.addCases(test);
		Report.create(runner);
		runner.run();
	}
}
