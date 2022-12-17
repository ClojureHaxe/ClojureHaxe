package lang;

import lang.exceptions.IllegalArgumentException;

class PersistentHashSet extends APersistentSet implements IObj implements IEditableCollection {
	// TOOD: remove cast
	static public final EMPTY:PersistentHashSet = new PersistentHashSet(null, cast PersistentHashMap.EMPTY);

	final _meta:IPersistentMap;

	public static function create(...init:Any):PersistentHashSet {
		var ret:ITransientSet = cast EMPTY.asTransient();
		var i:Int = 0;
		while (i < init.length) {
			ret = cast(ret.conj(init[i]), ITransientSet);
			i++;
		}
		return cast ret.persistent();
	}

	public static function createFromList(init:List<Any>):PersistentHashSet {
		var ret:ITransientSet = cast EMPTY.asTransient();
		for (key in init) {
			ret = cast ret.conj(key);
		}
		return cast ret.persistent();
	}

	static public function createFromISeq(items:ISeq):PersistentHashSet {
		var ret:ITransientSet = cast EMPTY.asTransient();
		while (items != null) {
			ret = cast ret.conj(items.first());
			items = items.next();
		}
		return cast ret.persistent();
	}

	public static function createWithCheck(...init:Any):PersistentHashSet {
		var ret:ITransientSet = cast EMPTY.asTransient();
		var i:Int = 0;
		while (i < init.length) {
			ret = cast ret.conj(init[i]);
			if (ret.count() != i + 1)
				throw new IllegalArgumentException("Duplicate key: " + init[i]);
			i++;
		}
		return cast ret.persistent();
	}

	public static function createWithCheckFromList(init:List<Any>):PersistentHashSet {
		var ret:ITransientSet = cast EMPTY.asTransient();
		var i:Int = 0;
		for (key in init) {
			ret = cast ret.conj(key);
			if (ret.count() != i + 1)
				throw new IllegalArgumentException("Duplicate key: " + key);
			++i;
		}
		return cast ret.persistent();
	}

	static public function createWithCheckFromISeq(items:ISeq):PersistentHashSet {
		var ret:ITransientSet = cast EMPTY.asTransient();
		var i:Int = 0;
		while (items != null) {
			ret = cast ret.conj(items.first());
			if (ret.count() != i + 1)
				throw new IllegalArgumentException("Duplicate key: " + items.first());

			items = items.next();
			++i;
		}
		return cast ret.persistent();
	}

	public function new(meta:IPersistentMap, impl:IPersistentMap) {
		super(impl);
		this._meta = meta;
	}

	public function disjoin(key:Any):IPersistentSet {
		if (contains(key))
			return new PersistentHashSet(meta(), impl.without(key));
		return this;
	}

	public function cons(o:Any):IPersistentSet {
		if (contains(o))
			return this;
		return new PersistentHashSet(meta(), cast impl.assoc(o, o));
	}

	public function empty():IPersistentCollection {
		return EMPTY.withMeta(meta());
	}

	public function withMeta(meta:IPersistentMap):PersistentHashSet {
		if (this.meta() == meta)
			return this;
		return new PersistentHashSet(meta, impl);
	}

	public function asTransient():ITransientCollection {
		// TODO: Fix
		//return new TransientHashSet(cast(impl, PersistentHashMap).asTransient());
		return null;
	}

	public function meta():IPersistentMap {
		return _meta;
	}
}

class TransientHashSet extends ATransientSet {
	public function new(impl:ITransientMap) {
		super(impl);
	}

	public function persistent():IPersistentCollection {
		return new PersistentHashSet(null, cast impl.persistent());
	}
}
