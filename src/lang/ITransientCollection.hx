package lang;

interface ITransientCollection {
	public function conj(val:Any):ITransientCollection;

	public function persistent():IPersistentCollection;
}
