package test;

import lang.Numbers;
import utest.Test;
import utest.Assert;

class NumbersTest extends Test {
	function test() {
		Assert.isFalse(Numbers.equiv(10, null));
	}
}
