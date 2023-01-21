package lang;

import haxe.Rest;
import haxe.Exception;
import lang.exceptions.RuntimeException;
import lang.exceptions.NumberFormatException;
import lang.exceptions.IllegalArgumentException;
import haxe.ds.Vector;

class EdnReader {
	static final macros:Vector<IFn> = {
		var m = new Vector<IFn>(256);
		m['"'.code] = new StringReader();
		m[';'.code] = new CommentReader();
		m['^'.code] = new MetaReader();
		m['('.code] = new ListReader();
		m[')'.code] = new UnmatchedDelimiterReader();
		m['['.code] = new VectorReader();
		m[']'.code] = new UnmatchedDelimiterReader();
		m['{'.code] = new MapReader();
		m['}'.code] = new UnmatchedDelimiterReader();
		m['\\'.code] = new CharacterReader();
		m['#'.code] = new DispatchReader();
		m;
	}

	static public final dispatchMacros:Vector<IFn> = {
		var dispatch:Vector<IFn> = new Vector<IFn>(256);
		dispatch['#'.code] = new SymbolicValueReader();
		dispatch['^'.code] = new MetaReader();
		// dispatchMacros['"'.code] = new RegexReader();
		dispatch['{'.code] = new SetReader();
		dispatch['<'.code] = new UnreadableReader();
		dispatch['_'.code] = new DiscardReader();
		dispatch[':'.code] = new NamespaceMapReader();
		dispatch;
	}

	// static final symbolPat:EReg = new EReg("[:]?([\\D&&[^/]].*/)?(/|[\\D&&[^/]][^/]*)", "");
	static final symbolPat:EReg = new EReg("^[:]?([^0-9/].*/)?(/|[^0-9/][^/]*)$", "");
	static final intPat:EReg = new EReg("^([-+]?)(?:(0)|([1-9][0-9]*)|0[xX]([0-9A-Fa-f]+)|0([0-7]+)|([1-9][0-9]?)[rR]([0-9A-Za-z]+)|0[0-9]+)(N)?$", "");
	static final ratioPat:EReg = new EReg("^([-+]?[0-9]+)/([0-9]+)$", "");
	static final floatPat:EReg = new EReg("^([-+]?[0-9]+(\\.[0-9]*)?([eE][-+]?[0-9]+)?)(M)?$", "");

	static public final taggedReader:IFn = new TaggedReader();

	static function nonConstituent(ch:Int):Bool {
		return ch == '@'.code || ch == '`'.code || ch == '~'.code;
	}

	static public function readString(s:String, opts:IPersistentMap):Any {
		var r:LineNumberingPushbackReader = new LineNumberingPushbackReader(s);
		return read2(r, opts);
	}

	static public function isWhitespace(ch:Int):Bool {
		return Character.isWhitespace(ch) || ch == ','.code;
	}

	static public function unread(r:LineNumberingPushbackReader, ch:Int) {
		if (ch != -1)
			try {
				r.unread();
			} catch (e) {
				throw Util.runtimeException("ERROR EdnReader unread", e);
				// throw Util.sneakyThrow(e);
			}
	}

	static public function read1(r:LineNumberingPushbackReader):Int {
		return r.read();
	}

	static final EOF:Keyword = Keyword.intern(null, "eof");

	static public function read2(r:LineNumberingPushbackReader, opts:IPersistentMap):Any {
		return read5(r, !opts.containsKey(EOF), opts.valAt(EOF), false, opts);
	}

	static public function read5(r:LineNumberingPushbackReader, eofIsError:Bool, eofValue:Any, isRecursive:Bool, opts:Any):Any {
		try {
			while (true) {
				var ch:Int = read1(r);
				// trace("ch1: ", ch, String.fromCharCode(ch));
				while (isWhitespace(ch))
					ch = read1(r);

				if (ch == -1) {
					if (eofIsError)
						throw Util.runtimeException("EOF while reading");
					return eofValue;
				}

				if (Character.isDigit(ch)) {
					var n:Any = readNumber(r, ch);
					if (RT.suppressRead())
						return null;
					return n;
				}
				var macroFn:IFn = getMacro(ch);

				if (macroFn != null) {
					var ret:Any = macroFn.invoke3(r, ch, opts);
					if (RT.suppressRead())
						return null;
					// no op macros return the reader
					// Java requires additional check
					if (r == ret)
						continue;

					return ret;
				}

				if (ch == '+'.code || ch == '-'.code) {
					var ch2:Int = read1(r);
					if (Character.isDigit(ch2)) {
						unread(r, ch2);
						var n:Any = readNumber(r, ch);
						if (RT.suppressRead())
							return null;
						return n;
					}
					unread(r, ch2);
				}

				var token:String = readToken(r, ch, true);
				if (RT.suppressRead())
					return null;
				return interpretToken(token);
			}
		} catch (e) {
			throw new ReaderException(r.getLineNumber(), r.getColumnNumber(), e);
		}
	}

