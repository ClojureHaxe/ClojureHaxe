package lang;

interface IPersistentSet extends IPersistentCollection extends Counted {
	public function disjoin(key:Any):IPersistentSet;

	public function contains(key:Any):Bool;

	public function get(key:Any):Any;
}
