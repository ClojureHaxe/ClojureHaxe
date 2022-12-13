package lang;

interface IPersistentStack extends IPersistentCollection {
	public function peek():Any;

	public function pop():IPersistentStack;
}
