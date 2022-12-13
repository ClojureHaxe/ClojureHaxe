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

	public static function hasheq(o:Any):Int {
		if (o == null)
			return 0;
		// if (Uo instanceof IHashEq)
		//     return dohasheq((IHashEq) o);
		// if (o instanceof Number)
		//     return Numbers.hasheq((Number) o);
		// if (o instanceof String)
		//     return Murmur3.hashInt(o.hashCode());
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
}
