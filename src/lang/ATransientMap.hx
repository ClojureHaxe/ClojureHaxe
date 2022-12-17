package lang;

import lang.exceptions.IllegalArgumentException;

abstract class ATransientMap extends AFn implements ITransientMap implements ITransientAssociative2 {
	abstract public function ensureEditable():Void;

	abstract public function doAssoc(key:Any, val:Any):ITransientMap;

	abstract public function doWithout(key:Any):ITransientMap;

	abstract public function doValAt(key:Any, notFound:Any):Any;

	abstract public function doCount():Int;

	abstract public function doPersistent():IPersistentMap;

	public function conj(o:Any):ITransientMap {
		ensureEditable();
		if (U.instanceof(o, Map.Entry)) {
			var e:Map.Entry = cast o;
			return assoc(e.getKey(), e.getValue());
		} else if (U.instanceof(o, IPersistentVector)) {
			var v:IPersistentVector = cast o;
			if (v.count() != 2)
				throw new IllegalArgumentException("Vector arg to map conj must be a pair");
			return assoc(v.nth(0), v.nth(1));
		}

		var ret:ITransientMap = this;
		var es:ISeq = RT.seq(o);
		while (es != null) {
			var e:Map.Entry = cast es.first();
			ret = ret.assoc(e.getKey(), e.getValue());
			es = es.next();
		}
		return ret;
	}

	override public final function invoke1(arg1:Any):Any {
		return valAt(arg1);
	}

	override public final function invoke2(arg1:Any, notFound:Any) {
		return valAt(arg1, notFound);
	}

	// public final function valAt(key:Any):Any {
	//     return valAt(key, null);
	// }

	public final function assoc(key:Any, val:Any):ITransientMap {
		ensureEditable();
		return doAssoc(key, val);
	}

	public final function without(key:Any):ITransientMap {
		ensureEditable();
		return doWithout(key);
	}

	public final function persistent():IPersistentMap {
		ensureEditable();
		return doPersistent();
	}

	public final function valAt(key:Any, ?notFound:Any = null):Any {
		ensureEditable();
		return doValAt(key, notFound);
	}

	private static final NOT_FOUND:Any = new ATransientHashMapNotFound();

	public final function containsKey(key:Any):Bool {
		return valAt(key, NOT_FOUND) != NOT_FOUND;
	}

	public final function entryAt(key:Any):IMapEntry {
		var v:Any = valAt(key, NOT_FOUND);
		if (v != NOT_FOUND)
			return MapEntry.create(key, v);
		return null;
	}

	public final function count():Int {
		ensureEditable();
		return doCount();
	}
}

class ATransientHashMapNotFound {
	public function new() {}
}
