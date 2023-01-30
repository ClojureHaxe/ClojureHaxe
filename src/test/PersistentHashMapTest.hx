package test;

import lang.*;
import utest.Test;
import utest.Assert;

class PersistentHashMapTest extends Test {
	function test() {
		var hm:IPersistentMap = PersistentHashMap.create(1, 2, 3, 4, 5, 6, 7, 8);
		var pp1:PersistentVector = PersistentVector.createFromISeq(new PersistentList("Hello"));
		var kw:Keyword = Keyword.create(null, "hello");
		hm = cast hm.assoc(kw, pp1);
		Assert.equals(5, hm.count());
		Assert.isTrue(Util.equiv(PersistentArrayMap.create(1, 2, 3, 4, 5, 6, 7, 8, kw, pp1), hm));

		var i:Int = 0;
		for (v in hm.iterator()) {
			Assert.isTrue(U.instanceof(v, IMapEntry));
			// trace("iter", v, Std.isOfType(v, IMapEntry));
			i++;
		}
		Assert.equals(5, i);

		// find
		Assert.isTrue(hm.containsKey(1));
		var hm2:PersistentHashMap = PersistentHashMap.create(Symbol.internNSname("Inf"), 1);
		Assert.isTrue(hm2.containsKey(Symbol.internNSname("Inf")));

		// Symbol
		var hm2:PersistentHashMap = PersistentHashMap.EMPTY;
		var s1:Symbol = Symbol.createNSname("clojure.core");
		hm2 = cast hm2.assoc(s1, s1);
		Assert.equals(s1, hm2.get(Symbol.createNSname("clojure.core")));

		// Entry
		var me:IMapEntry = hm2.entryAt(s1);
		Assert.equals(s1, me.key());
		Assert.equals(s1, me.val());
	}
}
