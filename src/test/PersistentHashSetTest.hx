package test;

import lang.Util;
import lang.PersistentHashSet;
import lang.Keyword;
import utest.Test;
import utest.Assert;

class PersistentHashSetTest extends Test {
	function test() {
		var hs:PersistentHashSet = PersistentHashSet.create("a", "b", "c", "d", "e", 10, null, true, false);
		Assert.equals(9, hs.count());
		/// contains
		Assert.isTrue(hs.contains("a"));
		Assert.isTrue(hs.contains("b"));
		Assert.isTrue(hs.contains("c"));
		Assert.isTrue(hs.contains("d"));
		Assert.isTrue(hs.contains("e"));
		Assert.isTrue(hs.contains(10));
		Assert.isTrue(hs.contains(null));
		Assert.isTrue(hs.contains(true));
		Assert.isTrue(hs.contains(false));
		// get
		Assert.equals("a", hs.get("a"));
		Assert.equals("b", hs.get("b"));
		Assert.equals("c", hs.get("c"));
		Assert.equals("d", hs.get("d"));
		Assert.equals("e", hs.get("e"));
		Assert.equals(10, hs.get(10));
		Assert.equals(null, hs.get(null));
		Assert.equals(true, hs.get(true));
		Assert.equals(false, hs.get(false));
		Assert.isTrue(Util.equiv(PersistentHashSet.create(null, "a", true, "b", "c", "d", "e", false, 10), hs));

		// equality
		var set1:PersistentHashSet = PersistentHashSet.create(1, 2, 3);
		var set2:PersistentHashSet = PersistentHashSet.create(1, 2, 3);
		Assert.isTrue(set1.equals(set2));
	}
}
