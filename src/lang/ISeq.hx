package lang;

interface ISeq extends IPersistentCollection /* extends  IEqual */ {
	public function first():Any;

	public function next():ISeq;

	public function more():ISeq;

	// TODO: realy not need? 
	// override public function cons(o:Any):ISeq;
}
