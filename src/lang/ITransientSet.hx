package lang;

interface ITransientSet extends ITransientCollection extends Counted {
	public function disjoin(key:Any):ITransientSet;

	public function contains(key:Any):Bool;

	public function get(key:Any):Any;
}
