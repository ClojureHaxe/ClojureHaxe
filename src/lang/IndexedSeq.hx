package lang;

interface IndexedSeq extends ISeq extends Sequential extends Counted {
	public function index():Int;
}
