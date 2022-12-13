package lang.exceptions;

import haxe.Exception;

class UnsupportedOperationException extends Exception {
	public function new(?s:String) {
		super(s);
	}
}
