package lang;

interface IPersistentVector extends Associative extends Sequential extends IPersistentStack extends Reversible extends Indexed {
	public function length():Int;

	public function assocN(i:Int, val:Any):IPersistentVector;

	// public function cons(o:Any):IPersistentVector;
}
