package lang;

class Reduced implements IDeref {
	var val:Any;

	public function new(val:Any) {
		this.val = val;
	}

	public function deref():Any {
		return val;
	}
}
