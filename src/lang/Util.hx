package lang;

class Util {
	static public function equiv(k1:Any, k2:Any):Bool {
		if (k1 == k2)
			return true;
		// TODO
		// if (k1 != null) {
		//     if (k1 instanceof Number && k2 instanceof Number)
		//         return Numbers.equal((Number) k1, (Number) k2);
		//     else if (k1 instanceof IPersistentCollection || k2 instanceof IPersistentCollection)
		//         return pcequiv(k1, k2);
		//     return k1.equals(k2);
		// }
		return false;
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

	public static function hasheq(o:Any):Int {
		// trace("Utis/hasheq", U.getClassName(o), U.instanceof(o, IHashEq));
		if (o == null)
			return 0;
		if (U.instanceof(o, IHashEq)){
			// trace("Utils/hasheq IHasheq: ", cast(o, IHashEq).hasheq());
			return cast(o, IHashEq).hasheq();
		}
		// if (o instanceof Number)
		//     return Numbers.hasheq((Number) o);
		if (U.instanceof(o, String))
			return Murmur3.hashInt(hashCodeString(cast o));
		// return o.hashCode();
		// TODO: smt
		return 100;
	}

	public static function ret1(ret:Any, nil:Any):Any {
		return ret;
	}

	static public function equals(k1:Any, k2:Any):Bool {
		if (k1 == k2)
			return true;
		return k1 != null && U.instanceof(k1, IEqual) && cast(k1, IEqual).equals(k2);
	}

	static public function hashCombine(seed:Int, hash:Int):Int {
		seed ^= hash + 0x9e3779b9 + (seed << 6) + (seed >> 2);
		return seed;
	}

	static public function isInteger(x:Any):Bool {
		/*return x instanceof Integer
			|| x instanceof Long
			|| x instanceof BigInt
			|| x instanceof BigInteger; */
		return x is Int;
	}

	static public function hash(o):Int {
		/* if (o == null)
				return 0;
			return o.hashCode();
		 */
		// TODO:
		return 0;
	}
}
