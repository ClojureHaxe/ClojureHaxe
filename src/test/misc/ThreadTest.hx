package test.misc;

import lang.misc.Thread;
import utest.Test;
import utest.Assert;

class ThreadTest extends Test {
	function test() {
		Assert.isTrue(Thread.equals(Thread.currentThread(), Thread.currentThread()));
	}
}
