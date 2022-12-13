package lang;

interface ITransientAssociative2 extends ITransientAssociative {
	public function containsKey(key:Any):Bool;

	public function entryAt(key:Any):IMapEntry;
}
