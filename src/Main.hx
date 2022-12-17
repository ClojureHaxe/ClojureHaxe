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

class Main {
	static function main() {
		/*trace("Hello Haxe!!!");

			var s = new Symbol("school", "user");
			var s2 = Symbol.internNSname("school/user");
			trace(s, s2);
		 */

		// trace(Type.getClass(s) == Type.getClass(s2));
		// trace(Type.typeof(s) == Type.typeof(s2));
		// trace(s.equals(s2));
		// trace(s.equals(10));
		// //trace(haxe.Log.formatOutput(20 ));

		// trace(RT.printString(null));
		// trace(U.instanceof(10, Int));
		trace("=========== START ============");
		var a1:ArraySeq = ArraySeq.create(1, 2, 3, 4);
		var a2:ArraySeq = ArraySeq.create("1", "2", "3", "4");
		var a3:ArraySeq = ArraySeq.create(1, "Hello", ArraySeq.create(10, 20, 30));
		trace(a1.toString());
		trace(a2.toString());
		trace(a3.toString());

		var types:Array<Any> = [10, 20.4, "Hello", true, null, a3];

		trace("===== TYPES =====");
		for (i in types) {
			trace('$i -  ${U.typeName(i)}');
		}

		var k:Keyword = Keyword.create("user", "age");
		var k2:Keyword = Keyword.createNSname("key");
		trace(k, k2);

		var p:PersistentList = new PersistentList("Hello");
		trace(p.toString());
		p = p.cons("1");
		p = p.cons(k);
		p = p.cons(k2);
		trace(p);

		trace("========== PersistentVector ============");
		var pp1:PersistentVector = PersistentVector.createFromISeq(p);
		trace(U.instanceof(pp1, IPersistentVector));
		trace(U.getClassName(pp1));
		// trace(pp1.toString());
		trace(pp1);

		// Sys.println(pp1);

		var pp2:Any = pp1;
		trace(U.instanceof(pp2, IPersistentVector));
		trace(RT.printString(pp2));

		var pp3:PersistentVector = PersistentVector.createFromItems(1, 2, 3);
		pp3 = pp3.cons(pp3);
		trace(pp3);

		// var pp3 = PersistentVector.createFromItems(pp1, pp2, p);
		// trace(pp3);
		trace("=============== PersistentHashMap ============");
		var hm:IPersistentMap = PersistentHashMap.create(1, 2, 3, 4);
		hm = cast hm.assoc(Keyword.create(null, "hello"), pp1);
		trace(hm.count());
		trace(hm);
		// trace(hm.toString());
		/*for (v in hm.iterator()){
			trace("iter", v);
		}*/
		/*
			trace("=============== PersistentHashMap ============");
			var hs:PersistentHashSet = PersistentHashSet.create(1,2,3);
			trace(hs);
		 */
	}
}
