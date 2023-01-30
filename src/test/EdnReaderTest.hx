package test;

import lang.IPersistentMap;
import lang.PersistentVector;
import lang.U;
import lang.Keyword;
import lang.Symbol;
import lang.PersistentArrayMap;
import lang.PersistentList;
import lang.PersistentHashSet;
import lang.EdnReader;
import lang.Util;
import lang.AFn;
import utest.Assert;

class EdnReaderTest extends utest.Test {
	function parse(s:String):Any {
		var opts:PersistentArrayMap = PersistentArrayMap.EMPTY;
		return EdnReader.readString(s, opts);
	}

	function testEdnReader() {
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

		// keyword
		var res = parse(":keyword");
		Assert.isTrue(Keyword.createNSname("keyword").equals(res));
		res = parse(":a/b");
		Assert.isTrue(Keyword.createNSname("a/b").equals(res));

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
			Assert.isTrue(U.instanceof(e, ReaderException));
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
	}

	function testEdnReaderTag() {
		var readersMap:PersistentArrayMap = PersistentArrayMap.create(Symbol.createNSname("my"), new IncFunc());
		var opts:PersistentArrayMap = PersistentArrayMap.create(Keyword.createNSname("readers"), readersMap);
		var res = EdnReader.readString(" #my 5 ", opts);
		Assert.equals(6, cast res);
	}
}

class IncFunc extends AFn {
	public function new() {}

	override public function invoke1(v:Any):Any {
		return 1 + (cast v);
	}
}