	static public function readToken(r:LineNumberingPushbackReader, initch:Int, leadConstituent:Bool):String {
		var sb:StringBuf = new StringBuf();
		if (leadConstituent && nonConstituent(initch))
			throw Util.runtimeException("Invalid leading character: " + initch);

		sb.add(String.fromCharCode(initch));

		while (true) {
			var ch:Int = read1(r);
			if (ch == -1 || isWhitespace(ch) || isTerminatingMacro(ch)) {
				unread(r, ch);
				return sb.toString();
			} else if (nonConstituent(ch))
				throw Util.runtimeException("Invalid constituent character: " + ch);
			sb.add(String.fromCharCode(ch));
		}
	}

	static private function readNumber(r:LineNumberingPushbackReader, initch:Int):Any {
		var sb:StringBuf = new StringBuf();
		sb.add(String.fromCharCode(initch));

		while (true) {
			var ch:Int = read1(r);
			if (ch == -1 || isWhitespace(ch) || isMacro(ch)) {
				unread(r, ch);
				break;
			}
			sb.add(String.fromCharCode(ch));
		}

		var s:String = sb.toString();
		var n:Any = matchNumber(s);
		if (n == null)
			throw new NumberFormatException("Invalid number: " + s);
		return n;
	}

	static public function readUnicodeChar4(token:String, offset:Int, length:Int, base:Int):Int {
		if (token.length != offset + length)
			throw new IllegalArgumentException("Invalid unicode character: \\" + token);
		var uc:Int = 0;
		var i:Int = offset;
		while (i < offset + length) {
			var d:Int = U.parseInt(token.charAt(i), base); //  Character.digit(token.charCodeAt(i), base);
			if (d == -1)
				throw new IllegalArgumentException("Invalid digit: " + token.charAt(i));
			uc = uc * base + d;
			++i;
		}
		return uc;
	}

	static public function readUnicodeChar5(r:LineNumberingPushbackReader, initch:Int, base:Int, length:Int, exact:Bool):Int {
		var uc:Int = Character.digit(initch, base);
		if (uc == -1)
			throw new IllegalArgumentException("Invalid digit: " + String.fromCharCode(initch));
		var i:Int = 1;
		while (i < length) {
			var ch:Int = read1(r);
			if (ch == -1 || isWhitespace(ch) || isMacro(ch)) {
				unread(r, ch);
				break;
			}
			var d:Int = Character.digit(ch, base);
			if (d == -1)
				throw new IllegalArgumentException("Invalid digit: " + String.fromCharCode(ch));
			uc = uc * base + d;
			++i;
		}
		if (i != length && exact)
			throw new IllegalArgumentException("Invalid character length: " + i + ", should be: " + length);
		return uc;
	}

	static private function interpretToken(s:String):Any {
		if (s == "nil") {
			return null;
		} else if (s == "true") {
			return RT.T;
		} else if (s == "false") {
			return RT.F;
		}

		var ret:Any = null;

		ret = matchSymbol(s);
		if (ret != null)
			return ret;

		throw Util.runtimeException("Invalid token: " + s);
	}

	private static function matchSymbol(s:String):Any {
		if (symbolPat.match(s)) {
			var ns:String = symbolPat.matched(1);
			var name:String = symbolPat.matched(2);
			if (ns != null && StringTools.endsWith(ns, ":/") || StringTools.endsWith(name, ":") || s.indexOf("::", 1) != -1)
				return null;
			if (StringTools.startsWith(s, "::")) {
				return null;
			}
			var isKeyword:Bool = s.charAt(0) == ':';
			var sym:Symbol = Symbol.internNSname(s.substring(isKeyword ? 1 : 0));
			if (isKeyword)
				return Keyword.internSymbol(sym);
			return sym;
		}
		return null;
	}

