package lang;

final class Cons extends ASeq {
	private final _first:Any;
	private final _more:ISeq;

	public function new(first:Any, _more:ISeq, ?meta:IPersistentMap = null) {
		super(meta);
		this._first = first;
		this._more = _more;
	}

	override public function first():Any {
		return _first;
	}

	override public function next():ISeq {
		return more().seq();
	}

	override public function more():ISeq {
		if (_more == null)
			return PersistentList.EMPTY;
		return _more;
	}

	override public function count():Int {
		return 1 + RT.count(_more);
	}

	override  public function withMeta(meta:IPersistentMap):Cons {
		if (super.meta() == meta)
			return this;
		return new Cons(_first, _more, meta);
	}
}
