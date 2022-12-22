package lang.exceptions;

import haxe.Exception;

class IllegalStateException extends Exception {
	public function new(?s:String, ?e:Exception) {
		super(s, e);
	}
}
