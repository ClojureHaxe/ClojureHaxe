package lang;

import haxe.Exception;
import Type.ValueType;
import lang.PersistentHashMap.ArrayNode;
import lang.exceptions.RuntimeException;

class Util {
	static public function equiv(k1:Any, k2:Any):Bool {
		if (k1 == k2)
			return true;
		if (k1 != null) {
			if (U.isNumber(k1) && U.isNumber(k2))
				return Numbers.equal(k1, k2);
			else if (U.instanceof(k1, IPersistentCollection) || U.instanceof(k2, IPersistentCollection))
				return pcequiv(k1, k2);
			else if (U.instanceof(k1, IEqual)) {
				return cast(k1, IEqual).equals(k2);
			} else if ((U.getClassName(k1) == U.getClassName(k2)) && k1 != k2) {
				return false;
			}
			// TODO: return false
			throw runtimeException('ERROR: cant equiv: $k1 (${U.typeName(k1)}) with $k2 (${U.typeName(k2)})');
		}
		return false;
	}

	static final equivNull:EquivPred = new EquivPredNull();
	static final equivEquals:EquivPred = new EquivPredEquals();
	static final equivNumber:EquivPred = new EquivPredNumber();
	static final equivColl:EquivPred = new EquivPredColl();

	static public function equivPred(k1:Any):EquivPred {
		if (k1 == null)
			return equivNull;
		else if (U.isNumber(k1))
			return equivNumber;
		else if (U.instanceof(k1, String) || U.instanceof(k1, Symbol))
			return equivEquals;
		else if (U.instanceof(k1, IPersistentCollection) || U.instanceof(k1, IPersistentCollection))
			return equivColl;
		return equivEquals;
	}

	static public function pcequiv(k1:Any, k2:Any):Bool {
		if (U.instanceof(k1, IPersistentCollection))
			return cast(k1, IPersistentCollection).equiv(k2);
		return cast(k2, IPersistentCollection).equiv(k1);
	}

	static public function equals(k1:Any, k2:Any):Bool {
		if (k1 == k2)
			return true;
		return k1 != null && U.instanceof(k1, IEqual) && cast(k1, IEqual).equals(k2);
	}

	static public function identical(k1:Any, k2:Any):Bool {
		return k1 == k2;
	}

	// TODO: doesnt work properly on several platforms (Python, NodeJS)
	static public function classOf(x:Any):Class<Any> {
		try {
			// In lua it throws Exception for primitive types like Int
			return Type.getClass(x);
		} catch (e) {
			return null;
		}
	}

	static public function compare(k1:Any, k2:Any):Int {
		// TODO: compare fix?
		if (k1 == k2)
			return 0;
		if (k1 != null) {
			if (k2 == null)
				return 1;
			if (U.isNumber(k1) && U.isNumber(k2))
				if ((cast k1) > (cast k2))
					return 1;
				else
					return -1;
			if (U.instanceof(k1, String) && U.instanceof(k2, String)) {
				if (cast(k1, String) > cast(k2, String))
					return 1;
				else
					return -1;
			}
			// return Numbers.compare((Number) k1, (Number) k2);
			// return ((Comparable) k1).compareTo(k2);
			// throw runtimeException("Cant compare " + k1 + " and " + k2);
			if (U.instanceof(k1, Comparable)) {
				return cast(k1, Comparable).compareTo(k2);
			}
		}
		/*return -1;*/
		return Reflect.compare(k1, k2);
	}

	// TODO: write String wrapper with _hash field hashed
	public static function hashCodeString(s:String):Int {
		var hash:Int = 0;
		var l = s.length;
		if (s.length > 0) {
			var i:Int = 0;
			while (i < l && i < 8) {
				hash = 31 * hash + s.charCodeAt(i);
				i++;
			}
			while (i < l && i < 16) {
				hash = 31 * hash + s.charCodeAt(i);
				i += 2;
			}
			while (i < l && i < 256) {
				hash = 31 * hash + s.charCodeAt(i);
				i += 4;
			}
			while (i < l && i < 1024) {
				hash = 31 * hash + s.charCodeAt(i);
				i += 16;
			}
			while (i < l) {
				hash = 31 * hash + s.charCodeAt(i);
				i += 32;
			}
			if (i > 32) {
				hash = 31 * hash + s.charCodeAt(l - 1);
			}
			return hash;
		}
		return hash;
	}

	public static function hash(o:Any):Int {
		return hasheq(o);
	}

	public static function hasheq(o:Any):Int {
		if (o == null)
			return 0;
		if (U.instanceof(o, IHashEq))
			return cast(o, IHashEq).hasheq();
		if (Type.typeof(o) == ValueType.TInt)
			return Murmur3.hashInt(o);
		if (Type.typeof(o) == ValueType.TFloat)
			return Murmur3.hashFloat(o);
		if (Type.typeof(o) == ValueType.TBool)
			return cast o == true ? 1231 : 1237;
		if (U.instanceof(o, String))
			return Murmur3.hashInt(hashCodeString(cast o));
		if (U.instanceof(o, Ratio))
			return (cast(o, Ratio)).hashCode();
		// return o.hashCode();
		// TODO: smt for classes
		return Murmur3.hashUnencodedChars(U.getClassName(o));
	}

	static public function hashCombine(seed:Int, hash:Int):Int {
		seed ^= hash + 0x9e3779b9 + (seed << 6) + (seed >> 2);
		return seed;
	}

	/*
		static public function isPrimitive(Class c):Bool {
			return c != null && c.isPrimitive() && !(c == Void.TYPE);
		}
	 */
	static public function isInteger(x:Any):Bool {
		return Std.isOfType(x, Int);
	}

	public static function ret1(ret:Any, nil:Any):Any {
		return ret;
	}

	static public function runtimeException(s:String, ?e:Exception):RuntimeException {
		return new RuntimeException(s, e);
	}

	static public function sneakyThrow(e:Exception):Exception {
		return e;
	}
}

// EquivPred =================================================================
interface EquivPred {
	public function equiv(k1:Any, k2:Any):Bool;
}

class EquivPredNull implements EquivPred {
	public function new() {}

	public function equiv(k1:Any, k2:Any):Bool {
		return k2 == null;
	}
}

class EquivPredEquals implements EquivPred {
	public function new() {}

	public function equiv(k1:Any, k2:Any):Bool {
		if (U.instanceof(k1, IEqual)) {
			return cast(k1, IEqual).equals(k2);
		}
		return k1 == k2;
	}
}

class EquivPredNumber implements EquivPred {
	public function new() {}

	public function equiv(k1:Any, k2:Any):Bool {
		if (U.isNumber(k2)) {
			return Numbers.equal(k1, k2);
		}
		return false;
	}
}

class EquivPredColl implements EquivPred {
	public function new() {}

	public function equiv(k1:Any, k2:Any):Bool {
		if (U.instanceof(k1, IPersistentCollection) || U.instanceof(k2, IPersistentCollection))
			return Util.pcequiv(k1, k2);
		return cast(k1, IEqual).equals(k2);
	}
}
