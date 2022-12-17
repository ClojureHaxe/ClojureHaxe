package lang;

import lang.exceptions.NoSuchElementException;

class SeqIterator {
	static final START:Any = new SeqIteratorStart();

	var seq:Any;
	var _next:Any;

	public function new(o:Any) {
		seq = START;
		_next = o;
	}

	// preserved for binary compatibility

	/*public SeqIterator(ISeq o) {
		seq = START;
		next = o;
	}*/
	public function hasNext():Bool {
		if (seq == START) {
			seq = null;
			_next = RT.seq(next);
		} else if (seq == next)
			_next = RT.next(seq);
		return next != null;
	}

	public function next():Any {
		if (!hasNext())
			throw new NoSuchElementException();
		seq = next;
		return RT.first(next);
	}
}

class SeqIteratorStart {
	public function new() {}
}
