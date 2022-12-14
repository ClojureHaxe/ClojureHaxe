package lang;

interface IPersistentMap
// TODO: extends Iterable 
extends Associative extends Counted {
	public function assoc(key:Any, val:Any):IPersistentMap;

	public function assocEx(key:Any, val:Any):IPersistentMap;

	public function without(key:Any):IPersistentMap;

	// TODO: Check
	public function iterator():Iterator<Any>;
}
