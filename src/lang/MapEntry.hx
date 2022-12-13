package lang;

class MapEntry extends AMapEntry {
	var _key:Any;
	var _val:Any;

	static public function create(key:Any, val:Any):MapEntry {
		return new MapEntry(key, val);
	}

	public function new(key:Any, val:Any) {
		this._key = key;
		this._val = val;
	}

	override public function key():Any {
		return _key;
	}

	override public function val():Any {
		return _val;
	}

	public function getKey():Any {
		return key();
	}

	public function getValue():Any {
		return val();
	}
}