	private static function matchNumber(s:String):Any {
		if (intPat.match(s)) {
			if (intPat.matched(2) != null) {
				if (intPat.matched(8) != null)
					return throw new NumberFormatException("BigInt is not supported");
				// return BigInt.ZERO;
				return 0; // Numbers.num(0);
			}
			var negate:Bool = (intPat.matched(1) == "-");
			var n:String;
			var radix:Int = 10;
			if ((n = intPat.matched(3)) != null)
				radix = 10;
			else if ((n = intPat.matched(4)) != null)
				radix = 16;
			else if ((n = intPat.matched(5)) != null)
				radix = 8;
			else if ((n = intPat.matched(7)) != null)
				radix = Std.parseInt(intPat.matched(6));
			if (n == null)
				return null;
			// BigInteger bn = new BigInteger(n, radix);
			var bn:Int = U.parseInt(n, radix);
			if (negate)
				// bn = bn.negate();
				bn = -bn;
			if (intPat.matched(8) != null)
				// return BigInt.fromBigInteger(bn);
				throw new NumberFormatException("BigInteger is not supported");
			return bn;
			// return bn.bitLength() < 64 ? Numbers.num(bn.longValue()) : BigInt.fromBigInteger(bn);
		}
		var m:EReg = floatPat;
		if (m.match(s)) {
			if (m.matched(4) != null)
				throw new NumberFormatException("BigDecimal is not supported");
			// return new BigDecimal(m.group(1));
			return Std.parseFloat(s);
		}
		m = ratioPat;
		if (m.match(s)) {
			var numerator:String = m.matched(1);
			if (StringTools.startsWith(numerator, "+"))
				numerator = numerator.substring(1);
			return Ratio.toNumber(Std.parseInt(numerator), Std.parseInt(m.matched(2)));

			/*return Numbers.divide(
				Numbers.reduceBigInt(BigInt.fromBigInteger(new BigInteger(numerator))),
				Numbers.reduceBigInt(BigInt.fromBigInteger(new BigInteger(m.group(2))))); */
		}
		return null;
	}

	static private function getMacro(ch:Int):IFn {
		if (ch < macros.length)
			return macros[ch];
		return null;
	}

	static private function isMacro(ch:Int):Bool {
		return (ch < macros.length && macros[ch] != null);
	}

	static private function isTerminatingMacro(ch:Int):Bool {
		return (ch != '#'.code && ch != "'".code && isMacro(ch));
	}

	public static function readDelimitedList(delim:Int, r:LineNumberingPushbackReader, isRecursive:Bool, opts:Any):Array<Any> {
		final firstline:Int = U.instanceof(r, LineNumberingPushbackReader) ? r.getLineNumber() : -1;

		// var a:Array<Any> = new Array<Any>();
		var a:Array<Any> = new Array<Any>();

		while (true) {
			var ch:Int = read1(r);

			while (isWhitespace(ch))
				ch = read1(r);

			if (ch == -1) {
				if (firstline < 0)
					throw Util.runtimeException("EOF while reading");
				else
					throw Util.runtimeException("EOF while reading, starting at line " + firstline);
			}

			if (ch == delim)
				break;

			var macroFn:IFn = getMacro(ch);
			if (macroFn != null) {
				var mret:Any = macroFn.invoke3(r, ch, opts);
				// no op macros return the reader
				if (r != mret)
					a.push(mret);
			} else {
				unread(r, ch);

				var o:Any = read5(r, true, null, isRecursive, opts);
				// trace("LIst read: ", o, U.typeName(o));
				if (r != o)
					a.push(o);
			}
		}

		return a;
	}
}

class ReaderException extends RuntimeException {
	var lin:Int;
	var column:Int;

	public function new(line:Int, column:Int, cause:Exception) {
		super("EDN reading error in line: " + line + ", column: " + column + " " + cause, cause);
		this.lin = line;
		this.column = column;
	}
}

class StringReader extends AFn {
	public function new() {}

