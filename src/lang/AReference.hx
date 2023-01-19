package lang;

class AReference extends AFn implements IReference {
	private var _meta:IPersistentMap;

	public function new(?meta:IPersistentMap) {
		_meta = meta;
	}

	/*@:synchronized*/
	public function meta():IPersistentMap {
		return _meta;
	}

	/*@:synchronized*/
	public function alterMeta(alter:IFn, args:ISeq):IPersistentMap {
		_meta = cast(alter.applyTo(new Cons(_meta, args)), IPersistentMap);
		return _meta;
	}

	/*@:synchronized*/
	public function resetMeta(m:IPersistentMap):IPersistentMap {
		_meta = m;
		return m;
	}
}
