package test;

import lang.Symbol;
import utest.Test;
import utest.Assert;

class SymbolTest extends Test {
	function test() {
		var s = new Symbol("school", "user");
		Assert.equals('school/user', s.toString());

		var s2 = Symbol.internNSname("school/user");
		Assert.equals('school/user', s2.toString());
		Assert.isTrue(s.equals(s2));
	}
}
