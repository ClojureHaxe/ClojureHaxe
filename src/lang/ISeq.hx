package lang;

interface ISeq extends IPersistentCollection {
	public function first():Any;

	public function next():ISeq;

	public function more():ISeq;

	// TODO: realy not need? 
	// override public function cons(o:Any):ISeq;
}
