package lang;

import lang.exceptions.ArityException;

class Keyword extends AFn implements IFn implements Named implements IHashEq implements IEqual {
	// Serializable Comparable
	public var sym:Symbol;

	public var _str:String;

	private var _hasheq:Int;

	public function new(sym:Symbol) {
		this.sym = sym;
		_hasheq = sym.hasheq() + 0x9e3779b9;
	}

	public static function create(ns:String, name:String):Keyword {
		return new Keyword(Symbol.create(ns, name));
	}

	public static function createNSname(nsname:String):Keyword {
		return new Keyword(Symbol.createNSname(nsname));
	}

	public static function internSymbol(sym:Symbol):Keyword {
		return new Keyword(sym);
	}

	public static function intern(ns:String, name:String):Keyword {
		return new Keyword(Symbol.create(ns, name));
	}

	public static function internNSname(nsname:String):Keyword {
		return new Keyword(Symbol.createNSname(nsname));
	}

	public function hashCode():Int {
		return sym.hashCode() + 0x9e3779b9;
	}

	public function hasheq():Int {
		return _hasheq;
	}

	public function toString():String {
		if (_str == null) {
			_str = (":" + sym);
		}
		return _str;
	}

	public function compareTo(o:Any):Int {
		return sym.compareTo(cast(o, Keyword).sym);
	}

	public function getNamespace():String {
		return sym.getNamespace();
	}

	public function getName():String {
		return sym.getName();
	}

	public function equals(o:Any):Bool {
		if (o == this)
			return true;
		if (!U.instanceof(o, Keyword))
			return false;
		var k:Keyword = cast o;
		return this.sym.equals(k.sym);
	}

	// IFn

	/*override public function throwArity(n:Int):Any {
			throw new ArityException(n, toString());
		}

		override public function invoke0():Any {
			return throwArity(0);
	}*/
	override public function invoke1(obj:Any):Any {
		if (U.instanceof(obj, ILookup))
			return cast(obj, ILookup).valAt(this);
		return RT.get(obj, this);
	}

	override public function invoke2(obj:Any, notFound:Any):Any {
		if (U.instanceof(obj, ILookup))
			return cast(obj, ILookup).valAt(this, notFound);
		return RT.get(obj, this, notFound);
	}
	/*override public function applyTo(arglist:ISeq):Any {
		return AFn.applyToHelper(this, arglist);
	}*/
}