	override public function invoke3(reader:Any, doublequote:Any, opts:Any):Any {
		var r:LineNumberingPushbackReader = cast reader;
		var sb:StringBuf = new StringBuf();
		var ch:Int = EdnReader.read1(r);
		while (ch != '"'.code) {
			if (ch == -1)
				throw Util.runtimeException("EOF while reading string");
			if (ch == '\\'.code) // escape
			{
				ch = EdnReader.read1(r);
				if (ch == -1)
					throw Util.runtimeException("EOF while reading string");
				switch (ch) {
					case 't'.code:
						ch = '\t'.code;
					case 'r'.code:
						ch = '\r'.code;
					case 'n'.code:
						ch = '\n'.code;
					case '\\'.code:
					case '"'.code:
					// case 'b':
					// 		ch = '\b';
					// case 'f':
					// 		ch = '\f';
					case 'u'.code:
						{
							ch = EdnReader.read1(r);
							if (Character.digit(ch, 16) == -1)
								throw Util.runtimeException("Invalid unicode escape: \\u" + String.fromCharCode(ch));
							ch = EdnReader.readUnicodeChar5(r, ch, 16, 4, true);
						}
					default:
						{
							if (Character.isDigit(ch)) {
								ch = EdnReader.readUnicodeChar5(r, ch, 8, 3, false);
								if (ch > 255) // 0377 (octal)
									throw Util.runtimeException("Octal escape sequence must be in range [0, 377].");
							} else
								throw Util.runtimeException("Unsupported escape character: \\" + String.fromCharCode(ch));
						}
				}
			}
			sb.add(String.fromCharCode(ch));
			ch = EdnReader.read1(r);
		}
		return sb.toString();
	}
}

class CommentReader extends AFn {
	public function new() {}

	override public function invoke3(reader:Any, semicolon:Any, opts:Any):Any {
		var r:LineNumberingPushbackReader = cast reader;
		var ch:Int;
		do {
			ch = EdnReader.read1(r);
		} while (ch != -1 && ch != '\n'.code && ch != '\r'.code);
		return r;
	}
}

class DiscardReader extends AFn {
	public function new() {}

	override public function invoke3(reader:Any, underscore:Any, opts:Any):Any {
		final r:LineNumberingPushbackReader = reader;
		EdnReader.read5(r, true, null, true, opts);
		return r;
	}
}

class NamespaceMapReader extends AFn {
	public function new() {}

	override public function invoke3(reader:Any, colon:Any, opts:Any):Any {
		final r:LineNumberingPushbackReader = reader;

		// Read ns symbol
		var sym:Any = EdnReader.read5(r, true, null, false, opts);
		if (!(U.instanceof(sym, Symbol)) || cast(sym, Symbol).getNamespace() != null)
			throw new RuntimeException("Namespaced map must specify a valid namespace: " + sym);
		var ns:String = cast(sym, Symbol).getName();

		// Read map
		var nextChar:Int = EdnReader.read1(r);
		while (EdnReader.isWhitespace(nextChar))
			nextChar = EdnReader.read1(r);
		if ('{'.code != nextChar)
			throw new RuntimeException("Namespaced map must specify a map");
		var kvs:Array<Any> = EdnReader.readDelimitedList('}'.code, r, true, opts);
		if ((kvs.length & 1) == 1)
			throw Util.runtimeException("Namespaced map literal must contain an even number of forms");

		// Construct output map
		// var a:Vector<Any> = new Vector<Any>(kvs.length);
		var a:Array<Any> = new Array<Any>();
		var iter:Iterator<Any> = kvs.iterator();
		var i:Int = 0;
		while (iter.hasNext()) {
			var key:Any = iter.next();
			var val:Any = iter.next();

			if (U.instanceof(key, Keyword)) {
				var kw:Keyword = key;
				if (kw.getNamespace() == null) {
					key = Keyword.intern(ns, kw.getName());
				} else if (kw.getNamespace() == "_") {
					key = Keyword.intern(null, kw.getName());
				}
			} else if (U.instanceof(key, Symbol)) {
				var s:Symbol = cast key;
				if (s.getNamespace() == null) {
					key = Symbol.intern(ns, s.getName());
				} else if (s.getNamespace() == "_") {
					key = Symbol.intern(null, s.getName());
				}
			}
			a[i] = key;
			a[i + 1] = val;
			i += 2;
		}
		/// TODO: change RT.map
		var r:Rest<Any> = Rest.of(a);
		return RT.map(...r);
	}
}

class DispatchReader extends AFn {
	public function new() {}

	override public function invoke3(reader:Any, hash:Any, opts:Any):Any {
		var ch:Int = EdnReader.read1(reader);
		if (ch == -1)
			throw Util.runtimeException("EOF while reading character");
		var fn:IFn = EdnReader.dispatchMacros[ch];

		if (fn == null) {
			// try tagged reader
			if (Character.isLetter(ch)) {
				EdnReader.unread(cast reader, ch);
				return EdnReader.taggedReader.invoke3(reader, ch, opts);
			}

			throw Util.runtimeException("No dispatch macro for: " + String.fromCharCode(ch));
		}
		return fn.invoke3(reader, ch, opts);
	}
}

