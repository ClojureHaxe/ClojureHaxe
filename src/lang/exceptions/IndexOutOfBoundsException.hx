package lang.exceptions;

import haxe.Exception;

class IndexOutOfBoundsException extends Exception {
	public function new(?s:String, ?index:Int) {
		super(if (index != null) "Index out of range: " + index else s);
		// if (index != null) {
		// 	super("Index out of range: " + index);
		// } else {
		// 	super(s);
		// }
	}
}