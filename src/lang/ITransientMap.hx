package lang;

interface ITransientMap extends ITransientAssociative extends Counted {
	public function assoc(key:Any, val:Any):ITransientMap;

	public function without(key:Any):ITransientMap;

    // TODO: remove from ITransientCollection
	// public function persistent():ITransientMap;
}
