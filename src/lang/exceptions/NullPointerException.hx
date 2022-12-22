package lang.exceptions;

import haxe.Exception;

class NullPointerException extends Exception {
	public function new(?s:String, ?e:Exception) {
		super(s, e);
	}
}
