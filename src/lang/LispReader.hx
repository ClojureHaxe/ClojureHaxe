package lang;

import lang.U.EMPTY_ARG;
import haxe.Exception;
import haxe.ds.Vector;
import haxe.Rest;
import lang.exceptions.RuntimeException;
import lang.exceptions.IllegalArgumentException;
import lang.exceptions.IllegalStateException;
import lang.exceptions.NumberFormatException;
import lang.exceptions.UnsupportedOperationException;

// import lang.lispreader.*;

class LispReader {
	static public final QUOTE:Symbol = Symbol.createNSname("quote");
	static public final THE_VAR:Symbol = Symbol.createNSname("var");
	static public final UNQUOTE:Symbol = Symbol.intern("clojure.core", "unquote");
	static public final UNQUOTE_SPLICING:Symbol = Symbol.intern("clojure.core", "unquote-splicing");
	static public final CONCAT:Symbol = Symbol.intern("clojure.core", "concat");
	static public final SEQ:Symbol = Symbol.intern("clojure.core", "seq");
	static public final LIST:Symbol = Symbol.intern("clojure.core", "list");
	static public final APPLY:Symbol = Symbol.intern("clojure.core", "apply");
	static public final HASHMAP:Symbol = Symbol.intern("clojure.core", "hash-map");
	static public final HASHSET:Symbol = Symbol.intern("clojure.core", "hash-set");
	static public final VECTOR:Symbol = Symbol.intern("clojure.core", "vector");
	static public final WITH_META:Symbol = Symbol.intern("clojure.core", "with-meta");
	static public final META:Symbol = Symbol.intern("clojure.core", "meta");
	static public final DEREF:Symbol = Symbol.intern("clojure.core", "deref");
	static public final READ_COND:Symbol = Symbol.intern("clojure.core", "read-cond");
	static public final READ_COND_SPLICING:Symbol = Symbol.intern("clojure.core", "read-cond-splicing");
	static public final UNKNOWN:Keyword = Keyword.intern(null, "unknown");

	static final macros:Vector<IFn> = {
		var m = new Vector<IFn>(256);
		m['"'.code] = new LispReader.StringReader();
		m[';'.code] = new LispReader.CommentReader();
		m['\''.code] = new LispReader.WrappingReader(QUOTE);
		m['@'.code] = new LispReader.WrappingReader(DEREF); // new DerefReader();
		m['^'.code] = new LispReader.MetaReader();
		m['`'.code] = new LispReader.SyntaxQuoteReader();
		m['~'.code] = new LispReader.UnquoteReader();
		m['('.code] = new LispReader.ListReader();
		m[')'.code] = new LispReader.UnmatchedDelimiterReader();
		m['['.code] = new LispReader.VectorReader();
		m[']'.code] = new LispReader.UnmatchedDelimiterReader();
		m['{'.code] = new LispReader.MapReader();
		m['}'.code] = new LispReader.UnmatchedDelimiterReader();
		m['\\'.code] = new LispReader.CharacterReader();
		m['%'.code] = new LispReader.ArgReader();
		m['#'.code] = new LispReader.DispatchReader();
		m;
	}

	static public final dispatchMacros:Vector<IFn> = {
		var dispatch:Vector<IFn> = new Vector<IFn>(256);
		dispatch['^'.code] = new LispReader.MetaReader();
		dispatch['#'.code] = new LispReader.SymbolicValueReader();
		dispatch['\''.code] = new LispReader.VarReader();
		dispatch['"'.code] = new LispReader.RegexReader();
		dispatch['('.code] = new LispReader.FnReader();
		dispatch['{'.code] = new LispReader.SetReader();
		dispatch['='.code] = new LispReader.EvalReader();
		dispatch['!'.code] = new LispReader.CommentReader();
		dispatch['<'.code] = new LispReader.UnreadableReader();
		dispatch['_'.code] = new LispReader.DiscardReader();
		dispatch['?'.code] = new LispReader.ConditionalReader();
		dispatch[':'.code] = new LispReader.NamespaceMapReader();
		dispatch;
	}

	static final symbolPat:EReg = new EReg("^[:]?([^0-9/].*/)?(/|[^0-9/][^/]*)$", "");
	static final intPat:EReg = new EReg("^([-+]?)(?:(0)|([1-9][0-9]*)|0[xX]([0-9A-Fa-f]+)|0([0-7]+)|([1-9][0-9]?)[rR]([0-9A-Za-z]+)|0[0-9]+)(N)?$", "");
	static final ratioPat:EReg = new EReg("^([-+]?[0-9]+)/([0-9]+)$", "");
	static final floatPat:EReg = new EReg("^([-+]?[0-9]+(\\.[0-9]*)?([eE][-+]?[0-9]+)?)(M)?$", "");

	static public final GENSYM_ENV:Var = Var.create1(null).setDynamic();
	// sorted-map num->gensymbol
	static public final ARG_ENV:Var = Var.create1(null).setDynamic();

