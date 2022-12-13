package lang;

interface ITransientVector extends ITransientAssociative extends Indexed {
	public function assocN(i:Int, val:Any):ITransientVector;

	public function pop():ITransientVector;
}
