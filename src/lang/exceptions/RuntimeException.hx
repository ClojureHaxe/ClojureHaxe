package lang.exceptions;

import haxe.Exception;

class RuntimeException extends Exception {
	public function new(?s:String) {
		super(s);
	}
}
