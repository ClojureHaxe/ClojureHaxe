package lang;

// Like Java Map
interface EntrySet {
	public function entrySet():Array<Any>;
}

interface Entry /*<K, V>*/ {
	// public function getKey():K;
	// public function getValue():V;
	// public function setValue(var1:V):V;
	public function getKey():Any;

	public function getValue():Any;

	public function setValue(var1:Any):Any;
	// boolean equals(Object var1);
	// int hashCode();
}
