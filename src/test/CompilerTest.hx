package test;

import lang.PersistentHashSet;
import lang.IPersistentMap;
import lang.Compiler;
import lang.Keyword;
import lang.Util;
import lang.PersistentVector;
import lang.U;
import utest.Test;
import utest.Assert;

class CompilerTest extends Test {
	function readEval(s:String):Any {
		return Compiler.load(s, "sourcePath", "sourceName");
	}

	function test() {
		Assert.equals(null, readEval("nil"));
		Assert.equals(true, readEval("true"));
		Assert.equals(false, readEval("false"));
		Assert.equals("hello", readEval('"hello"'));
		Assert.equals(10, readEval("10"));
		Assert.equals(10.5, readEval("10.5"));
		Assert.isTrue(Keyword.create1("keyword").equals(readEval(":keyword")));

		Assert.equals(3, readEval("(do 1 2 3)"));

		// map
		var m:IPersistentMap = readEval("(do 1 2 {:a 1 :b 2})");
		Assert.equals(2, m.count());
		Assert.equals(1, m.valAt(Keyword.intern1("a")));
		Assert.equals(2, m.valAt(Keyword.intern1("b")));

		// vector
		Assert.isTrue(Util.equals(PersistentVector.createFromItems(1, 2, 3), readEval("[1,2,3]")));

		// set
		Assert.isTrue(Util.equals(PersistentHashSet.create(1, 2, 3), readEval("#{1,2,3}")));

		trace("============================== CompilerTests ==========================");
		// var set1:PersistentHashSet = PersistentHashSet.create(1, 2, 3);
		// var set2:PersistentHashSet = PersistentHashSet.create(1, 2, 3);
		// trace(">>>>>>>> SET: " + set1 + " " + set2 + "  " + Util.equals(set1, set2));
		// var readedSet:Any = readEval("#{1,2,3}");
		// trace("ReaderSet: " + readedSet);

		// var s:String = "(do 1 2 {:a 1 :b 2 :c [1 2 3]})";
		// trace(readEval(s));
		// var k:Any = true;
		//  var k1:Any = 1;
		//  var k2:Any = 2;
		//  trace("Equality:", (k1 == true), (true == k1), (k2 == true), (true == k2));
		//  trace("Equality bool", Type.typeof(1), Type.typeof(2), Type.typeof(true), Type.typeof(false));

		// trace(U.getClassName(readEval(":keyword")));
	}
}
