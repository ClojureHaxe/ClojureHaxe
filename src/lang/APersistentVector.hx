package lang;

import lang.exceptions.ArityException;
import lang.exceptions.IndexOutOfBoundsException;
import lang.exceptions.UnsupportedOperationException;
import lang.exceptions.NoSuchElementException;
import lang.exceptions.IllegalArgumentException;

abstract class APersistentVector extends AFn implements IPersistentVector // implements Iterable
// implements List
implements RandomAccess // implements Comparable
// implements Serializable
implements IHashEq implements IEqual {
	var _hash:Int;
	var _hasheq:Int;

	public function toString():String {
		return RT.printString(this);
	}

	public function seq():ISeq {
		if (count() > 0)
			return new Seq(this, 0);
		return null;
	}

	public function rseq():ISeq {
		if (count() > 0)
			return new RSeq(this, count() - 1);
		return null;
	}

	// TODO: test
	static public function doEquals(v:IPersistentVector, obj:Any):Bool {
		if (U.instanceof(obj, IPersistentVector)) {
			var ov:IPersistentVector = cast(obj, IPersistentVector);
			if (ov.count() != v.count())
				return false;
			var i:Int = 0;
			while (i < v.count()) {
				if (!Util.equals(v.nth(i), ov.nth(i)))
					return false;
				i++;
			}
			return true;
		} else if (U.instanceof(obj, List)) { // TODO: Iterator/Iterable
			var ma:List<Any> = cast(obj, List<Dynamic>);
			if (ma.length != v.count()) // || ma.hashCode() != v.hashCode()
				return false;
			var i1:Iterator<Any> = ma.iterator();
			var i:Int = 0;
			while (i1.hasNext()) {
				if (!Util.equals(v.nth(i), i1.next())) {
					return false;
				}
				i++;
			}
			return true;
		} else {
			if (!U.instanceof(obj, Sequential))
				return false;
			var ms:ISeq = RT.seq(obj);
			var i:Int = 0;
			while (i < v.count()) {
				if (ms == null || !Util.equals(v.nth(i), ms.first()))
					return false;
				i++;
				ms = ms.next();
			}
			if (ms != null)
				return false;
		}
		return true;
	}

	public function equals(obj:Any):Bool {
		if (obj == this)
			return true;
		return doEquals(this, obj);
	}

	public function equiv(obj:Any):Bool {
		if (obj == this)
			return true;
		// TODO: equiv
		return equals(obj);
	}

	public function hasheq():Int {
		var hash:Int = this._hasheq;
		if (hash == 0) {
			var n:Int = 0;
			hash = 1;
			while (n < count()) {
				hash = 31 * hash + Util.hasheq(nth1(n));
				++n;
			}
			this._hasheq = hash = Murmur3.mixCollHash(hash, n);
		}
		return hash;
	}

	// TODO: get and nth - subclasses

	public function get(index:Int, notFound:Any = null):Any {
		return nth1(index);
	}

	public function nth2(i:Int, notFound:Any):Any {
		if (i >= 0 && i < count())
			return nth1(i);
		return notFound;
	}

	public function nth(...args:Any):Any {
		switch args.length {
			case 1:
				return nth1(args[0]);
			case 2:
				return nth2(args[0], args[1]);
			default:
				throw new ArityException(args.length, U.getClassName(this));
		}
	}

	public function indexOf(o:Any):Int {
		var i:Int = 0;
		while (i < this.count()) {
			if (Util.equiv(nth1(i), o))
				return i;
			i++;
		}
		return -1;
	}

	public function lastIndexOf(o:Any):Int {
		var i:Int = count() - 1;
		while (i >= 0) {
			if (Util.equiv(nth1(i), o))
				return i;
			i--;
		}
		return -1;
	}

	function rangedIterator(start:Int, end:Int):Iterator<Any> {
		return new RangedIterator(this, start, end);
	}

	// TODO: List stuff

	/*public function  subList(fromIndex:Int, toIndex:Int):List<Any> {
		return (List) RT.subvec(this, fromIndex, toIndex);
	}*/
	override public function invoke1(arg1:Any):Any {
		if (Util.isInteger(arg1))
			// TODO: use Numbers
			return nth1(cast(arg1, Int));
		throw new IllegalArgumentException("Key must be integer");
	}

	public function iterator():Iterator<Any> {
		return new RangedIterator(this, 0, this.count());
	}

	public function peek():Any {
		if (count() > 0)
			return nth(count() - 1);
		return null;
	}

	public function containsKey(key:Any):Bool {
		if (!(Util.isInteger(key)))
			return false;
		// int i = ((Number) key).intValue();
		// TODO:
		var i:Int = cast key;
		return i >= 0 && i < count();
	}

	public function entryAt(key:Any):IMapEntry {
		if (Util.isInteger(key)) {
			// TODO:
			// int i = ((Number) key).intValue();
			var i:Int = cast key;
			if (i >= 0 && i < count())
				return MapEntry.create(key, nth(i));
		}
		return null;
	}

	public function assoc(key:Any, val:Any):IPersistentVector {
		if (Util.isInteger(key)) {
			// int i = ((Number) key).intValue();
			// TODO::
			var i:Int = cast key;
			return assocN(i, val);
		}
		throw new IllegalArgumentException("Key must be integer");
	}

	public function valAt(key:Any, notFound:Any = null):Any {
		if (Util.isInteger(key)) {
			// int i = ((Number) key).intValue();
			// TODO::
			var i:Int = cast key;
			if (i >= 0 && i < count())
				return nth(i);
		}
		return notFound;
	}

	public function length():Int {
		return count();
	}
}

