package lang;

import haxe.Exception;

class ASeq extends Obj implements ISeq implements Sequential // TODO:
// implements List
// implements Serializable
implements IHashEq {
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

		if ( // Std.downcast(this, Counted) != null &&
			// Std.downcast(obj, Counted) != null &&
			U.instanceof(this, Counted) && U.instanceof(obj, Counted) && cast(this, Counted).count() != cast(obj, Counted).count())
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

	public function first():Any {
		throw new Exception("ASeq.first() implemented in subclassed.");
		return null;
	}

	public function next():ISeq {
		throw new Exception("ASeq.next() implemented in subclasses.");
		return null;
	}

	public function hasNext():Bool {
		return next() != null;
	}
}
