package lang;

interface Sorted {
	public function comparator():Comparator;

	public function entryKey(entry:Any):Any;

	public function seq1(ascending:Bool):ISeq;

	public function seqFrom(key:Any, ascending:Bool):ISeq;
}
