package test;

import lang.*;
import lang.Keyword;
import utest.Test;
import utest.Assert;

class PersistentVectorTest extends Test {
	function test() {
		var pl = new PersistentList("Hello");
		var pp1:PersistentVector = PersistentVector.createFromISeq(pl);
		Assert.isTrue(U.instanceof(pp1, IPersistentVector));
		Assert.equals('["Hello"]', pp1.toString());
		Assert.isFalse(pp1.equiv(10));
		Assert.isTrue(pp1.equiv(pl));
        Assert.isTrue(U.instanceof(pp1, IPersistentVector));

		var pp3:PersistentVector = PersistentVector.createFromItems(1, 2, 3);
		pp3 = pp3.cons(pp3);
		Assert.equals(4, pp3.count());
		Assert.equals('[1 2 3 [1 2 3]]', pp3.toString());
	}
}
