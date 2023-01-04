package test;

import lang.PersistentTreeMap;
import lang.ArraySeq;
import lang.Keyword;
import utest.Test;
import utest.Assert;

class PersistentTreeMapTest extends Test {
	function test() {
		// Numbers
		var a:ArraySeq = ArraySeq.create(3, 3, 1, 1, 2, 2);
		var p:PersistentTreeMap = PersistentTreeMap.createFromISeq(a);
		Assert.equals("{1 1, 2 2, 3 3}", p.toString());
		p = p.assoc(5, 5);
		p = p.assoc(4, 4);
		Assert.equals("{1 1, 2 2, 3 3, 4 4, 5 5}", p.toString());
		p = p.without(2);
		Assert.equals("{1 1, 3 3, 4 4, 5 5}", p.toString());
		p = p.assoc(2, 2);
		Assert.equals("{1 1, 2 2, 3 3, 4 4, 5 5}", p.toString());

		// String
		// trace("====================== PersistentTreeMapTest Strings =======================");
		var a2:ArraySeq = ArraySeq.create("a", "a", "d", "d", "c", "c", "b", "b");
		var p2:PersistentTreeMap = PersistentTreeMap.createFromISeq(a2);
		Assert.equals('{"a" "a", "b" "b", "c" "c", "d" "d"}', p2.toString());
		p2 = p2.without("b");
		Assert.equals('{"a" "a", "c" "c", "d" "d"}', p2.toString());

		// trace("====================== PersistentTreeMapTest Symbols =======================");
		// Comparable
		var a3:ArraySeq = ArraySeq.create(Keyword.createNSname("d"), "d", Keyword.createNSname("a"), "a", Keyword.createNSname("b"), "b");
		var p3:PersistentTreeMap = PersistentTreeMap.createFromISeq(a3);
		Assert.equals('{:a "a", :b "b", :d "d"}', p3.toString());
	}
}
