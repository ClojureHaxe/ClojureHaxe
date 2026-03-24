import lang.*;

private var init:Bool = Init.init();

class Main {
	static function main() {
		// //trace(haxe.Log.formatOutput(20 ));

		// trace(U.instanceof(10, Int));

		// trace(Util.classOf(pp2));
		readerTest();
		// trace(EdnReader.readString("  \\zz", PersistentArrayMap.EMPTY));
	}

	private static function typesTest() {
		trace("=========== START ============");

		var types:Array<Any> = [10, 20.4, "Hello", true, null, ArraySeq.create(1, 2, 3)];

		trace("===== TYPES =====");
		for (i in types) {
			trace('$i -  ${U.typeName(i)}');
		}
	}

	private static function readerTest() {
		trace("======================= EdnReader test ===================");

		/*var m =  new EReg("^([-+]?)(?:(0)|([1-9][0-9]*)|0[xX]([0-9A-Fa-f]+)|0([0-7]+)|([1-9][0-9]?)[rR]([0-9A-Za-z]+)|0[0-9]+)(N)?$", "");

			var m2 =  new EReg("^([-+]?)
			(?:  (0) | ([1-9][0-9]*) |  0[xX]([0-9A-Fa-f]+) | 0([0-7]+) | ([1-9][0-9]?) [rR] ([0-9A-Za-z]+) | 0[0-9]+)  (N)?

			$", "");
		 */

		// trace(m.match("0x10112M"));
	}
}
