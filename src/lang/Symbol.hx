package lang;

class Symbol extends AFn implements IObj implements Named implements IHashEq implements IEqual {
	// Comparable Serializable
	public var ns:String;
	public var name:String;

	var _hasheq:Int = 0;
	var _meta:IPersistentMap;

	public function new(ns, name, ?meta:IPersistentMap) {
		this.ns = ns;
		this.name = name;
		this._meta = meta;
	}

	public function toString():String {
		if (ns != null) {
			return ns + "/" + name;
		} else {
			return name;
		}
	}

	public function getNamespace():String {
		return ns;
	}

	public function getName():String {
		return name;
	}

	public static function create(ns:String, name:String):Symbol {
		return intern(ns, name);
	}

	public static function createNSname(nsname:String):Symbol {
		return internNSname(nsname);
	}

	public static function intern(ns:String, name:String):Symbol {
		return new Symbol(ns, name);
	}

	public static function internNSname(nsname:String):Symbol {
		var i = nsname.indexOf("/");
		if (i == -1 || nsname == "/") {
			return new Symbol(null, nsname);
		} else {
			return new Symbol(nsname.substr(0, i), nsname.substr(i + 1));
		}
	}

	public function equals(o:Any):Bool {
		if (this == o)
			return true;
		if (!U.instanceof(o, Symbol)) {
			return false;
		}
		var s:Symbol = cast o;
		return s.getName() == getName() && s.getNamespace() == getNamespace();
	}

	public function hashCode():Int {
		return Util.hashCombine(Murmur3.hashUnencodedChars(name), Murmur3.hashUnencodedChars(ns));
	}

	public function hasheq():Int {
		if (_hasheq == 0) {
			// lltrace(name, ns, Murmur3.hashUnencodedChars(ns));
			// trace("hashed Symbol: ", Murmur3.hashUnencodedChars(name), Murmur3.hashUnencodedChars(ns));
			_hasheq = Util.hashCombine(Murmur3.hashUnencodedChars(name), Murmur3.hashUnencodedChars(ns));
		}
		return _hasheq;
	}

	public function withMeta(meta:IPersistentMap):IObj {
		if (this.meta() == meta)
			return this;
		return new Symbol(ns, name, meta);
	}

	// TODO: check
	public function compareTo(o:Any):Int {
		var s:Symbol = cast(o, Symbol);
		if (this.equals(o))
			return 0;
		if (this.ns == null && s.ns != null)
			return -1;
		if (this.ns != null) {
			if (s.ns == null)
				return 1;
			if (s.ns > ns) {
				return -1;
			}
		}
		if (this.name > s.name)
			return 1;
		if (this.name < s.name)
			return -1;
		return 0;
	}

	override public function invoke1(obj:Any):Any {
		return RT.get(obj, this);
	}

	override public function invoke2(obj:Any, notFound:Any):Any {
		return RT.get(obj, this, notFound);
	}

	public function meta():IPersistentMap {
		return _meta;
	}
}
