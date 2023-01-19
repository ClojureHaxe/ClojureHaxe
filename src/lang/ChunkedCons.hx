package lang;

class ChunkedCons extends ASeq implements IChunkedSeq {
	// private static final long serialVersionUID = 2773920188566401743L;
	var chunk:IChunk;
	var _more:ISeq;

	public function new(chunk:IChunk, more:ISeq, ?meta:IPersistentMap = null) {
		super(meta);
		this.chunk = chunk;
		this._more = more;
	}

	public function withMeta(meta:IPersistentMap):Obj {
		if (meta != _meta)
			return new ChunkedCons(chunk, _more, meta);
		return this;
	}

	public function first():Any {
		return chunk.nth(0);
	}

	public function next():ISeq {
		if (chunk.count() > 1)
			return new ChunkedCons(chunk.dropFirst(), _more);
		return chunkedNext();
	}

	override public function more():ISeq {
		if (chunk.count() > 1)
			return new ChunkedCons(chunk.dropFirst(), _more);
		if (_more == null)
			return PersistentList.EMPTY;
		return _more;
	}

	public function chunkedFirst():IChunk {
		return chunk;
	}

	public function chunkedNext():ISeq {
		return chunkedMore().seq();
	}

	public function chunkedMore():ISeq {
		if (_more == null)
			return PersistentList.EMPTY;
		return _more;
	}
}
