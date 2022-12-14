package lang;

interface IMapIterable {
	public function keyIterator():Iterator<Any>;

	public function valIterator():Iterator<Any>;
}
