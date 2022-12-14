package lang;

import lang.exceptions.UnsupportedOperationException;
import lang.exceptions.IndexOutOfBoundsException;

abstract class AMapEntry extends APersistentVector implements IMapEntry {
	override public function nth1(i:Int):Any {
		if (i == 0)
			return key();
		else if (i == 1)
			return val();
		else
			throw new IndexOutOfBoundsException();
	}

	public function key():Any {
		throw new UnsupportedOperationException();
	}

	public function val():Any {
		throw new UnsupportedOperationException();
	}

	private function asVector():IPersistentVector {
		// TODO:
		// return LazilyPersistentVector.createOwning(key(), val());
		return null;
	}

	override public function assocN(i:Int, val:Any):IPersistentVector {
		return asVector().assocN(i, val);
	}

	override public function count():Int {
		return 2;
	}

	override public function seq():ISeq {
		return asVector().seq();
	}

	override public function cons(o:Any):IPersistentVector {
		return asVector().cons(o);
	}

	override public function empty():IPersistentCollection {
		return null;
	}

	override public function pop():IPersistentStack {
		// return LazilyPersistentVector.createOwning(key());
		return null;
	}

	public function setValue(value:Any):Any {
		throw new UnsupportedOperationException();
	}
}
