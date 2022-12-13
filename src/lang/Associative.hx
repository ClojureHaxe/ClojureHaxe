package lang;

interface Associative extends IPersistentCollection extends ILookup {
	public function containsKey(key:Any):Bool;

	public function entryAt(key:Any):IMapEntry;

	public function assoc(key:Any, val:Any):Associative;
}