class MetaReader extends AFn {
	public function new() {}

	override public function invoke3(reader:Any, caret:Any, opts:Any):Any {
		var r:LineNumberingPushbackReader = cast reader;
		var line:Int = -1;
		var column:Int = -1;
		if (U.instanceof(r, LineNumberingPushbackReader)) {
			line = r.getLineNumber();
			column = r.getColumnNumber() - 1;
		}

		var meta:Any = EdnReader.read5(r, true, null, true, opts);
		if (U.instanceof(meta, Symbol) || U.instanceof(meta, String))
			meta = RT.map(RT.TAG_KEY, meta);
		else if (U.instanceof(meta, Keyword))
			meta = RT.map(meta, RT.T);
		else if (!(U.instanceof(meta, IPersistentMap)))
			throw new IllegalArgumentException("Metadata must be Symbol,Keyword,String or Map");

		var o:Any = EdnReader.read5(r, true, null, true, opts);
		if (U.instanceof(o, IMeta)) {
			if (line != -1 && U.instanceof(o, ISeq)) {
				meta = cast(meta, IPersistentMap).assoc(RT.LINE_KEY, line).assoc(RT.COLUMN_KEY, column);
			}
			if (U.instanceof(o, IReference)) {
				cast(o, IReference).resetMeta(meta);
				return o;
			}
			var ometa:Any = RT.meta(o);
			var s:ISeq = RT.seq(meta);
			while (s != null) {
				var kv:IMapEntry = cast s.first();
				ometa = RT.assoc(ometa, kv.getKey(), kv.getValue());
				s = s.next();
			}
			return cast(o, IObj).withMeta(ometa);
		} else
			throw new IllegalArgumentException("Metadata can only be applied to IMetas");
	}
}

class CharacterReader extends AFn {
	public function new() {}

	override public function invoke3(reader:Any, backslash:Any, opts:Any):Any {
		var r:LineNumberingPushbackReader = reader;
		var ch:Int = EdnReader.read1(r);
		if (ch == -1)
			throw Util.runtimeException("EOF while reading character");
		var token:String = EdnReader.readToken(r, ch, false);
		if (token.length == 1)
			// Character.valueOf(token.charAt(0));
			return token;
		else if (token == "newline")
			return '\n';
		else if (token == "space")
			return ' ';
		else if (token == "tab")
			return '\t';
		/*else if (token.equals("backspace"))
				return '\b';
			else if (token.equals("formfeed"))
				return '\f'; */
		else if (token == "return")
			return '\r';
		else if (StringTools.startsWith(token, "u")) {
			var c:Int = EdnReader.readUnicodeChar4(token, 1, 4, 16);
			if (c >= 55295 && c <= 57343)
				// if (c >= '\uD800' && c <= '\uDFFF') // surrogate code unit?
				throw Util.runtimeException("Invalid character constant: \\u" + StringTools.hex(c));
			return String.fromCharCode(c);
		} else if (StringTools.startsWith(token, "o")) {
			var len:Int = token.length - 1;
			if (len > 3)
				throw Util.runtimeException("Invalid octal escape sequence length: " + len);
			var uc:Int = EdnReader.readUnicodeChar4(token, 1, len, 8);
			if (uc > 255) // octal 0377
				throw Util.runtimeException("Octal escape sequence must be in range [0, 377].");
			return String.fromCharCode(uc);
		}
		throw Util.runtimeException("Unsupported character: \\" + token);
	}
}

class ListReader extends AFn {
	public function new() {}

	override public function invoke3(reader:Any, leftparen:Any, opts:Any):Any {
		var r:LineNumberingPushbackReader = cast reader;
		var line:Int = -1;
		var column:Int = -1;
		if (U.instanceof(r, LineNumberingPushbackReader)) {
			line = r.getLineNumber();
			column = r.getColumnNumber() - 1;
		}
		var list = EdnReader.readDelimitedList(')'.code, r, true, opts);
		if (list.length == 0)
			return PersistentList.EMPTY;
		var s:IObj = cast PersistentList.createFromArray(list);
		//		IObj s = (IObj) RT.seq(list);
		//		if(line != -1)
		//			{
		//			return s.withMeta(RT.map(RT.LINE_KEY, line, RT.COLUMN_KEY, column));
		//			}
		//		else
		return s;
	}
}

