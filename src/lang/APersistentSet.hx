package lang;

import lang.exceptions.UnsupportedOperationException;
import haxe.ds.Vector;

abstract class APersistentSet extends AFn implements IPersistentSet implements IHashEq implements IEqual {
	var _hash:Int;
	var _hasheq:Int;
	final impl:IPersistentMap;

	function new(impl:IPersistentMap) {
		this.impl = impl;
	}

	public function toString():String {
		return RT.printString(this);
	}

	public function contains(key:Any):Bool {
		return impl.containsKey(key);
	}

	public function get(key:Any):Any {
		return impl.valAt(key);
	}

	public function count():Int {
		return impl.count();
	}

	public function seq():ISeq {
		return RT.keys(impl);
	}

	override public function invoke1(arg1:Any):Any {
		return get(arg1);
	}

	public function equals(obj:Any):Bool {
		return setEquals(this, obj);
	}

	static public function setEquals(s1:IPersistentSet, obj:Any):Bool {
		if (s1 == obj)
			return true;
		if (!U.instanceof(obj, IPersistentSet))
			return false;
		var m:IPersistentSet = cast obj;

		if (m.count() != s1.count())
			return false;

		var mi:Iterable<Any> = cast m;
		for (aM in mi.iterator()) {
			if (!s1.contains(aM))
				return false;
		}

		return true;
	}

	public function equiv(obj:Any):Bool {
		if (!U.instanceof(obj, IPersistentSet))
			return false;

		var m:Iterable<Any> = cast obj;

		if (cast(m, IPersistentSet).count() != count())
			return false;

		for (aM in m.iterator()) {
			if (!contains(aM))
				return false;
		}

		return true;
	}

	public function hashCode():Int {
		var hash:Int = this._hash;
		if (hash == 0) {
			var s:ISeq = seq();
			while (s != null) {
				var e:Any = s.first();
				hash += Util.hash(e);
				s = s.next();
			}
			this._hash = hash;
		}
		return hash;
	}

	public function hasheq():Int {
		var cached:Int = this._hasheq;
		if (cached == 0) {
			this._hasheq = cached = Murmur3.hashUnordered(this);
		}
		return cached;
	}

	public function toArray():Vector<Any> {
		return RT.seqToArray(seq());
	}

	public function add(o:Any):Bool {
		throw new UnsupportedOperationException();
	}

	public function remove(o:Any):Bool {
		throw new UnsupportedOperationException();
	}

	public function addAll(c:Collection):Bool {
		throw new UnsupportedOperationException();
	}

	public function clear() {
		throw new UnsupportedOperationException();
	}

	public function retainAll(c:Collection) {
		throw new UnsupportedOperationException();
	}

	public function removeAll(c:Collection):Bool {
		throw new UnsupportedOperationException();
	}

	public function containsAll(c:Collection) {
		for (o in U.getIterator(c)) {
			if (!contains(o))
				return false;
		}
		return true;
	}

	/*
		public toArray(a:Vector<Any>):Vector<Any> {
			return RT.seqToPassedArray(seq(), a);
		}
	 */
	public function size():Int {
		return count();
	}

	public function isEmpty():Bool {
		return count() == 0;
	}

	public function iterator():Iterator<Any> {
		if (U.instanceof(impl, IMapIterable))
			return cast(impl, IMapIterable).keyIterator();
		else
			return new IteratorPS(impl);
	}
}

class IteratorPS {
	private var iter:Iterator<Any>;

	public function new(impl:IPersistentMap) {
		var m:Iterable<Any> = cast impl;
		this.iter = m.iterator();
	}

	public function hasNext():Bool {
		return iter.hasNext();
	}

	public function next():Any {
		return cast(iter.next(), IMapEntry).key();
	}
}
