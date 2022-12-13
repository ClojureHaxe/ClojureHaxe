package lang;

import haxe.Exception;

class Obj implements IObj {
	var _meta:IPersistentMap;

	public function new(?meta:IPersistentMap) {
		this._meta = meta;
	}

	public function meta():IPersistentMap {
		return _meta;
	}

	public function withMeta(meta:IPersistentMap):Obj{
		throw new Exception("Obj.meta() implemented in subclasses.");
	}
}
