package lang;

import lang.exceptions.NoSuchElementException;

class SeqIterator {
	static final START:Any = U.object();

	var seq:Any;
	var _next:Any;

	public function new(o:Any) {
		seq = START;
		_next = o;
	}

	public function hasNext():Bool {
		if (seq == START) {
			seq = null;
			_next = RT.seq(_next);
		} else if (seq == _next)
			_next = RT.next(seq);
		return _next != null;
	}

	public function next():Any {
		if (!hasNext())
			throw new NoSuchElementException();
		seq = _next;
		return RT.first(_next);
	}
}
