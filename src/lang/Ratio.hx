package lang;

class Ratio {
	public var numerator:Int;
	public var denominator:Int;

	public function new(numerator:Int, denominator:Int) {
		this.numerator = numerator;
		this.denominator = denominator;
	}

	public function equals(arg0:Any):Bool {
		return arg0 != null
			&& U.instanceof(arg0, Ratio)
			&& cast(arg0, Ratio).numerator == numerator && cast(arg0, Ratio).denominator == denominator;
	}

	public function hashCode():Int {
		return Murmur3.hashInt(numerator) ^ Murmur3.hashInt(denominator);
	}

	public function toString():String {
		return numerator + "/" + denominator;
	}

	public function intValue():Int {
		return Std.int(floatValue());
	}

	public function floatValue():Float {
		return numerator / denominator;
	}
	/*
		public int compareTo(Object o) {
			Number other = (Number) o;
			return Numbers.compare(this, other);
		}
	 */
}
