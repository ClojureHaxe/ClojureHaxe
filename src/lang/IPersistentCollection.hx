package lang;

interface IPersistentCollection extends Seqable {
	public function count():Int;

	public function cons(o:Any):IPersistentCollection;

	public function empty():IPersistentCollection;

	public function equiv(o:Any):Bool;
}
