package lang;

interface ITransientAssociative extends ITransientCollection extends ILookup {
	public function assoc(key:Any, val:Any):ITransientAssociative;
}
