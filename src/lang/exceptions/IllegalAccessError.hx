package lang.exceptions;

import haxe.Exception;

class IllegalAccessError extends Exception {
	public function new(?s:String) {
		super(s);
	}
}
