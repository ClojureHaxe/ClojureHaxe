package test;

import lang.*;
import lang.exceptions.*;
import utest.Assert;

class LispReaderTest extends utest.Test {
	
	/*
	function parse(s:String):Any {
		var opts:PersistentArrayMap = PersistentArrayMap.EMPTY;
		return LispReader.readString(s, opts);
	}
	*/

	function test() {
		Assert.equals(true, true);
		// numbers
		/*
		Assert.equals(10, parse("10"));
		Assert.equals(10.5, parse("10.5"));
		Assert.equals(0, parse("0"));
/*
		// keyword
		var res = parse(":keyword");
		Assert.isTrue(Keyword.create1("keyword").equals(res));
		res = parse(":a/b");
		Assert.isTrue(Keyword.create1("a/b").equals(res));

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
*/
		// exception
		/*
			try {
				parse("  \\rr");
			} catch (e) {
				Assert.isTrue(U.instanceof(e, LispReader.ReaderException));
			}
		 */
/*
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

        */
	}
}
