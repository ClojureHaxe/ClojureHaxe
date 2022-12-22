package lang;

import lang.exceptions.IllegalStateException;

abstract class ARef extends AReference implements IRef {
	@:volatile var validator:IFn = null;
	@:volatile var watches:IPersistentMap = PersistentHashMap.EMPTY;

	public function new(?meta:IPersistentMap = null) {
		super(meta);
	}

	private function validate(vf:IFn, val:Any) {
		try {
			if (vf != null && !RT.booleanCast(vf.invoke(val)))
				throw new IllegalStateException("Invalid reference state");
		} catch (e) {
			throw new IllegalStateException("Invalid reference state", e);
		}
	}

	private function validateVal(val) {
		validate(validator, val);
	}

	private function setValidator(vf:IFn) {
		validate(vf, deref());
		validator = vf;
	}

	private function getValidator():IFn {
		return validator;
	}

	private function getWatches():IPersistentMap {
		return watches;
	}

	/*@:synchronized */
	private function addWatch(key:Any, callback:IFn):IRef {
		watches = cast watches.assoc(key, callback);
		return this;
	}

	/*@:synchronized*/
	private function removeWatch(key:Any):IRef {
		watches = watches.without(key);
		return this;
	}

	public function notifyWatches(oldval:Any, newval:Any) {
		var ws:IPersistentMap = watches;
		if (ws.count() > 0) {
			var s:ISeq = ws.seq();
			while (s != null) {
				var e:Map.Entry = cast(s.first(), Map.Entry);
				var fn:IFn = cast e.getValue();
				if (fn != null)
					fn.invoke4(e.getKey(), this, oldval, newval);
				s = s.next();
			}
		}
	}
}
