package lang;

import haxe.Exception;
import lang.exceptions.RuntimeException;
import lang.exceptions.IllegalArgumentException;

class ExceptionInfo extends RuntimeException implements IExceptionInfo {
	// private static final long serialVersionUID = -1073473305916521986L;
	public var data:IPersistentMap;

	public static function create(s:String, data:IPersistentMap):ExceptionInfo {
		return new ExceptionInfo(s, data, null);
	}

	public function new(s:String, data:IPersistentMap, throwable:Exception) {
		// null cause is equivalent to not passing a cause
		super(s, throwable);
		if (data != null) {
			this.data = data;
		} else {
			throw new IllegalArgumentException("Additional data must be non-nil.");
		}
	}

	public function getData():IPersistentMap {
		return data;
	}

	override public function toString():String {
		return "clojure.lang.ExceptionInfo: " + this.details() + " " + data;
	}
}
