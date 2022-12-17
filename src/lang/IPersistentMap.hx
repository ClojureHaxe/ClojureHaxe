package lang;

interface IPersistentMap extends Associative extends Counted // TODO: extends Iterable
{
	// public function assoc(key:Any, val:Any):IPersistentMap;
	public function assocEx(key:Any, val:Any):IPersistentMap;

	public function without(key:Any):IPersistentMap;

	// TODO: Check
	public function iterator():Iterator<Any>;
}
