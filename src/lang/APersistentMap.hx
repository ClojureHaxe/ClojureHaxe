package lang;

import haxe.Constraints.IMap;
import lang.exceptions.IllegalArgumentException;
import lang.exceptions.UnsupportedOperationException;

abstract class APersistentMap extends AFn implements IPersistentMap // implements IMap<K, V>
// implements Map, Iterable, Serializable,
// TODO: implements IMap
implements MapEquivalence implements IHashEq {
	var _hash:Int;
	var _hasheq:Int;

	public function toString():String {
		return RT.printString(this);
	}

	public function cons(o:Any):IPersistentCollection {
		/* if (U.instanceof( Map.Entry)) {
				var e Map.Entry  =  o;

				return assoc(e.getKey(), e.getValue());
			} else
		 */

		if (U.instanceof(o, IPersistentVector)) {
			var v:IPersistentVector = o;
			if (v.count() != 2)
				throw new IllegalArgumentException("Vector arg to map conj must be a pair");
			return assoc(v.nth(0), v.nth(1));
		}

		var ret:IPersistentMap = cast this;
		var es:ISeq = RT.seq(o);
		while (es != null) {
			var e:Map.Entry = cast(es.first(), Map.Entry);
			ret = cast ret.assoc(e.getKey(), e.getValue());
			es = es.next();
		}
		return ret;
	}

	public function equals(obj:Any):Bool {
		return mapEquals(this, obj);
	}

	static public function mapEquals(m1:IPersistentMap, obj:Any):Bool {
		// TODO:
		// cause there is no .lenght in haxe.ds.Map... well support only IPersistentMap for now
		if (m1 == obj)
			return true;
		if (!(U.instanceof(obj, IPersistentMap)))
			return false;
		// var m:IPersistentMap = cast obj;
		// TODO: Need some type that has .get()
		var m:APersistentMap = cast obj;

		if (m.count() != m1.count())
			return false;

		var s:ISeq = m1.seq();
		while (s != null) {
			var e:Map.Entry = cast s.first();
			var found:Bool = m.containsKey(e.getKey());

			// TODO:!!!
			if (!found || !Util.equals(e.getValue(), m.get(e.getKey())))
				return false;

			s = s.next();
		}

		return true;
	}

	public function equiv(obj:Any):Bool {
		if (!(U.instanceof(obj, IPersistentMap)))
			return false;
		// TODO: Need some type that has .get()
		var m:APersistentMap = cast obj;

		if (m.count() != count())
			return false;

		var s:ISeq = m.seq();
		while (s != null) {
			var e:Map.Entry = cast s.first();
			var found:Bool = m.containsKey(e.getKey());

			// TODO:!!!
			if (!found || !Util.equiv(e.getValue(), m.get(e.getKey())))
				return false;

			s = s.next();
		}

		return true;
	}

	public function hashCode():Int {
		var cached:Int = this._hash;
		if (cached == 0) {
			this._hash = cached = mapHash(this);
		}
		return cached;
	}

	static public function mapHash(m:IPersistentMap):Int {
		var hash:Int = 0;
		// TODO: hashcode
		// var s:ISeq = m.seq();
		// while (s != null) {
		// 	var e:Map.Entry = cast s.first();
		// 	hash += (e.getKey() == null ? 0 : e.getKey().hashCode()) ^ (e.getValue() == null ? 0 : e.getValue().hashCode());
		// 	s = s.next();
		// }
		return hash;
	}

	public function hasheq():Int {
		var cached:Int = this._hasheq;
		if (cached == 0) {
			// this._hasheq = mapHasheq(this);
			this._hasheq = cached = Murmur3.hashUnordered(this);
		}
		return cached;
	}

	public static final MAKE_ENTRY:IFn = new MakeEntryFN();

	public static final MAKE_KEY:IFn = new MakeKeyFN();

	public static final MAKE_VAL:IFn = new MakeValFN();

	override public function invoke1(arg1:Any) {
		return valAt(arg1);
	}

	override public function invoke2(arg1:Any, notFound:Any) {
		return valAt(arg1, notFound);
	}

	// java.util.Map implementation

	public function clear() {
		throw new UnsupportedOperationException();
	}

	/*public function containsValue( value:Any):Bool{
		// TODO://
		// return values().contains(value);
		return null;
	}*/
	// TODO:
	// public Set entrySet() {
	//     return new AbstractSet() {
	//         public Iterator iterator() {
	//             return APersistentMap.this.iterator();
	//         }
	//         public int size() {
	//             return count();
	//         }
	//         public int hashCode() {
	//             return APersistentMap.this.hashCode();
	//         }
	//         public boolean contains(Object o) {
	//             if (o instanceof Entry) {
	//                 Entry e = (Entry) o;
	//                 Entry found = entryAt(e.getKey());
	//                 if (found != null && Util.equals(found.getValue(), e.getValue()))
	//                     return true;
	//             }
	//             return false;
	//         }
	//     };
	// }

	public function get(key:Any):Any {
		return valAt(key);
	}

	public function isEmpty():Bool {
		return count() == 0;
	}

	// TODO:
	// public Set keySet() {
	//     return new AbstractSet() {
	//         public Iterator iterator() {
	//             final Iterator mi = APersistentMap.this.iterator();
	//             return new Iterator() {
	//                 public boolean hasNext() {
	//                     return mi.hasNext();
	//                 }
	//                 public Object next() {
	//                     Entry e = (Entry) mi.next();
	//                     return e.getKey();
	//                 }
	//                 public void remove() {
	//                     throw new UnsupportedOperationException();
	//                 }
	//             };
	//         }
	//         public int size() {
	//             return count();
	//         }
	//         public boolean contains(Object o) {
	//             return APersistentMap.this.containsKey(o);
	//         }
	//     };
	// }
}

