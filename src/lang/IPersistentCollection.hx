package lang;

// Because Haxe doens't have default equals method for every class,
// lets extends IPersistentCollection here with IEqual for all collections
interface IPersistentCollection extends Seqable extends Counted extends IEqual {
	//public function count():Int;

	public function cons(o:Any):IPersistentCollection;

	public function empty():IPersistentCollection;

	public function equiv(o:Any):Bool;
}
