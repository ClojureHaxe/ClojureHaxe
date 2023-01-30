package test;

import Map.IMap;
import lang.IMapEntry;
import lang.PersistentArrayMap;
import utest.Test;
import utest.Assert;

class PersistentArrayMapTest extends Test {
	function test() {
		var m:PersistentArrayMap = PersistentArrayMap.create("a", "b", "c", "d", "e", 10, true, false);
		Assert.equals(4, m.count());
		Assert.equals('{"a" "b", "c" "d", "e" 10, true false}', m.toString());
		var me:IMapEntry = m.entryAt("a");
		Assert.equals("a", me.key());
		Assert.equals("b", me.val());
	}
}
