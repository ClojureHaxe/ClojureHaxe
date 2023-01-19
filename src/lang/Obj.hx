package lang;

import haxe.Exception;

abstract class Obj implements IObj {
	var _meta:IPersistentMap;

	public function new(?meta:IPersistentMap) {
		this._meta = meta;
	}

	public function meta():IPersistentMap {
		return _meta;
	}

	// abstract public function withMeta(meta:IPersistentMap):Obj;
}
