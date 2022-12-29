package test;

import lang.RT;
import utest.Test;
import utest.Assert;

class RTTest extends Test {
	function test() {
		Assert.equals('nil', RT.printString(null));
	}
}
