package lang.exceptions;

import haxe.Exception;

class NoSuchElementException extends Exception {
	public function new(?s:String) {
		super(s);
	}
}