class VectorReader extends AFn {
	public function new() {}

	override public function invoke3(reader:Any, leftparen:Any, opts:Any):Any {
		var r:LineNumberingPushbackReader = cast reader;
		return LazilyPersistentVector.create(EdnReader.readDelimitedList(']'.code, r, true, opts));
	}
}

class MapReader extends AFn {
	public function new() {}

	override public function invoke3(reader:Any, rightdelim:Any, opts:Any):Any {
		var r:LineNumberingPushbackReader = cast reader;
		var a:Array<Any> = EdnReader.readDelimitedList('}'.code, r, true, opts);
		if ((a.length & 1) == 1)
			throw Util.runtimeException("Map literal must contain an even number of forms");
		// TODO: Rest on jvm
		return RT.map(...a);
		// var m:Any = RT.mapFromArray(a);
		// return RT.mapFromArray(a);
	}
}

class SetReader extends AFn {
	public function new() {}

	override public function invoke3(reader:Any, rightdelim:Any, opts:Any):Any {
		var r:LineNumberingPushbackReader = cast reader;
		var ar:Array<Any> = EdnReader.readDelimitedList('}'.code, r, true, opts);
		// var rs:Rest<Any> = Rest.of(ar);
		// trace(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>  z ", ar, ar.length, rs, rs.length );
		// Buf with jvm/java https://github.com/HaxeFoundation/haxe/issues/10906
		/*
			#if jvm
			return PersistentHashSet.createWithCheckFromISeq(ArraySeq.createFromObject(ar));
			#else
			return PersistentHashSet.createWithCheck(...(Rest.of(ar)));
			#end
		 */
		return PersistentHashSet.createWithCheckFromIter(ar.iterator());
	}
}

class UnmatchedDelimiterReader extends AFn {
	public function new() {}

	override public function invoke3(reader:Any, rightdelim:Any, opts:Any):Any {
		throw Util.runtimeException("Unmatched delimiter: " + rightdelim);
	}
}

class UnreadableReader extends AFn {
	public function new() {}

	override public function invoke3(reader:Any, rightdelim:Any, opts:Any):Any {
		throw Util.runtimeException("Unreadable form");
	}
}

class SymbolicValueReader extends AFn {
	static var specials:IPersistentMap = PersistentHashMap.create(Symbol.internNSname("Inf"), Math.POSITIVE_INFINITY, Symbol.internNSname("-Inf"),
		Math.NEGATIVE_INFINITY, Symbol.internNSname("NaN"), Math.NaN);

	public function new() {}

	override public function invoke3(reader:Any, rightdelim:Any, opts:Any):Any {
		var r:LineNumberingPushbackReader = cast reader;
		var o:Any = EdnReader.read5(r, true, null, true, opts);
		if (!(U.instanceof(o, Symbol)))
			throw Util.runtimeException("Invalid token: ##" + o);
		if (!(specials.containsKey(o)))
			throw Util.runtimeException("Unknown symbolic value: ##" + o);
		return specials.valAt(o);
	}
}

class TaggedReader extends AFn {
	public function new() {}

	override public function invoke3(reader:Any, firstChar:Any, opts:Any):Any {
		var r:LineNumberingPushbackReader = reader;
		var name:Any = EdnReader.read5(r, true, null, false, opts);
		if (!(U.instanceof(name, Symbol)))
			throw new RuntimeException("Reader tag must be a symbol");
		var sym:Symbol = cast name;
		return readTagged(r, sym, cast opts);
	}

	static final READERS:Keyword = Keyword.intern(null, "readers");
	static final DEFAULT:Keyword = Keyword.intern(null, "default");

	private function readTagged(reader:LineNumberingPushbackReader, tag:Symbol, opts:IPersistentMap):Any {
		var o:Any = EdnReader.read5(reader, true, null, true, opts);

		var readers:ILookup = RT.get(opts, READERS);
		var dataReader:IFn = RT.get(readers, tag);
		// trace("------------------------- readTagged: ", opts, readers, dataReader);
		if (dataReader == null)
			dataReader = RT.get(RT.DEFAULT_DATA_READERS.deref(), tag);
		if (dataReader == null) {
			var defaultReader:IFn = RT.get(opts, DEFAULT);
			if (defaultReader != null)
				return defaultReader.invoke(tag, o);
			else
				throw new RuntimeException("No reader function for tag " + tag.toString());
		} else
			return dataReader.invoke1(o);
	}
}