	static public final ctorReader:IFn = new LispReader.CtorReader();
	// Dynamic var set to true in a read-cond context
	static public final READ_COND_ENV:Var = Var.create1(null).setDynamic();

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
		try {
			return r.read();
		} catch (e) {
			throw Util.sneakyThrow(e);
		}
	}

	// Reader opts
	static public final OPT_EOF:Keyword = Keyword.intern(null, "eof");
	static public final OPT_FEATURES:Keyword = Keyword.intern(null, "features");
	static public final OPT_READ_COND:Keyword = Keyword.intern(null, "read-cond");

	// EOF special value to throw on eof
	static public final EOFTHROW:Keyword = Keyword.intern(null, "eofthrow");

	// Platform features - always installed
	static private final PLATFORM_KEY:Keyword = Keyword.intern(null, "clj");
	static private final PLATFORM_FEATURES:Any = PersistentHashSet.create(PLATFORM_KEY);

	// Reader conditional options - use with :read-cond
	static public final COND_ALLOW:Keyword = Keyword.intern(null, "allow");
	static public final COND_PRESERVE:Keyword = Keyword.intern(null, "preserve");

	static public function readString(s:String, opts:IPersistentMap) {
		var r:LineNumberingPushbackReader = new LineNumberingPushbackReader(s);
		return read(r, opts);
	}

	static public function read(r:LineNumberingPushbackReader, opts:Any) {
		var eofIsError:Bool = true;
		var eofValue:Any = null;
		if (opts != null && U.instanceof(opts, IPersistentMap)) {
			var eof:Any = cast(opts, IPersistentMap).valAt(OPT_EOF, EOFTHROW);
			if (!EOFTHROW.equals(eof)) {
				eofIsError = false;
				eofValue = eof;
			}
		}
		return read5(r, eofIsError, eofValue, false, opts);
	}

	static public function read4(r:LineNumberingPushbackReader, eofIsError:Bool, eofValue:Any, isRecursive:Bool) {
		return read5(r, eofIsError, eofValue, isRecursive, PersistentHashMap.EMPTY);
	}

	static public function read5(r:LineNumberingPushbackReader, eofIsError:Bool, eofValue:Any, isRecursive:Bool, opts:Any) {
		// start with pendingForms null as reader conditional splicing is not allowed at top level
		return read9(r, eofIsError, eofValue, null, null, isRecursive, opts, null, cast(RT.READER_RESOLVER.deref(), LispReader.Resolver));
	}

	static public function read6(r:LineNumberingPushbackReader, eofIsError:Bool, eofValue:Any, isRecursive:Bool, opts:Any, pendingForms:Any) {
		return read9(r, eofIsError, eofValue, null, null, isRecursive, opts, ensurePending(pendingForms),
			cast(RT.READER_RESOLVER.deref(), LispReader.Resolver));
	}

	static public function ensurePending(pendingForms:Any):Any {
		if (pendingForms == null)
			return new Array<Any>();
		else
			return pendingForms;
	}

	static private function installPlatformFeature(opts:Any):Any {
		if (opts == null)
			return RT.mapUniqueKeys(LispReader.OPT_FEATURES, PLATFORM_FEATURES);
		else {
			var mopts:IPersistentMap = cast opts;
			var features:Any = mopts.valAt(OPT_FEATURES);
			if (features == null)
				return mopts.assoc(LispReader.OPT_FEATURES, PLATFORM_FEATURES);
			else
				return mopts.assoc(LispReader.OPT_FEATURES, RT.conj(cast(features, IPersistentSet), PLATFORM_KEY));
		}
	}

	static public function read9(r:LineNumberingPushbackReader, eofIsError:Bool, eofValue:Any, returnOn:String, returnOnValue:Any, isRecursive:Bool, opts:Any,
			pendingForms:Any, resolver:LispReader.Resolver):Any {
		if (RT.READEVAL.deref() == UNKNOWN)
			throw Util.runtimeException("Reading disallowed - *read-eval* bound to :unknown");

		opts = installPlatformFeature(opts);

		try {
			while (true) {
				if (U.instanceof(pendingForms, Array)) {
					// l.remove(0);
					return (pendingForms : Array<Any>).shift();
					/*var l:List<Any> = cast pendingForms;
						if (!l.isEmpty())
							return l.pop(); */
				}

				var ch:Int = read1(r);

				while (isWhitespace(ch))
					ch = read1(r);

				if (ch == -1) {
					if (eofIsError)
						throw Util.runtimeException("EOF while reading");
					return eofValue;
				}

				if (returnOn != null && (returnOn == String.fromCharCode(ch))) {
					return returnOnValue;
				}

				if (Character.isDigit(ch)) {
					var n:Any = readNumber(r, ch);
					return n;
				}

				var macroFn:IFn = getMacro(ch);
				if (macroFn != null) {
					var ret:Any = macroFn.invoke(r, ch, opts, pendingForms);
					// no op macros return the reader
					if (ret == r)
						continue;
					return ret;
				}

				if (ch == '+'.code || ch == '-'.code) {
					var ch2:Int = read1(r);
					if (Character.isDigit(ch2)) {
						unread(r, ch2);
						var n:Any = readNumber(r, ch);
						return n;
					}
					unread(r, ch2);
				}

				var token:String = readToken(r, ch);
				return interpretToken(token, resolver);
			}
		} catch (e) {
			if (isRecursive || !(U.instanceof(r, LineNumberingPushbackReader)))
				throw Util.sneakyThrow(e);
			var rdr:LineNumberingPushbackReader = r;
			throw new LispReader.ReaderException(rdr.getLineNumber(), rdr.getColumnNumber(), e);
		}
	}

	static public function readToken(r:LineNumberingPushbackReader, initch:Int):String {
		var sb:StringBuf = new StringBuf();
		sb.add(String.fromCharCode(initch));

		while (true) {
			var ch:Int = read1(r);
			if (ch == -1 || isWhitespace(ch) || isTerminatingMacro(ch)) {
				unread(r, ch);
				return sb.toString();
			}
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

	static public function interpretToken(s:String, resolver:LispReader.Resolver):Any {
		if (s == "nil") {
			return null;
		} else if (s == "true") {
			return RT.T;
		} else if (s == "false") {
			return RT.F;
		}

		var ret:Any = null;

		ret = matchSymbol(s, resolver);
		if (ret != null)
			return ret;

		throw Util.runtimeException("Invalid token: " + s);
	}

	private static function matchSymbol(s:String, resolver:LispReader.Resolver):Any {
		if (symbolPat.match(s)) {
			var ns:String = symbolPat.matched(1);
			var name:String = symbolPat.matched(2);
			if (ns != null && StringTools.endsWith(ns, ":/") || StringTools.endsWith(name, ":") || s.indexOf("::", 1) != -1)
				return null;
			if (StringTools.startsWith(s, "::")) {
				var ks:Symbol = Symbol.internNSname(s.substring(2));
				if (resolver != null) {
					var nsym:Symbol;
					if (ks.ns != null)
						nsym = resolver.resolveAlias(Symbol.internNSname(ks.ns));
					else
						nsym = resolver.currentNS();
					// auto-resolving keyword
					if (nsym != null)
						return Keyword.intern(nsym.name, ks.name);
					else
						return null;
				} else {
					var kns:Namespace;
					if (ks.ns != null)
						kns = Compiler.currentNS().lookupAlias(Symbol.internNSname(ks.ns));
					else
						kns = Compiler.currentNS();
					// auto-resolving keyword
					if (kns != null)
						return Keyword.intern(kns.name.name, ks.name);
					else
						return null;
				}
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

	static public function getMacro(ch:Int):IFn {
		if (ch < macros.length)
			return macros[ch];
		return null;
	}

	static private function isMacro(ch:Int):Bool {
		return (ch < macros.length && macros[ch] != null);
	}

	static public function isTerminatingMacro(ch:Int):Bool {
		return (ch != '#'.code && ch != "'".code && isMacro(ch));
	}

	static public function garg(n:Int) {
		return Symbol.intern(null, (n == -1 ? "rest" : ("p" + n)) + "__" + RT.nextID() + "#");
	}

	static public function registerArg(n:Int):Symbol {
		var argsyms:PersistentTreeMap = ARG_ENV.deref();
		if (argsyms == null) {
			throw new IllegalStateException("arg literal not in #()");
		}
		var ret:Symbol = cast argsyms.valAt(n);
		if (ret == null) {
			ret = garg(n);
			ARG_ENV.set(argsyms.assoc(n, ret));
		}
		return ret;
	}

	static public function isUnquoteSplicing(form:Any):Bool {
		return U.instanceof(form, ISeq) && Util.equals(RT.first(form), UNQUOTE_SPLICING);
	}

	static public function isUnquote(form:Any):Bool {
		return U.instanceof(form, ISeq) && Util.equals(RT.first(form), UNQUOTE);
	}

	// TODO: just unique object
	public static final READ_EOF:Any = Symbol.createNSname("READ_EOF");
	public static final READ_FINISHED:Any = Symbol.createNSname("READ_FINISHED");

	static public function isPreserveReadCond(opts:Any):Bool {
		if (RT.booleanCast(READ_COND_ENV.deref()) && U.instanceof(opts, IPersistentMap)) {
			var readCond:Any = cast(opts, IPersistentMap).valAt(OPT_READ_COND);
			return COND_PRESERVE.equals(readCond);
		} else
			return false;
	}

	public static function readDelimitedList(delim:Int, r:LineNumberingPushbackReader, isRecursive:Bool, opts:Any, pendingForms:Any):Array<Any> {
		final firstline:Int = U.instanceof(r, LineNumberingPushbackReader) ? r.getLineNumber() : -1;

		var a:Array<Any> = new Array<Any>();
		var resolver:LispReader.Resolver = cast RT.READER_RESOLVER.deref();

		while (true) {
			var form:Any = LispReader.read9(r, false, READ_EOF, String.fromCharCode(delim), READ_FINISHED, isRecursive, opts, pendingForms, resolver);

			if (form == READ_EOF) {
				if (firstline < 0)
					throw Util.runtimeException("EOF while reading");
				else
					throw Util.runtimeException("EOF while reading, starting at line " + firstline);
			} else if (form == READ_FINISHED) {
				return a;
			}

			a.push(form);
		}
	}
}

class RegexReader extends AFn {
	public function new() {}

	override public function invoke4(reader:Any, doublequote:Any, opts:Any, pendingForms:Any):Any {
		var sb:StringBuf = new StringBuf();
		var r:LineNumberingPushbackReader = cast reader;
		var ch:Int = LispReader.read1(r);
		while (ch != '"'.code) {
			if (ch == -1)
				throw Util.runtimeException("EOF while reading regex");
			sb.add(String.fromCharCode(ch));
			if (ch == '\\'.code) // escape
			{
				ch = LispReader.read1(r);
				if (ch == -1)
					throw Util.runtimeException("EOF while reading regex");
				sb.add(String.fromCharCode(ch));
			}
			ch = LispReader.read1(r);
		}
		return new EReg(sb.toString(), "");
	}
}

class StringReader extends AFn {
	public function new() {}

	override public function invoke4(reader:Any, doublequote:Any, opts:Any, pendingForms:Any):Any {
		var r:LineNumberingPushbackReader = cast reader;
		var sb:StringBuf = new StringBuf();
		var ch:Int = LispReader.read1(r);
		while (ch != '"'.code) {
			if (ch == -1)
				throw Util.runtimeException("EOF while reading string");
			if (ch == '\\'.code) // escape
			{
				ch = LispReader.read1(r);
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
							ch = LispReader.read1(r);
							if (Character.digit(ch, 16) == -1)
								throw Util.runtimeException("Invalid unicode escape: \\u" + String.fromCharCode(ch));
							ch = LispReader.readUnicodeChar5(r, ch, 16, 4, true);
						}
					default:
						{
							if (Character.isDigit(ch)) {
								ch = LispReader.readUnicodeChar5(r, ch, 8, 3, false);
								if (ch > 255) // 0377 (octal)
									throw Util.runtimeException("Octal escape sequence must be in range [0, 377].");
							} else
								throw Util.runtimeException("Unsupported escape character: \\" + String.fromCharCode(ch));
						}
				}
			}
			sb.add(String.fromCharCode(ch));
			ch = LispReader.read1(r);
		}
		return sb.toString();
	}
}

class CommentReader extends AFn {
	public function new() {}

	override public function invoke4(reader:Any, semicolon:Any, opts:Any, pendingForms:Any):Any {
		var r:LineNumberingPushbackReader = cast reader;
		var ch:Int;
		do {
			ch = LispReader.read1(r);
		} while (ch != -1 && ch != '\n'.code && ch != '\r'.code);
		return r;
	}
}

class DiscardReader extends AFn {
	public function new() {}

	override public function invoke4(reader:Any, underscore:Any, opts:Any, pendingForms:Any):Any {
		final r:LineNumberingPushbackReader = reader;
		LispReader.read6(r, true, null, true, opts, LispReader.ensurePending(pendingForms));
		return r;
	}
}

class NamespaceMapReader extends AFn {
	public function new() {}

	override public function invoke4(reader:Any, colon:Any, opts:Any, pendingForms:Any):Any {
		final r:LineNumberingPushbackReader = reader;

		var auto:Bool = false;
		var autoChar:Int = LispReader.read1(r);
		if (autoChar == ':'.code) {
			auto = true;
		} else {
			LispReader.unread(r, autoChar);
		}

		var sym:Any = null;
		var nextChar:Int = LispReader.read1(r);
		if (LispReader.isWhitespace(nextChar)) { // the #:: { } case or an error
			if (auto) {
				while (LispReader.isWhitespace(nextChar))
					nextChar = LispReader.read1(r);
				if (nextChar != '{'.code) {
					LispReader.unread(r, nextChar);
					throw Util.runtimeException("Namespaced map must specify a namespace");
				}
			} else {
				LispReader.unread(r, nextChar);
				throw Util.runtimeException("Namespaced map must specify a namespace");
			}
		} else if (nextChar != '{'.code) { // #:foo { } or #::foo { }
			LispReader.unread(r, nextChar);
			sym = LispReader.read6(r, true, null, false, opts, pendingForms);
			nextChar = LispReader.read1(r);
			while (LispReader.isWhitespace(nextChar))
				nextChar = LispReader.read1(r);
		}
		if (nextChar != '{'.code)
			throw Util.runtimeException("Namespaced map must specify a map");

		// Resolve autoresolved ns
		var ns:String;
		if (auto) {
			var resolver:Resolver = cast RT.READER_RESOLVER.deref();
			if (sym == null) {
				if (resolver != null)
					ns = resolver.currentNS().name;
				else
					ns = Compiler.currentNS().getName().getName();
			} else if (!(U.instanceof(sym, Symbol)) || cast(sym, Symbol).getNamespace() != null) {
				throw Util.runtimeException("Namespaced map must specify a valid namespace: " + sym);
			} else {
				var resolvedNS:Symbol;
				if (resolver != null)
					resolvedNS = resolver.resolveAlias(cast(sym, Symbol));
				else {
					var rns:Namespace = Compiler.currentNS().lookupAlias(cast(sym, Symbol));
					resolvedNS = rns != null ? rns.getName() : null;
				}

				if (resolvedNS == null) {
					throw Util.runtimeException("Unknown auto-resolved namespace alias: " + sym);
				} else {
					ns = resolvedNS.getName();
				}
			}
		} else if (!(U.instanceof(sym, Symbol)) || cast(sym, Symbol).getNamespace() != null) {
			throw Util.runtimeException("Namespaced map must specify a valid namespace: " + sym);
		} else {
			ns = cast(sym, Symbol).getName();
		}

		// Read map
		var kvs:Array<Any> = LispReader.readDelimitedList('}'.code, r, true, opts, LispReader.ensurePending(pendingForms));
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

class SymbolicValueReader extends AFn {
	static var specials:IPersistentMap;

	// TODO:
	// = PersistentHashMap.create(Symbol.internNSname("Inf"), Math.POSITIVE_INFINITY, Symbol.internNSname("-Inf"),
	//		Math.NEGATIVE_INFINITY, Symbol.internNSname("NaN"), Math.NaN);

	public function new() {}

	override public function invoke4(reader:Any, rightdelim:Any, opts:Any, pendingForms:Any):Any {
		specials = PersistentHashMap.create(Symbol.internNSname("Inf"), Math.POSITIVE_INFINITY, Symbol.internNSname("-Inf"), Math.NEGATIVE_INFINITY,
			Symbol.internNSname("NaN"), Math.NaN);
		var r:LineNumberingPushbackReader = cast reader;
		var o:Any = LispReader.read6(r, true, null, true, opts, LispReader.ensurePending(pendingForms));
		if (!(U.instanceof(o, Symbol)))
			throw Util.runtimeException("Invalid token: ##" + o);
		if (!(specials.containsKey(o)))
			throw Util.runtimeException("Unknown symbolic value: ##" + o);
		return specials.valAt(o);
	}
}

class WrappingReader extends AFn {
	var sym:Symbol;

	public function new(sym:Symbol) {
		this.sym = sym;
	}

	override public function invoke4(reader:Any, rightdelim:Any, opts:Any, pendingForms:Any):Any {
		var r:LineNumberingPushbackReader = cast reader;
		var o:Any = LispReader.read6(r, true, null, true, opts, LispReader.ensurePending(pendingForms));
		return RT.list(sym, o);
	}
}

class VarReader extends AFn {
	public function new() {}

	override public function invoke4(reader:Any, rightdelim:Any, opts:Any, pendingForms:Any):Any {
		var r:LineNumberingPushbackReader = cast reader;
		var o:Any = LispReader.read6(r, true, null, true, opts, LispReader.ensurePending(pendingForms));
		return RT.list(LispReader.THE_VAR, o);
	}
}

class DispatchReader extends AFn {
	public function new() {}

	override public function invoke4(reader:Any, rightdelim:Any, opts:Any, pendingForms:Any):Any {
		var ch:Int = LispReader.read1(reader);
		if (ch == -1)
			throw Util.runtimeException("EOF while reading character");
		var fn:IFn = LispReader.dispatchMacros[ch];

		if (fn == null) {
			LispReader.unread(reader, ch);
			pendingForms = LispReader.ensurePending(pendingForms);
			var result:Any = LispReader.ctorReader.invoke4(reader, ch, opts, pendingForms);
			if (result != null)
				return result;
			else
				throw Util.runtimeException("No dispatch macro for: " + String.fromCharCode(ch));
		}
		return fn.invoke3(reader, ch, opts);
	}
}

class FnReader extends AFn {
	public function new() {}

	override public function invoke4(reader:Any, rightdelim:Any, opts:Any, pendingForms:Any):Any {
		var r:LineNumberingPushbackReader = reader;
		if (LispReader.ARG_ENV.deref() != null)
			throw new IllegalStateException("Nested #()s are not allowed");
		try {
			Var.pushThreadBindings(RT.map(LispReader.ARG_ENV, PersistentTreeMap.EMPTY));
			LispReader.unread(r, '('.code);
			var form:Any = LispReader.read6(r, true, null, true, opts, LispReader.ensurePending(pendingForms));

			var args:PersistentVector = PersistentVector.EMPTY;
			var argsyms:PersistentTreeMap = cast LispReader.ARG_ENV.deref();
			var rargs:ISeq = argsyms.rseq();
			if (rargs != null) {
				var higharg:Int = cast(rargs.first, (Map.Entry)).getKey();
				if (higharg > 0) {
					var i:Int = 1;
					while (i <= higharg) {
						var sym:Any = argsyms.valAt(i);
						if (sym == null)
							sym = LispReader.garg(i);
						args = args.cons(sym);
						++i;
					}
				}
				var restsym:Any = argsyms.valAt(-1);
				if (restsym != null) {
					args = args.cons(Compiler._AMP_);
					args = args.cons(restsym);
				}
			}
			return RT.list(Compiler.FN, args, form);
		}
		Var.popThreadBindings();
	}
}

class ArgReader extends AFn {
	public function new() {}

	override public function invoke4(reader:Any, rightdelim:Any, opts:Any, pendingForms:Any):Any {
		var r:LineNumberingPushbackReader = cast reader;
		if (LispReader.ARG_ENV.deref() == null) {
			return LispReader.interpretToken(LispReader.readToken(r, '%'.code), null);
		}
		var ch:Int = LispReader.read1(r);
		LispReader.unread(r, ch);
		// % alone is first arg
		if (ch == -1 || LispReader.isWhitespace(ch) || LispReader.isTerminatingMacro(ch)) {
			return LispReader.registerArg(1);
		}
		var n:Any = LispReader.read6(r, true, null, true, opts, LispReader.ensurePending(pendingForms));
		if (Compiler._AMP_.equals(n))
			return LispReader.registerArg(-1);
		if (!(U.instanceof(n, Int)))
			throw new IllegalStateException("arg literal must be %, %& or %integer");
		return LispReader.registerArg(cast n);
	}
}

class MetaReader extends AFn {
	public function new() {}

	override public function invoke4(reader:Any, rightdelim:Any, opts:Any, pendingForms:Any):Any {
		var r:LineNumberingPushbackReader = cast reader;
		var line:Int = -1;
		var column:Int = -1;
		if (U.instanceof(r, LineNumberingPushbackReader)) {
			line = r.getLineNumber();
			column = r.getColumnNumber() - 1;
		}
		pendingForms = LispReader.ensurePending(pendingForms);
		var meta:Any = LispReader.read6(r, true, null, true, opts, pendingForms);
		if (U.instanceof(meta, Symbol) || U.instanceof(meta, String))
			meta = RT.map(RT.TAG_KEY, meta);
		else if (U.instanceof(meta, Keyword))
			meta = RT.map(meta, RT.T);
		else if (!(U.instanceof(meta, IPersistentMap)))
			throw new IllegalArgumentException("Metadata must be Symbol,Keyword,String or Map");

		var o:Any = LispReader.read6(r, true, null, true, opts, pendingForms);
		if (U.instanceof(o, IMeta)) {
			if (line != -1 && U.instanceof(o, ISeq)) {
				meta = RT.assoc(meta, RT.LINE_KEY, RT.get(meta, RT.LINE_KEY, line));
				meta = RT.assoc(meta, RT.COLUMN_KEY, RT.get(meta, RT.COLUMN_KEY, column));
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

class SyntaxQuoteReader extends AFn {
	public function new() {}

	override public function invoke4(reader:Any, rightdelim:Any, opts:Any, pendingForms:Any):Any {
		var r:LineNumberingPushbackReader = cast reader;
		try {
			Var.pushThreadBindings(RT.map(LispReader.GENSYM_ENV, PersistentHashMap.EMPTY));

			var form:Any = LispReader.read6(r, true, null, true, opts, LispReader.ensurePending(pendingForms));
			return syntaxQuote(form);
		} catch (e) {}
		Var.popThreadBindings();
		return null;
	}

	static function syntaxQuote(form:Any):Any {
		var ret:Any;
		if (Compiler.isSpecial(form))
			ret = RT.list(Compiler.QUOTE, form);
		else if (U.instanceof(form, Symbol)) {
			var resolver:Resolver = RT.READER_RESOLVER.deref();
			var sym:Symbol = cast form;
			if (sym.ns == null && StringTools.endsWith(sym.name, "#")) {
				var gmap:IPersistentMap = cast LispReader.GENSYM_ENV.deref();
				if (gmap == null)
					throw new IllegalStateException("Gensym literal not in syntax-quote");
				var gs:Symbol = gmap.valAt(sym);
				if (gs == null)
					LispReader.GENSYM_ENV.set(gmap.assoc(sym,
						gs = Symbol.intern(null, sym.name.substring(0, sym.name.length - 1) + "__" + RT.nextID() + "__auto__")));
				sym = gs;
			} else if (sym.ns == null && StringTools.endsWith(sym.name, ".")) {
				var csym:Symbol = Symbol.intern(null, sym.name.substring(0, sym.name.length - 1));
				if (resolver != null) {
					var rc:Symbol = resolver.resolveClass(csym);
					if (rc != null)
						csym = rc;
				} else
					csym = Compiler.resolveSymbol(csym);
				sym = Symbol.intern(null, csym.name + ".");
			} else if (sym.ns == null && StringTools.startsWith(sym.name, ".")) {
				// Simply quote method names.
			} else if (resolver != null) {
				var nsym:Symbol = null;
				if (sym.ns != null) {
					var alias:Symbol = Symbol.intern(null, sym.ns);
					nsym = resolver.resolveClass(alias);
					if (nsym == null)
						nsym = resolver.resolveAlias(alias);
				}
				if (nsym != null) {
					// Classname/foo -> package.qualified.Classname/foo
					sym = Symbol.intern(nsym.name, sym.name);
				} else if (sym.ns == null) {
					var rsym:Symbol = resolver.resolveClass(sym);
					if (rsym == null)
						rsym = resolver.resolveVar(sym);
					if (rsym != null)
						sym = rsym;
					else
						sym = Symbol.intern(resolver.currentNS().name, sym.name);
				}
				// leave alone if qualified
			} else {
				var maybeClass:Any = null;
				if (sym.ns != null)
					maybeClass = Compiler.currentNS().getMapping(Symbol.intern(null, sym.ns));
				if (U.instanceof(maybeClass, Class)) {
					// Classname/foo -> package.qualified.Classname/foo
					sym = Symbol.intern(Type.getClassName(maybeClass), sym.name);
				} else
					sym = Compiler.resolveSymbol(sym);
			}
			ret = RT.list(Compiler.QUOTE, sym);
		} else if (LispReader.isUnquote(form))
			return RT.second(form);
		else if (LispReader.isUnquoteSplicing(form))
			throw new IllegalStateException("splice not in list");
		else if (U.instanceof(form, IPersistentCollection)) {
			if (U.instanceof(form, IRecord))
				ret = form;
			else if (U.instanceof(form, IPersistentMap)) {
				var keyvals:IPersistentVector = flattenMap(form);
				ret = RT.list(LispReader.APPLY, LispReader.HASHMAP, RT.list(LispReader.SEQ, RT.cons(LispReader.CONCAT, sqExpandList(keyvals.seq()))));
			} else if (U.instanceof(form, IPersistentVector)) {
				ret = RT.list(LispReader.APPLY, LispReader.VECTOR,
					RT.list(LispReader.SEQ, RT.cons(LispReader.CONCAT, sqExpandList(cast(form, IPersistentVector).seq()))));
			} else if (U.instanceof(form, IPersistentSet)) {
				ret = RT.list(LispReader.APPLY, LispReader.HASHSET,
					RT.list(LispReader.SEQ, RT.cons(LispReader.CONCAT, sqExpandList(cast(form, IPersistentSet).seq()))));
			} else if (U.instanceof(form, ISeq) || U.instanceof(form, IPersistentList)) {
				var seq:ISeq = RT.seq(form);
				if (seq == null)
					ret = RT.cons(LispReader.LIST, null);
				else
					ret = RT.list(LispReader.SEQ, RT.cons(LispReader.CONCAT, sqExpandList(seq)));
			} else
				throw new UnsupportedOperationException("Unknown Collection type");
		} else if (U.instanceof(form, Keyword)
			|| U.instanceof(form, Int)
			|| U.instanceof(form, Float) // || U.instanceof(form, Number) Character
			|| U.instanceof(form, String))
			ret = form;
		else
			ret = RT.list(Compiler.QUOTE, form);

		if (U.instanceof(form, IObj) && RT.meta(form) != null) {
			// filter line and column numbers
			var newMeta:IPersistentMap = cast(form, IObj).meta().without(RT.LINE_KEY).without(RT.COLUMN_KEY);
			if (newMeta.count() > 0)
				return RT.list(LispReader.WITH_META, ret, syntaxQuote(cast(form, IObj).meta()));
		}
		return ret;
	}

	private static function sqExpandList(seq:ISeq):ISeq {
		var ret:PersistentVector = PersistentVector.EMPTY;
		while (seq != null) {
			var item:Any = seq.first();
			if (LispReader.isUnquote(item))
				ret = ret.cons(RT.list(LispReader.LIST, RT.second(item)));
			else if (LispReader.isUnquoteSplicing(item))
				ret = ret.cons(RT.second(item));
			else
				ret = ret.cons(RT.list(LispReader.LIST, syntaxQuote(item)));
			seq = seq.next();
		}
		return ret.seq();
	}

	private static function flattenMap(form:Any):IPersistentVector {
		var keyvals:IPersistentVector = PersistentVector.EMPTY;
		var s:ISeq = RT.seq(form);
		while (s != null) {
			var e:IMapEntry = cast s.first();
			keyvals = cast keyvals.cons(e.key());
			keyvals = cast keyvals.cons(e.val());
			s = s.next();
		}
		return keyvals;
	}
}

class UnquoteReader extends AFn {
	public function new() {}

	override public function invoke4(reader:Any, rightdelim:Any, opts:Any, pendingForms:Any):Any {
		var r:LineNumberingPushbackReader = cast reader;
		var ch:Int = LispReader.read1(r);
		if (ch == -1)
			throw Util.runtimeException("EOF while reading character");
		pendingForms = LispReader.ensurePending(pendingForms);
		if (ch == '@'.code) {
			var o:Any = LispReader.read6(r, true, null, true, opts, pendingForms);
			return RT.list(LispReader.UNQUOTE_SPLICING, o);
		} else {
			LispReader.unread(r, ch);
			var o:Any = LispReader.read6(r, true, null, true, opts, pendingForms);
			return RT.list(LispReader.UNQUOTE, o);
		}
	}
}

class CharacterReader extends AFn {
	public function new() {}

	override public function invoke4(reader:Any, rightdelim:Any, opts:Any, pendingForms:Any):Any {
		var r:LineNumberingPushbackReader = reader;
		var ch:Int = LispReader.read1(r);
		if (ch == -1)
			throw Util.runtimeException("EOF while reading character");
		var token:String = LispReader.readToken(r, ch);
		if (token.length == 1)
			// Character.valueOf(token.charAt(0));
			return token;
		else if (token == "newline")
			return '\n';
		else if (token == "space")
			return ' ';
		else if (token == "tab")
			return '\t';
			// else if (token.equals("backspace"))
			// 		return '\b';
			// 	else if (token.equals("formfeed"))
		// 		return '\f';
		else if (token == "return")
			return '\r';
		else if (StringTools.startsWith(token, "u")) {
			var c:Int = LispReader.readUnicodeChar4(token, 1, 4, 16);
			if (c >= 55295 && c <= 57343)
				// if (c >= '\uD800' && c <= '\uDFFF') // surrogate code unit?
				throw Util.runtimeException("Invalid character constant: \\u" + StringTools.hex(c));
			return String.fromCharCode(c);
		} else if (StringTools.startsWith(token, "o")) {
			var len:Int = token.length - 1;
			if (len > 3)
				throw Util.runtimeException("Invalid octal escape sequence length: " + len);
			var uc:Int = LispReader.readUnicodeChar4(token, 1, len, 8);
			if (uc > 255) // octal 0377
				throw Util.runtimeException("Octal escape sequence must be in range [0, 377].");
			return String.fromCharCode(uc);
		}
		throw Util.runtimeException("Unsupported character: \\" + token);
	}
}

class ListReader extends AFn {
	public function new() {}

	override public function invoke4(reader:Any, rightdelim:Any, opts:Any, pendingForms:Any):Any {
		var r:LineNumberingPushbackReader = reader;
		var line:Int = -1;
		var column:Int = -1;
		if (U.instanceof(r, LineNumberingPushbackReader)) {
			line = r.getLineNumber();
			column = r.getColumnNumber() - 1;
		}
		var list = LispReader.readDelimitedList(')'.code, r, true, opts, LispReader.ensurePending(pendingForms));
		if (list.length == 0)
			return PersistentList.EMPTY;
		var s:IObj = cast PersistentList.create(list);
		if (line != -1) {
			var meta:Any = RT.meta(s);
			meta = cast RT.assoc(meta, RT.LINE_KEY, RT.get(meta, RT.LINE_KEY, line));
			meta = cast RT.assoc(meta, RT.COLUMN_KEY, RT.get(meta, RT.COLUMN_KEY, column));
			return s.withMeta(cast(meta, IPersistentMap));
		} else
			return s;
	}
}

class EvalReader extends AFn {
	public function new() {}

	override public function invoke4(reader:Any, rightdelim:Any, opts:Any, pendingForms:Any):Any {
		if (!RT.booleanCast(RT.READEVAL.deref())) {
			throw Util.runtimeException("EvalReader not allowed when *read-eval* is false.");
		}

		var r:LineNumberingPushbackReader = cast reader;
		var o:Any = LispReader.read6(r, true, null, true, opts, LispReader.ensurePending(pendingForms));
		if (U.instanceof(o, Symbol)) {
			return RT.classForName(cast(o, Symbol).toString());
		} else if (U.instanceof(o, IPersistentList)) {
			var fs:Symbol = cast RT.first(o);
			if (fs.equals(LispReader.THE_VAR)) {
				var vs:Symbol = cast RT.second(o);
				return RT.var2(vs.ns, vs.name);
			}
			if (StringTools.endsWith(fs.name, ".")) {
				var args:Vector<Any> = RT.toArray(RT.next(o));
				return Reflector.invokeConstructor(RT.classForName(fs.name.substring(0, fs.name.length - 1)), args);
			}
			if (Compiler.namesStaticMember(fs)) {
				var args:Vector<Any> = RT.toArray(RT.next(o));
				return Reflector.invokeStaticMethod(fs.ns, fs.name, args);
			}
			var v:Any = Compiler.maybeResolveIn(Compiler.currentNS(), fs);
			if (U.instanceof(v, Var)) {
				return cast(v, IFn).applyTo(RT.next(o));
			}
			throw Util.runtimeException("Can't resolve " + fs);
		} else
			throw new IllegalArgumentException("Unsupported #= form");
	}
}

class VectorReader extends AFn {
	public function new() {}

	override public function invoke4(reader:Any, rightdelim:Any, opts:Any, pendingForms:Any):Any {
		var r:LineNumberingPushbackReader = cast reader;
		return LazilyPersistentVector.create(LispReader.readDelimitedList(']'.code, r, true, opts, LispReader.ensurePending(pendingForms)));
	}
}

class MapReader extends AFn {
	public function new() {}

	override public function invoke4(reader:Any, rightdelim:Any, opts:Any, pendingForms:Any):Any {
		var r:LineNumberingPushbackReader = cast reader;
		var a:Array<Any> = LispReader.readDelimitedList('}'.code, r, true, opts, LispReader.ensurePending(pendingForms));
		if ((a.length & 1) == 1)
			throw Util.runtimeException("Map literal must contain an even number of forms");
		return RT.mapFromArray(a);
	}
}

class SetReader extends AFn {
	public function new() {}

	override public function invoke4(reader:Any, rightdelim:Any, opts:Any, pendingForms:Any):Any {
		var r:LineNumberingPushbackReader = cast reader;
		return PersistentHashSet.createWithCheck(LispReader.readDelimitedList('}'.code, r, true, opts, LispReader.ensurePending(pendingForms)));
	}
}

class UnmatchedDelimiterReader extends AFn {
	public function new() {}

	override public function invoke4(reader:Any, rightdelim:Any, opts:Any, pendingForms:Any):Any {
		throw Util.runtimeException("Unmatched delimiter: " + rightdelim);
	}
}

class UnreadableReader extends AFn {
	public function new() {}

	override public function invoke4(reader:Any, rightdelim:Any, opts:Any, pendingForms:Any):Any {
		throw Util.runtimeException("Unreadable form");
	}
}

class CtorReader extends AFn {
	public function new() {}

	override public function invoke4(reader:Any, rightdelim:Any, opts:Any, pendingForms:Any):Any {
		var r:LineNumberingPushbackReader = cast reader;
		pendingForms = LispReader.ensurePending(pendingForms);
		var name:Any = LispReader.read6(r, true, null, false, opts, pendingForms);
		if (!(U.instanceof(name, Symbol)))
			throw new RuntimeException("Reader tag must be a symbol");
		var sym:Symbol = cast name;
		var form:Any = LispReader.read6(r, true, null, true, opts, pendingForms);

		if (LispReader.isPreserveReadCond(opts) || RT.suppressRead()) {
			return TaggedLiteral.create(sym, form);
		} else {
			return StringTools.contains(sym.getName(), ".") ? readRecord(form, sym, opts, pendingForms) : readTagged(form, sym, opts, pendingForms);
		}
	}

	private function readTagged(o:Any, tag:Symbol, opts:Any, pendingForms:Any) {
		var data_readers:ILookup = cast RT.DATA_READERS.deref();
		var data_reader:IFn = cast RT.get(data_readers, tag);
		if (data_reader == null) {
			data_readers = cast RT.DEFAULT_DATA_READERS.deref();
			data_reader = cast RT.get(data_readers, tag);
			if (data_reader == null) {
				var default_reader:IFn = cast RT.DEFAULT_DATA_READER_FN.deref();
				if (default_reader != null)
					return default_reader.invoke2(tag, o);
				else
					throw new RuntimeException("No reader function for tag " + tag.toString());
			}
		}

		return data_reader.invoke(o);
	}

	private function readRecord(form:Any, recordName:Symbol, opts:Any, pendingForms:Any) {
		var readeval:Bool = RT.booleanCast(RT.READEVAL.deref());

		if (!readeval) {
			throw Util.runtimeException("Record construction syntax can only be used when *read-eval* == true");
		}

		var recordClass:Class<Dynamic> = RT.classForNameNonLoading(recordName.toString());

		var shortForm:Bool = true;

		if (U.instanceof(form, IPersistentMap)) {
			shortForm = false;
		} else if (U.instanceof(form, IPersistentVector)) {
			shortForm = true;
		} else {
			throw Util.runtimeException("Unreadable constructor form starting with \"#" + recordName + "\"");
		}

		var ret:Any = null;
		// Constructor[] allctors = ((Class) recordClass).getConstructors();

		if (shortForm) {
			var recordEntries:IPersistentVector = cast form;

			// var ctorFound:Bool = false;
			// 	for (Constructor ctor : allctors)
			// 		if (ctor.getParameterTypes().length == recordEntries.count())
			// 			ctorFound = true;

			// 	if (!ctorFound)
			// 		throw Util.runtimeException("Unexpected number of constructor arguments to " + recordClass.toString() + ": got " + recordEntries.count());

			ret = Reflector.invokeConstructor(recordClass, RT.toArray(recordEntries));
		} else {
			var vals:IPersistentMap = cast form;
			var s:ISeq = RT.keys(vals);
			while (s != null) {
				if (!U.instanceof(s.first(), Keyword))
					throw Util.runtimeException("Unreadable defrecord form: key must be of type clojure.lang.Keyword, got " + s.first());
				s = s.next();
			}
			var v:Vector<Any> = new Vector<Any>(1);
			v[0] = vals;
			ret = Reflector.invokeStaticMethodClass(recordClass, "create", v);
		}

		return ret;
	}
}

class ConditionalReader extends AFn {
	static private final READ_STARTED:Any = EMPTY_ARG.NO_ARG; // Symbol.createNSname();
	static public final DEFAULT_FEATURE:Keyword = Keyword.intern(null, "default");
	static public final RESERVED_FEATURES:IPersistentSet = RT.set(Keyword.intern(null, "else"), Keyword.intern(null, "none"));

	public function new() {}

	public static function hasFeature(feature:Any, opts:Any):Bool {
		if (!(U.instanceof(feature, Keyword)))
			throw Util.runtimeException("Feature should be a keyword: " + feature);

		if (DEFAULT_FEATURE.equals(feature))
			return true;

		var custom:IPersistentSet = cast(cast(opts, IPersistentMap)).valAt(LispReader.OPT_FEATURES);
		return custom != null && custom.contains(feature);
	}

	public static function readCondDelimited(r:LineNumberingPushbackReader, splicing:Bool, opts:Any, pendingForms:Any):Any {
		var result:Any = READ_STARTED;
		var form:Any; // The most recently ready form
		var toplevel:Bool = (pendingForms == null);
		pendingForms = LispReader.ensurePending(pendingForms);

		final firstline:Int = (U.instanceof(r, LineNumberingPushbackReader)) ? (cast(r, LineNumberingPushbackReader)).getLineNumber() : -1;

		while (true) {
			if (result == READ_STARTED) {
				// Read the next feature
				form = LispReader.read9(r, false, LispReader.READ_EOF, ')', LispReader.READ_FINISHED, true, opts, pendingForms, null);

				if (form == LispReader.READ_EOF) {
					if (firstline < 0)
						throw Util.runtimeException("EOF while reading");
					else
						throw Util.runtimeException("EOF while reading, starting at line " + firstline);
				} else if (form == LispReader.READ_FINISHED) {
					break; // read-cond form is done
				}

				if (RESERVED_FEATURES.contains(form))
					throw Util.runtimeException("Feature name " + form + " is reserved.");

				if (hasFeature(form, opts)) {
					// Read the form corresponding to the feature, and assign it to result if everything is kosher

					form = LispReader.read9(r, false, LispReader.READ_EOF, ')', LispReader.READ_FINISHED, true, opts, pendingForms,
						RT.READER_RESOLVER.deref());

					if (form == LispReader.READ_EOF) {
						if (firstline < 0)
							throw Util.runtimeException("EOF while reading");
						else
							throw Util.runtimeException("EOF while reading, starting at line " + firstline);
					} else if (form == LispReader.READ_FINISHED) {
						if (firstline < 0)
							throw Util.runtimeException("read-cond requires an even number of forms.");
						else
							throw Util.runtimeException("read-cond starting on line " + firstline + " requires an even number of forms");
					} else {
						result = form;
					}
				}
			}

			// When we already have a result, or when the feature didn't match, discard the next form in the reader
			try {
				Var.pushThreadBindings(RT.map(RT.SUPPRESS_READ, RT.T));
				form = LispReader.read9(r, false, LispReader.READ_EOF, ')', LispReader.READ_FINISHED, true, opts, pendingForms, RT.READER_RESOLVER.deref());

				if (form == LispReader.READ_EOF) {
					if (firstline < 0)
						throw Util.runtimeException("EOF while reading");
					else
						throw Util.runtimeException("EOF while reading, starting at line " + firstline);
				} else if (form == LispReader.READ_FINISHED) {
					break;
				}
			}
			Var.popThreadBindings();
		}

		if (result == READ_STARTED) // no features matched
			return r;

		if (splicing) {
			if (!(U.isIterable(result)))
				// TODO: Implement IList (java.util.List) for all collections
				throw Util.runtimeException("Spliced form list in read-cond-splicing must implement Iterable");

			if (toplevel)
				throw Util.runtimeException("Reader conditional splicing not allowed at the top level.");

			// TODO: check
			// cast(pendingForms, List<Dynamic>).addAll(0, result);
			var i:Int = 0;
			for (v in U.getIterator(result)) {
				(pendingForms : Array<Any>).insert(i, v);
				i++;
			}
			return r;
		} else {
			return result;
		}
	}

	private static function checkConditionalAllowed(opts:Any) {
		var mopts:IPersistentMap = cast opts;
		if (!(opts != null
			&& (LispReader.COND_ALLOW.equals(mopts.valAt(LispReader.OPT_READ_COND))
				|| LispReader.COND_PRESERVE.equals(mopts.valAt(LispReader.OPT_READ_COND)))))
			throw Util.runtimeException("Conditional read not allowed");
	}

	override public function invoke4(reader:Any, mode:Any, opts:Any, pendingForms:Any):Any {
		checkConditionalAllowed(opts);

		var r:LineNumberingPushbackReader = cast reader;
		var ch:Int = LispReader.read1(r);
		if (ch == -1)
			throw Util.runtimeException("EOF while reading character");

		var splicing:Bool = false;

		if (ch == '@'.code) {
			splicing = true;
			ch = LispReader.read1(r);
		}

		while (LispReader.isWhitespace(ch))
			ch = LispReader.read1(r);

		if (ch == -1)
			throw Util.runtimeException("EOF while reading character");

		if (ch != '('.code)
			throw Util.runtimeException("read-cond body must be a list");

		try {
			Var.pushThreadBindings(RT.map(LispReader.READ_COND_ENV, RT.T));

			if (LispReader.isPreserveReadCond(opts)) {
				var listReader:IFn = LispReader.getMacro(ch); // should always be a list
				var form:Any = listReader.invoke4(r, ch, opts, LispReader.ensurePending(pendingForms));

				var res:Any = ReaderConditional.create(form, splicing);
				Var.popThreadBindings();
				return res;
			} else {
				var res:Any = readCondDelimited(r, splicing, opts, pendingForms);
				Var.popThreadBindings();
				return res;
			}
		} catch (e) {
			Var.popThreadBindings();
			return null;
		}
	}
}

interface Resolver {
	public function currentNS():Symbol;

	public function resolveClass(sym:Symbol):Symbol;

	public function resolveAlias(sym:Symbol):Symbol;

	public function resolveVar(sym:Symbol):Symbol;
}

class ReaderException extends RuntimeException implements IExceptionInfo {
	var lin:Int;
	var column:Int;

	public var data:Any;

	static public final ERR_NS:String = "clojure.error";
	static public final ERR_LINE:Keyword = Keyword.intern(ERR_NS, "line");
	static public final ERR_COLUMN:Keyword = Keyword.intern(ERR_NS, "column");

	public function new(line:Int, column:Int, cause:Exception) {
		super("EDN reading error in line: " + line + ", column: " + column + " " + cause, cause);
		this.lin = line;
		this.column = column;
		this.data = RT.map(ERR_LINE, line, ERR_COLUMN, column);
	}

	public function getData():IPersistentMap {
		return cast data;
	}
}
