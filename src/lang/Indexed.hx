package lang;

interface Indexed extends Counted {

	public function nth1(i:Int):Any;

	public function nth2(i:Int, notFound:Any):Any;

	public function nth(...arg:Any):Any;
}
