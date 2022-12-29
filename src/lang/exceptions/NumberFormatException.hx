package lang.exceptions;

import haxe.Exception;

class NumberFormatException extends IllegalArgumentException {
	public function new(?s:String, ?e:Exception) {
		super(s, e);
	}
}
