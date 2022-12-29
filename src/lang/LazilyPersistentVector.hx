package lang;

import haxe.ds.Vector;
import haxe.exceptions.ArgumentException;

class LazilyPersistentVector {
	static public function createOwningArray(items:Array<Any>):IPersistentVector {
		return PersistentVector.createFromIterator(items.iterator());
	}

	static public function createOwningVector(items:Vector<Any>):IPersistentVector {
		if (items.length <= 32)
			return new PersistentVector(items.length, 5, PersistentVector.EMPTY_NODE, items);
		return PersistentVector.createFromISeq(RT.seq(items));
	}

	static public function createOwning(...items:Any):IPersistentVector {
		return PersistentVector.createFromIterator(items.iterator());
	}

	/*static function fcount(c:Any):Int {
		if (U.instanceof(c, Counted))
			return cast(c, Counted).count();

		return ((Collection) c).size();
	}*/
	static public function create(obj:Any):IPersistentVector {
		//   if((obj instanceof Counted || obj instanceof RandomAccess)
		//      && fcount(obj) <= Tuple.MAX_SIZE)
		//        return Tuple.createFromColl(obj);
		//   else
		if (U.instanceof(obj, IReduceInit))
			return PersistentVector.createFromReduceInit(cast(obj, IReduceInit));
		else if (U.instanceof(obj, ISeq))
			return PersistentVector.createFromISeq(RT.seq(obj));
		else if (U.isIterable(obj))
			return PersistentVector.createFromIterator(U.getIterator(obj));
		throw new ArgumentException("Don't know how to make PersistentVector from: " + obj);
		// TODO:
		/*else
			return createOwning(RT.toArray(obj)); */
	}
}
