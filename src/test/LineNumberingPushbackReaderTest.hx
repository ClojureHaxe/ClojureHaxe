package test;

import lang.LineNumberingPushbackReader;
import utest.Test;
import utest.Assert;

class LineNumberingPushbackReaderTest extends Test {
	function test() {
		var s:String = "Hi\nall";
		var r:LineNumberingPushbackReader = new LineNumberingPushbackReader(s);

		Assert.equals(1, r.getLineNumber());
		Assert.equals(1, r.getColumnNumber());
		Assert.equals("H".code, r.read());

		Assert.equals(1, r.getLineNumber());
		Assert.equals(2, r.getColumnNumber());
		Assert.equals("i".code, r.read());

		Assert.equals(1, r.getLineNumber());
		Assert.equals(3, r.getColumnNumber());
		Assert.equals("\n".code, r.read());

		Assert.equals(2, r.getLineNumber());
		Assert.equals(1, r.getColumnNumber());
		Assert.equals("a".code, r.read());

		Assert.equals(2, r.getLineNumber());
		Assert.equals(2, r.getColumnNumber());
		Assert.equals("l".code, r.read());

		Assert.equals(2, r.getLineNumber());
		Assert.equals(3, r.getColumnNumber());
		Assert.equals("l".code, r.read());

		Assert.equals(-1, r.read());
	}
}
