package test;

import lang.Keyword;
import utest.Test;
import utest.Assert;

class KeywordTest extends Test {
	function test() {
		var k = Keyword.create("user", "age");
		Assert.equals(":user/age", k.toString());

		var k1 = Keyword.createNSname("a/b");
		Assert.equals("a", k1.getNamespace());
		Assert.equals("b", k1.getName());
		Assert.equals(":a/b", k1.toString());

		var k2 = Keyword.createNSname("hello");
		Assert.equals("hello", k2.getName());
		Assert.equals(null, k2.getNamespace());
	}
}
