package test;

import lang.PersistentList;
import lang.Keyword;
import utest.Test;
import utest.Assert;

class PersistentListTest extends Test {
	function test() {
		var k1:Keyword = Keyword.create("user", "age");
		var k2:Keyword = Keyword.createNSname("key");

		var p:PersistentList = new PersistentList("Hello");

		p = p.cons("1");
		p = p.cons(k1);
		p = p.cons(k2);
		Assert.equals('(:key :user/age "1" "Hello")', p.toString());
	}
}
