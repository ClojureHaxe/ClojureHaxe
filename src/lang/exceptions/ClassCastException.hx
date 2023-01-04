package lang.exceptions;

import haxe.Exception;

class ClassCastException extends Exception {
	public function new(?s:String, ?e:Exception) {
		super(s, e);
	}
}