class MakeEntryFN extends AFn {
	public function new() {};

	override public function invoke2(key:Any, val:Any):Any {
		return MapEntry.create(key, val);
	}
}

class MakeKeyFN extends AFn {
	public function new() {};

	override public function invoke2(key:Any, val:Any):Any {
		return return key;
	}
}

class MakeValFN extends AFn {
	public function new() {};

	override public function invoke2(key:Any, val:Any):Any {
		return return val;
	}
}

// KeySeq ==============================================================
class KeySeq extends ASeq {
	var _seq:ISeq;
	var iterable:Iterable<Any>;

	static public function create(seq:ISeq):KeySeq {
		if (seq == null)
			return null;
		return new KeySeq(seq, null);
	}

	static public function createFromMap(map:IPersistentMap):KeySeq {
		if (map == null)
			return null;
		var seq:ISeq = map.seq();
		if (seq == null)
			return null;
		return new KeySeq(seq, cast map);
	}

	private function new(seq:ISeq, iterable:Iterable<Any>, ?meta:IPersistentMap = null) {
		super(meta);
		this._seq = seq;
		this.iterable = iterable;
	}

	public function first():Any {
		return cast(_seq.first(), Map.Entry).getKey();
	}

	// TODO: fix return type IPersistentMap
	public function next():ISeq {
		return cast create(_seq.next());
	}

	public function withMeta(meta:IPersistentMap):KeySeq {
		if (this.meta() == meta)
			return this;
		return new KeySeq(_seq, iterable, meta);
	}

	override public function iterator():Iterator<Any> {
		// TODO:
		// if (iterable == null)
		//		return cast(super, Iterable).iterator();

		if (U.instanceof(iterable, IMapIterable))
			return cast(iterable, IMapIterable).keyIterator();

		final mapIter:Iterator<Any> = iterable.iterator();
		return new KeySeqIterator(mapIter);
	}
}

class KeySeqIterator {
	final mapIter:Iterator<Any>;

	public function new(mapIter) {
		this.mapIter = mapIter;
	}

	public function hasNext():Bool {
		return mapIter.hasNext();
	}

	public function next():Any {
		return cast(mapIter.next(), Map.Entry).getKey();
	}

	// public function remove() {
	//     throw new UnsupportedOperationException();
	// }
}

// ValSeq ===============================================
class ValSeq extends ASeq {
	var _seq:ISeq;
	var iterable:Iterable<Any>;

	static public function create(seq:ISeq):ValSeq {
		if (seq == null)
			return null;
		return new ValSeq(seq, null);
	}

	static public function createFromMap(map:IPersistentMap):ValSeq {
		if (map == null)
			return null;
		var seq:ISeq = map.seq();
		if (seq == null)
			return null;
		return new ValSeq(seq, map);
	}

	private function new(seq:ISeq, iterable:Iterable<Any>, ?meta:IPersistentMap) {
		super(meta);
		this._seq = seq;
		this.iterable = iterable;
	}

	public function first():Any {
		return cast(_seq.first(), Map.Entry).getValue();
	}

	public function next():ISeq {
		return create(_seq.next());
	}

	public function withMeta(meta:IPersistentMap):ValSeq {
		if (this.meta() == meta)
			return this;
		return new ValSeq(_seq, iterable, meta);
	}

	override public function iterator():Iterator<Any> {
		// TODO:
		// if (iterable == null)
		//	return super.iterator();

		if (U.instanceof(iterable, IMapIterable))
			return cast(iterable, IMapIterable).valIterator();

		final mapIter:Iterator<Any> = iterable.iterator();
		return new ValSeqIterator(mapIter);
	}
}

class ValSeqIterator {
	var mapIter:Iterator<Any>;

	public function new(mapIter:Iterator<Any>) {
		this.mapIter = mapIter;
	}

	public function hasNext():Bool {
		return mapIter.hasNext();
	}

	public function next():Any {
		return cast(mapIter.next(), Map.Entry).getValue();
	}
	/*public void remove() {
		throw new UnsupportedOperationException();
	}*/
}
