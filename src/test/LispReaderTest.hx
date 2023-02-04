package test;

import lang.*;
import lang.exceptions.*;
import utest.Assert;

class LispReaderTest extends utest.Test {
	function parse(s:String):Any {
		var opts:PersistentArrayMap = PersistentArrayMap.EMPTY;
		return LispReader.readString(s, opts);
	}

	function test() {
		// nil
		Assert.equals(null, parse("nil"));

		// bool
		Assert.equals(true, parse("true"));
		Assert.equals(false, parse("false"));

		// numbers
		Assert.equals(10, parse("10"));
		Assert.equals(10.5, parse("10.5"));
		Assert.equals(0, parse("0"));
		Assert.equals(1, parse("1"));
		Assert.equals(2, parse("2"));

		// ratio
		Assert.equals(0.5, parse("1/2"));
		Assert.equals(1, parse("2/2"));

		// string
		var s:String = cast parse(' "hel\\nlo" ');
		Assert.equals(6, s.length);
		Assert.equals("hel\nlo", s);
		Assert.equals('"', parse('"\\""'));

		// comment
		Assert.equals(1, parse(";;comment\n1"));

		// character
		Assert.equals("a", parse(" \\a "));
		Assert.equals("\n", parse(" \\newline "));
		Assert.equals(" ", parse(" \\space "));
		Assert.equals("\t", parse(" \\tab "));
		Assert.equals("\r", parse(" \\return "));

		Assert.equals("$", parse(" \\u0024  "));
		Assert.equals("Ω", parse(" \\u03A9  "));
		Assert.equals("\n", parse(" \\o12  "));

		// exception
		try {
			parse("  \\rr");
		} catch (e) {
			Assert.isTrue(U.instanceof(e, LispReader.ReaderExceptionLR));
		}

		// list
		Assert.equals("(1 2 3)", cast(parse(" (1 2 3) "), PersistentList).toString());

		// vector
		Assert.equals("[1 2 3]", cast(parse(" [1 2 3] "), PersistentVector).toString());

		// map
		Assert.equals("{:a 1, :b 2}", cast(parse(" {:a 1 :b 2} "), PersistentArrayMap).toString());

		// set
		Assert.isTrue(Util.equiv(PersistentHashSet.create(1, 2, 3), parse(" #{ 1  2 3} ")));

		// Symbolic
		// TODO: printString for them
		Assert.equals(Math.POSITIVE_INFINITY, parse(" ##Inf "));
		Assert.equals(Math.NEGATIVE_INFINITY, parse(" ##-Inf "));
		Assert.isTrue(Math.isNaN(parse(" ##NaN ")));

		// Discard
		Assert.equals(4, parse(" #_[1 2 3] 4"));

		// Meta
		Assert.equals(4, parse(" #_[1 2 3] 4"));

		// Meta
		var p:PersistentVector = cast parse(" ^:const [1]");
		var m:IPersistentMap = p.meta();
		var k = Keyword.createNSname("const");
		Assert.equals(true, m.valAt(k));

		// TODO: doesn't work in Java because of https://github.com/HaxeFoundation/haxe/issues/10906
		p = cast parse(" #^{1 2} [1]");
		m = p.meta();
		Assert.equals(1, p.count());
		Assert.isTrue(Util.pcequiv(PersistentVector.createFromItems(1), p));
		Assert.equals(2, m.valAt(1));

		// FnReader
		// trace(parse("(fn [a] (inc a))"));
		var ret:ISeq = parse("#(inc %)"); // (fn* [p1__2#] (inc p1__2#))
		Assert.equals(ret.first(), Compiler.FN);
		Assert.isTrue(U.instanceof(RT.second(ret), PersistentVector));
		Assert.isTrue(Symbol.intern1("inc").equals(RT.first(RT.third(ret))));

		// parse fn second time
		ret = parse("#(inc %)");
		Assert.equals(ret.first(), Compiler.FN);
		Assert.isTrue(U.instanceof(RT.second(ret), PersistentVector));
		Assert.isTrue(Symbol.intern1("inc").equals(RT.first(RT.third(ret))));

		// test wrong rest &% instead of %&
		var ret:ISeq = parse(" #(inc % % &%)"); // (fn* [p1__1#] (inc p1__1# p1__1# &%))
		Assert.equals(ret.first(), Compiler.FN);
		Assert.isTrue(Symbol.intern1("&%").equals(RT.fourth(RT.third(ret))));

		// test rest
		ret = parse(" #(inc % % %&)"); // (fn* [p1__2# & rest__3#] (inc p1__2# p1__2# rest__3#))
		Assert.equals(3, RT.count(RT.second(ret)));
		Assert.isTrue(Symbol.intern1("&").equals(RT.second(RT.second(ret))));
		Assert.equals(4, RT.count(RT.third(ret)));
	}
}
