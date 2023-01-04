package test;

import lang.*;
import utest.Test;
import utest.Assert;

class PersistentTreeSetTest extends Test {
	function test() {
		var a:ArraySeq = ArraySeq.create(4, 1, 0, 2, 3, 5);
		var s:PersistentTreeSet = PersistentTreeSet.create(a);
		Assert.equals("#{0 1 2 3 4 5}", s.toString());
		s = cast s.disjoin(2);
		Assert.equals("#{0 1 3 4 5}", s.toString());
		s = cast s.cons(2);
		Assert.equals("#{0 1 2 3 4 5}", s.toString());
	}
}
