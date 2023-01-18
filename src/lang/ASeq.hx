package lang;

import lang.exceptions.UnsupportedOperationException;
import haxe.Exception;
import haxe.ds.Vector;

abstract class ASeq extends Obj implements ISeq implements Sequential // TODO:
// implements List
// implements Serializable
implements IHashEq implements Collection {
	var _hash:Int;
	var _hasheq:Int;

	public function toString():String {
		return RT.printString(this);
	}

	public function empty():IPersistentCollection {
		return PersistentList.EMPTY;
	}

	public function new(?meta:IPersistentMap = null) {
		super(meta);
	}

	public function equiv(obj:Any):Bool {
		if (!(U.instanceof(obj, Sequential)) // TODO: //||  (Std.downcast(obj, List)!= null)
		)
			return false;

		if (U.instanceof(this, Counted) && U.instanceof(obj, Counted) && cast(this, Counted).count() != cast(obj, Counted).count())
			return false;

		var ms:ISeq = RT.seq(obj);
		var s:ISeq = this;
		while (s != null) {
			if (ms == null || !Util.equiv(s.first(), ms.first()))
				return false;
		}

		return ms == null;
	}

	public function hasheq():Int {
		if (_hasheq == 0) {
			// TODO: check if work
			_hasheq = Murmur3.hashOrdered(this);
		}
		return _hasheq;
	}

	public function count():Int {
		var i:Int = 1;
		var s:ISeq = next();
		while (s != null) {
			if (U.instanceof(s, Counted)) {
				return i + s.count();
			}
			s = s.next();
			i++;
		}
		return i;
	}

	final public function seq():ISeq {
		return this;
	}

	public function cons(o:Any):ISeq {
		return new Cons(o, this);
	}

	public function more():ISeq {
		var s:ISeq = next();
		if (s == null)
			return PersistentList.EMPTY;
		return s;
	}

	// java.util.Collection implementation
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

	public function retainAll(c:Collection):Bool {
		throw new UnsupportedOperationException();
	}

	public function removeAll(c:Collection):Bool {
		throw new UnsupportedOperationException();
	}

	public function containsAll(c:Collection):Bool {
		for (o in U.getIterator(c)) {
			if (!contains(o))
				return false;
		}
		return true;
	}

	/*public function toArray(a:Vector<Any>):Vector<Any> {
		return RT.seqToPassedArray(seq(), a);
	}*/
	public function size():Int {
		return count();
	}

	public function isEmpty():Bool {
		return seq() == null;
	}

	public function contains(o:Any):Bool {
		var s:ISeq = seq();
		while (s != null) {
			if (Util.equiv(s.first(), o))
				return true;
			s = s.next();
		}
		return false;
	}

	public function iterator():Iterator<Any> {
		return new SeqIterator(this);
	}
}
