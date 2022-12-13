package lang;

interface ILookup {
	// public function valAt(key:Any):Any;
	public function valAt(key:Any, ?notFound:Any = null):Any;
}
