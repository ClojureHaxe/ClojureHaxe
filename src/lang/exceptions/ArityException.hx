package lang.exceptions;

import haxe.Exception;

class ArityException extends haxe.Exception {
	public var actual:Int;
	public var name:String;

	public function new(actual:Int, name:String, ?e:Exception) {
		super("Wrong number of args (" + actual + ") passed to: " + name // Compiler.demunge(name)
			, e);
		this.actual = actual;
		this.name = name;
	}
}
