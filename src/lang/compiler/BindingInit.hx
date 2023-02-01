package lang.compiler;

class BindingInit {
	var _binding:LocalBinding;
	var _init:Expr;

	public function binding():LocalBinding {
		return _binding;
	}

	public function init():Expr {
		return _init;
	}

	public function new(binding:LocalBinding, init:Expr) {
		this._binding = binding;
		this._init = init;
	}
}
