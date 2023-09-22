/*import lang.U.EMPTY_ARG;
	import lang.ISeq;
	import lang.Seqable;
	import lang.IFn;
	import lang.IReduce;
	import lang.Symbol;
	import lang.ILookup;
	import lang.StringSeq;
	import lang.U;
 */

import Map.IMap;
import lang.Murmur3;
import haxe.Int64;
import lang.U;
import lang.ArraySeq;
import lang.RT;
import lang.Symbol;
import lang.PersistentList;
import lang.Keyword;
import lang.*;
import lang.APersistentVector;
import lang.PersistentVector;
import lang.APersistentSet;
import lang.PersistentHashSet;
import lang.PersistentHashMap;
import lang.AReference;
import lang.Namespace;
import lang.EdnReader;

private var init:Bool = {
	// trace("Static field initialization");
	PersistentHashMap.BitmapIndexedNode.EMPTY;
	PersistentHashMap.EMPTY;
	//trace("PersistentHashMap.EMPTY", PersistentHashMap.EMPTY);
	//trace(PersistentHashMap.create(1,2));
	//Namespace.namespaces;	
	PersistentList.EMPTY;
	//PersistentHashMap.EMPTY;
	//
	true;
};


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
