package test;

import haxe.Rest;
import lang.ArraySeq;
import utest.Test;
import utest.Assert;

class ArraySeqTest extends Test {
	function testCreation() {
		var a1:ArraySeq = ArraySeq.create(1, 2, 3, 4);
		Assert.equals(4, a1.count());

		var res = [1, 2, 3, 4];
		var i:Int = 0;
		while (i < 4) {
			Assert.equals(res[i], a1.first());
			a1 = cast a1.next();
			i++;
		}
	}

	function testPrint() {
		var a1:ArraySeq = ArraySeq.create(10, 20, 30);
		var a2:ArraySeq = ArraySeq.create(1, "Hello", true, null, a1);
		Assert.equals('(1 "Hello" true nil (10 20 30))', a2.toString());

		// TODO: previous test doesn't work in Lua because of bug:
		// https://github.com/HaxeFoundation/haxe/issues/10909
		var arr:Array<Any> = [1, 2, 3, null, 5];
		var r:Rest<Any> = Rest.of(arr);
		trace("https://github.com/HaxeFoundation/haxe/issues/10909", arr, r); // [1,2,3,null,5], [1,2,3,null,null]
	}
}
