package lang;

interface IFn {

	public function invoke0():Any;

	public function invoke1(arg1:Any):Any;

	public function invoke2(arg1:Any, arg2:Any):Any;

	public function invoke3(arg1:Any, arg2:Any, arg3:Any):Any;

	public function invoke4(arg1:Any, arg2:Any, arg3:Any, arg4:Any):Any;

	public function invoke5(arg1:Any, arg2:Any, arg3:Any, arg4:Any, arg5:Any):Any;

	public function invoke(...args:Any):Any;

	public function applyTo(arglist:ISeq):Any;
}
