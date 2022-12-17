package lang;

import haxe.ds.Vector;

class RT {
	static public final EMPTY_ARRAY:Array<Any> = new Array<Any>();

	public static function get(coll:Any, key:Any, ?notFound = null):Any {
		return null;
	}

	static public function cons(x:Any, coll:Any):ISeq {
		// ISeq y = seq(coll);
		if (coll == null)
			return new PersistentList(x);
		else if (U.instanceof(coll, ISeq))
			return new Cons(x, cast coll);
		else
			return new Cons(x, seq(coll));
	}

	static public function first(x:Any) {
		if (U.instanceof(x, ISeq))
			return (cast x).first();
		var seq:ISeq = seq(x);
		if (seq == null)
			return null;
		return seq.first();
	}

	static public function next(x:Any):ISeq {
		if (U.instanceof(x, ISeq))
			return (cast x).next();
		var seq:ISeq = seq(x);
		if (seq == null)
			return null;
		return seq.next();
	}

	static public function printString(x:Any):String {
		var sb:StringBuf = new StringBuf();
		print(x, sb);
		return sb.toString();
	}

	static public function print(x:Any, sb:StringBuf) {
		// trace("IN PRINT");
		// if (U.instanceof(x, ArraySeq)) {
		// 	trace("In print: ", cast(x, ArraySeq).array, U.instanceof(x, ISeq) /*, sb.toString()*/);
		// }

		if (x == null) {
			sb.add("nil");
		} else if (U.instanceof(x, String)) {
			var s:String = cast(x, String);
			var i:Int = 0;
			sb.add('"');
			while (i < s.length) {
				var c:String = s.charAt(i);
				switch (c) {
					case '\n':
						sb.add("\\n");
					case '\t':
						sb.add("\\t");
					case '\r':
						sb.add("\\r");
					case '"':
						sb.add("\\\"");
					case '\\':
						sb.add("\\\\");

					// case '\f':
					// 	w.write("\\f");
					// 	break;
					// case '\b':
					// 	w.write("\\b");
					// 	break;

					default:
						sb.add(c);
				}
				i++;
			}
			sb.add('"');
		} else if (U.instanceof(x, ISeq) || U.instanceof(x, IPersistentList)) {
			sb.add('(');
			printInnerSeq(seq(x), sb);
			sb.add(')');
		} else if (U.instanceof(x, IPersistentMap) || (U.instanceof(x, PersistentHashMap))) {
			sb.add("{");
			var s:ISeq = seq(x);
			while (s != null) {
				var e:IMapEntry = s.first();
				print(e.key(), sb);
				sb.add(" ");
				print(e.val(), sb);
				if (s.next() != null) {
					sb.add(", ");
				}
				s = s.next();
			}
			sb.add("}");
		} else
			// if (Std.isOfType(x, IPersistentVector))
			if (U.instanceof(x, IPersistentVector)) {
				// trace("print cast to vector yes!");
				var a:IPersistentVector = cast(x, IPersistentVector);
				var i:Int = 0;
				sb.add("[");
				while (i < a.count()) {
					print(a.nth(i), sb);
					if (i < a.count() - 1) {
						sb.add(' ');
					}
					i++;
				}
				sb.add("]");
			} else {
				sb.add('$x');
				// sb.add(Std.string(x));
			}
	}

	private static function printInnerSeq(x:ISeq, sb:StringBuf) {
		var s:ISeq = x;
		while (s != null) {
			var fr:Any = s.first();
			// trace("next()", fr, U.instanceof(x, Int), U.instanceof(x, String), U.instanceof(Std.downcast(fr, String), String));
			print(fr, sb);
			if (s.next() != null)
				sb.add(' ');
			s = s.next();
		}
	}

	public static final CHUNK_SIZE = 32;

	public static function chunkIteratorSeq(iter:Iterator<Any>):ISeq {
		if (iter.hasNext()) {
			return LazySeq.createFromFn(new ChunkIteratorSeqLazySeqAFn(iter));
		}
		return null;
	}

	static public function seq(coll:Any):ISeq {
		if (U.instanceof(coll, ASeq))
			return cast(coll, ASeq);
			// TODO
			// else if (U.instanceof(call, LazySeq))
		//    return ((LazySeq) coll).seq();
		else
			return seqFrom(coll);
	}

	static function seqFrom(coll:Any):ISeq {
		if (U.instanceof(coll, Seqable))
			return cast(coll, Seqable).seq();
		else if (coll == null)
			return null;
		else if (U.isIterable(coll))
			// return null;
			return chunkIteratorSeq((cast coll).iterator());
			// else if (coll.getClass().isArray())
			//     return ArraySeq.createFromObject(coll);
			// else if (coll instanceof CharSequence)
			//     return StringSeq.create((CharSequence) coll);
			// else if (coll instanceof Map)
		//     return seq(((Map) coll).entrySet());
		else {
			throw new haxe.exceptions.ArgumentException("Don't know how to create ISeq from: " + Type.getClassName(Type.getClass(coll)));
		}
		return null;
	}

	static public function booleanCast(x:Any):Bool {
		if (U.instanceof(x, Bool))
			return cast(x, Bool);
		return x != null;
	}

	public static function count(o:Any):Int {
		if (U.instanceof(o, Counted))
			return cast(o, Counted).count();
		return countFrom(Util.ret1(o, o = null));
	}

	private static function countFrom(o:Any):Int {
		if (o == null)
			return 0;
		else if (U.instanceof(o, IPersistentCollection)) {
			var s:ISeq = seq(o);
			o = null;
			var i:Int = 0;
			while (s != null) {
				if (U.instanceof(s, Counted)) {
					return i + s.count();
				}
				i++;
			}
			return i;
		} else if (U.instanceof(o, String)) {
			return cast(o, String).length;
		}
		// TODO:
		/*
			} else if (o instanceof CharSequence)
				return ((CharSequence) o).length();
			else if (o instanceof Collection)
				return ((Collection) o).size();
			else if (o instanceof Map)
				return ((Map) o).size();
			else if (o instanceof Map.Entry)
				return 2;
			else if (o.getClass().isArray())
				return Array.getLength(o); */

		return 0;

		// throw new UnsupportedOperationException("count not supported on this type: " + o.getClass().getSimpleName());
	}

	static public function isReduced(r:Any):Bool {
		return U.instanceof(r, Reduced);
	}

	static public function length(list:ISeq):Int {
		var i:Int = 0;
		var c:ISeq = list;
		while (c != null) {
			i++;
			c = c.next();
		}
		return i;
	}

	static public function seqToArray(seq:ISeq):Vector<Any> {
		var len:Int = length(seq);
		var ret:Vector<Any> = new Vector<Any>(len);
		var i:Int = 0;
		while (seq != null) {
			ret[i] = seq.first();
			++i;
			seq = seq.next();
		}
		return ret;
	}
}

class ChunkIteratorSeqLazySeqAFn extends AFn {
	var iter:Iterator<Any>;

	public function new(iter:Iterator<Any>) {
		this.iter = iter;
	}

	override public function invoke0():Any {
		var arr:Vector<Any> = new Vector<Any>(RT.CHUNK_SIZE);
		var n:Int = 0;
		while (iter.hasNext() && n < RT.CHUNK_SIZE)
			arr[n++] = iter.next();
		return new ChunkedCons(new ArrayChunk(arr, 0, n), RT.chunkIteratorSeq(iter));
	}
}
