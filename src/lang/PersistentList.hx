package lang;

import lang.exceptions.UnsupportedOperationException;
import haxe.ds.List;
import haxe.ds.Vector;

class PersistentList extends ASeq implements IPersistentList implements IReduce // TODO: implements List
implements Counted {
	final _first:Any;
	final _rest:IPersistentList;
	final _count:Int;

	public static var creator:IFn = new PersistentList.Primordial();

	public static final EMPTY:EmptyList = new EmptyList(null);

	public function new(first:Any, ?rest:IPersistentList = null, ?count:Int = 1, ?meta:IPersistentMap = null) {
		super(meta);
		// this._first = first;
		// this._rest = null;
		// this._count = 1;
		this._first = first;
		this._rest = rest;
		this._count = count;
	}

	// TODO: use list vs array?
	public static function createFromArray(init:Array<Any>):IPersistentList {
		var ret:IPersistentList = EMPTY;
		var i:Int = init.length - 1;
		while (i >= 0) {
			ret = cast(ret.cons(init[i]), IPersistentList);
			i--;
		}
		return ret;
	}

	public static function create(...init:Any):IPersistentList {
		var ret:IPersistentList = EMPTY;
		var i:Int = init.length - 1;
		while (i >= 0) {
			ret = cast(ret.cons(init[i]), IPersistentList);
			i--;
		}
		return ret;
	}

	public function first():Any {
		return _first;
	}

	public function next():ISeq {
		if (_count == 1) {
			return null;
		}
		return cast(_rest, ISeq);
	}

	public function peek():Any {
		return first();
	}

	public function pop():IPersistentList {
		if (_rest == null) {
			return EMPTY.withMeta(_meta);
		}
		return _rest;
	}

	override public function count():Int {
		return _count;
	}

	override public function cons(o:Any):PersistentList {
		return new PersistentList(o, this, _count + 1, meta());
	}

	override public function empty():IPersistentCollection {
		return EMPTY.withMeta(meta());
	}

	public function withMeta(meta:IPersistentMap):PersistentList {
		if (meta != super.meta())
			return new PersistentList(_first, _rest, _count, meta);
		return this;
	}

	public function reduce1(f:IFn):Any {
		var ret:Any = first();
		var s:ISeq = next();
		while (s != null) {
			ret = f.invoke(ret, s.first());
			if (RT.isReduced(ret)) {
				return cast(ret, IDeref).deref();
			}
		}
		return ret;
	}

	public function reduce2(f:IFn, start:Any):Any {
		var ret:Any = f.invoke(start, first());
		var s:ISeq = next();
		while (s != null) {
			if (RT.isReduced(ret)) {
				return cast(ret, IDeref).deref();
			}
			ret = f.invoke(ret, s.first());
		}
		return ret;
	}
}

class Primordial extends RestFn {
	public function new() {}

	override final public function getRequiredArity():Int {
		return 0;
	}

	final function doInvoke(args:Any):Any {
		return invokeStatic(args);
	}

	static public function invokeStatic(args:ISeq):Any {
		if (U.instanceof(args, ArraySeq)) {
			var argsarray:Array<Any> = cast(args, ArraySeq).array;
			var ret:IPersistentList = PersistentList.EMPTY;
			var i:Int = argsarray.length - 1;
			while (i >= cast(args, ArraySeq).i) {
				ret = cast(ret.cons(argsarray[i]), IPersistentList);
				--i;
			}
			return ret;
		}
		/*var list:List<Any> = new List<Any>();
			var s:ISeq = RT.seq(args);
			while (s != null) {
				list.add(s.first());
				s = s.next();
		}*/
		var list:Array<Any> = new Array<Any>();
		var s:ISeq = RT.seq(args);
		while (s != null) {
			list.push(s.first());
			s = s.next();
		}
		return PersistentList.createFromArray(list);
	}

	override public function withMeta(meta:IPersistentMap):IObj {
		return throw new lang.exceptions.UnsupportedOperationException();
	}

	override public function meta():IPersistentMap {
		return null;
	}
}

class EmptyList extends Obj implements IPersistentList // implements List
implements ISeq implements Counted implements IHashEq implements Collection {
	static final _hasheq:Int = Murmur3.hashOrdered(new Array<Any>());

	public function hashCode():Int {
		return 1;
	}

	public function hasheq():Int {
		return _hasheq;
	}

	public function toString():String {
		return "()";
	}

	public function equals(o:Any):Bool {
		return (U.instanceof(o, Sequential) || U.instanceof(o, List)) && RT.seq(o) == null;
	}

	public function equiv(o:Any):Bool {
		return equals(o);
	}

	public function new(meta:IPersistentMap) {
		super(meta);
	}

	public function first():Any {
		return null;
	}

	public function next():ISeq {
		return null;
	}

	public function more():ISeq {
		return this;
	}

	public function cons(o:Any):PersistentList {
		return new PersistentList(o, null, 1, meta());
	}

	public function empty():IPersistentCollection {
		return this;
	}

	public function withMeta(meta:IPersistentMap):EmptyList {
		if (meta != super.meta()) {
			return new EmptyList(meta);
		}
		return this;
	}

	public function peek():Any {
		return null;
	}

	public function pop():IPersistentList {
		throw new lang.exceptions.IllegalStateException("Can't pop empty list");
	}

	public function count():Int {
		return 0;
	}

	public function seq():ISeq {
		return null;
	}

	public function size():Int {
		return 0;
	}

	public function isEmpty():Bool {
		return true;
	}

	public function contains(o:Any):Bool {
		return false;
	}

	// TODO:
	// public function iterator():Iterator<Any>{
	// }

	public function toArray():Vector<Any> {
		return RT.EMPTY_ARRAY;
	}

	public function add(o:Any):Bool {
		throw new UnsupportedOperationException();
	}

	public function remove(o:Any):Bool {
		throw new UnsupportedOperationException();
	}

	public function addAll(l:List<Any>):Bool {
		throw new UnsupportedOperationException();
	}

	public function clear() {
		throw new UnsupportedOperationException();
	}
}
