package test;

import lang.PersistentArrayMap;
import utest.Test;
import utest.Assert;

class PersistentArrayMapTest extends Test {
	function test() {
		var m:PersistentArrayMap = PersistentArrayMap.create("a", "b", "c", "d", "e", 10, true, false);
		Assert.equals(4, m.count());
		Assert.equals('{"a" "b", "c" "d", "e" 10, true false}', m.toString());
	}
}