// === RangedIterator ========================================================
class RangedIterator {
	var v:APersistentVector;
	var i:Int;
	var end:Int;

	public function new(v:APersistentVector, start:Int, end:Int) {
		this.v = v;
		this.i = start;
		this.end = end;
	}

	public function hasNext():Bool {
		return i < end;
	}

	public function next():Any {
		if (i < end)
			return v.nth(i++);
		else
			throw new NoSuchElementException();
	}
}

// === Seq =====================================================================
class Seq extends ASeq implements IndexedSeq implements IReduce {
	// todo - something more efficient
	var v:IPersistentVector;
	var i:Int;

	public function new(v:IPersistentVector, i:Int, ?meta:IPersistentMap) {
		super(meta);
		this.v = v;
		this.i = i;
	}

	public function first():Any {
		return v.nth(i);
	}

	public function next():ISeq {
		if (i + 1 < v.count())
			return new APersistentVector.Seq(v, i + 1);
		return null;
	}

	public function index():Int {
		return i;
	}

	override public function count():Int {
		return v.count() - i;
	}

	override public function withMeta(meta:IPersistentMap):APersistentVector.Seq {
		if (this.meta() == meta)
			return this;
		return new APersistentVector.Seq(v, i, meta);
	}

	public function reduce1(f:IFn):Any {
		var ret:Any = v.nth(i);
		var x:Int = i + 1;
		while (x < v.count()) {
			ret = f.invoke(ret, v.nth(x));
			if (RT.isReduced(ret))
				return cast(ret, IDeref).deref();
			x++;
		}
		return ret;
	}

	public function reduce2(f:IFn, start:Any):Any {
		var ret:Any = f.invoke2(start, v.nth(i));
		var x:Int = i + 1;
		while (x < v.count()) {
			if (RT.isReduced(ret))
				return cast(ret, IDeref).deref();
			ret = f.invoke(ret, v.nth(x));
			x++;
		}
		if (RT.isReduced(ret))
			return cast(ret, IDeref).deref();
		return ret;
	}
}

// === RSeq =====================================================================
class RSeq extends ASeq implements IndexedSeq implements Counted {
	var v:IPersistentVector;
	var i:Int;

	public function new(v:IPersistentVector, i:Int, ?meta:IPersistentMap) {
		super(meta);
		this.v = v;
		this.i = i;
	}

	public function first():Any {
		return v.nth(i);
	}

	public function next():ISeq {
		if (i > 0)
			return new APersistentVector.RSeq(v, i - 1);
		return null;
	}

	public function index():Int {
		return i;
	}

	override public function count():Int {
		return i + 1;
	}

	override public function withMeta(meta:IPersistentMap):APersistentVector.RSeq {
		if (this.meta() == meta)
			return this;
		return new APersistentVector.RSeq(v, i, meta);
	}
}

// === SubVector =====================================================================
class SubVector extends APersistentVector implements IObj implements IKVReduce {
	var v:IPersistentVector;
	var start:Int;
	var end:Int;
	var _meta:IPersistentMap;

	public function new(meta:IPersistentMap, v:IPersistentVector, start:Int, end:Int) {
		this._meta = meta;

		if (U.instanceof(v, APersistentVector.SubVector)) {
			var sv:APersistentVector.SubVector = cast(v, APersistentVector.SubVector);
			start += sv.start;
			end += sv.start;
			v = sv.v;
		}
		this.v = v;
		this.start = start;
		this.end = end;
	}

	// TODO:

	/*public Iterator iterator() {
		if (v instanceof APersistentVector) {
			return ((APersistentVector) v).rangedIterator(start, end);
		}
		return super.iterator();
	}*/
	public function kvreduce(f:IFn, init:Any):Any {
		var cnt:Int = count();
		var i:Int = 0;
		while (i < cnt) {
			init = f.invoke3(init, i, v.nth(start + i));
			if (RT.isReduced(init))
				return cast(init, IDeref).deref();
			i++;
		}
		return init;
	}

	public function nth1(i:Int):Any {
		if ((start + i >= end) || (i < 0))
			throw new IndexOutOfBoundsException();
		return v.nth(start + i);
	}

	public function assocN(i:Int, val:Any):IPersistentVector {
		if (start + i > end)
			throw new IndexOutOfBoundsException();
		else if (start + i == end)
			return cons(val);
		return new SubVector(_meta, v.assocN(start + i, val), start, end);
	}

	public function count():Int {
		return end - start;
	}

	public function cons(o:Any):IPersistentVector {
		return new SubVector(_meta, v.assocN(end, o), start, end + 1);
	}

	public function empty():IPersistentCollection {
		return PersistentVector.EMPTY.withMeta(this.meta());
	}

	public function pop():IPersistentStack {
		if (end - 1 == start) {
			return PersistentVector.EMPTY;
		}
		return new SubVector(_meta, v, start, end - 1);
	}

	public function withMeta(meta:IPersistentMap):SubVector {
		if (meta == _meta)
			return this;
		return new SubVector(meta, v, start, end);
	}

	public function meta():IPersistentMap {
		return _meta;
	}
}
