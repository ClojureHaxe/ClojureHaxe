package lang;

import Type.ValueType;

class Numbers {
	// Here can be only Numbers: Int, Float, Ratio
	public static function equiv(x:Any, y:Any):Bool {
		var f1:Float = U.instanceof(x, Ratio) ? cast(x, Ratio).floatValue() : (cast x);
		var f2:Float = U.instanceof(y, Ratio) ? cast(y, Ratio).floatValue() : (cast y);
		return f1 == f2;
	}

	public static function equal(x:Any, y:Any):Bool {
		return Type.typeof(x) == Type.typeof(y) && equiv(x, y);
	}
}
