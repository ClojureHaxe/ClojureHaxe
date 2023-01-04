package lang;

class PersistentTreeSet extends APersistentSet implements IObj implements Reversible implements Sorted {
	static public final EMPTY:PersistentTreeSet = new PersistentTreeSet(null, PersistentTreeMap.EMPTY);

	final _meta:IPersistentMap;

	static public function create(items:ISeq):PersistentTreeSet {
		var ret:PersistentTreeSet = EMPTY;

		while (items != null) {
			ret = cast ret.cons(items.first());
			items = items.next();
		}
		return ret;
	}

	static public function create2(comp:Comparator, items:ISeq):PersistentTreeSet {
		var ret:PersistentTreeSet = new PersistentTreeSet(null, PersistentTreeMap.create2(null, comp));
		while (items != null) {
			ret = cast ret.cons(items.first());
			items = items.next();
		}
		return ret;
	}

	public function new(meta:IPersistentMap, impl:IPersistentMap) {
		super(impl);
		this._meta = meta;
	}

	override public function equals(obj:Any):Bool {
		try {
			return super.equals(obj);
		} catch (e) {
			return false;
		}
	}

	override public function equiv(obj:Any):Bool {
		try {
			return super.equiv(obj);
		} catch (e) {
			return false;
		}
	}

	public function disjoin(key:Any):IPersistentSet {
		if (contains(key))
			return new PersistentTreeSet(meta(), impl.without(key));
		return this;
	}

	public function cons(o:Any):IPersistentSet {
		if (contains(o))
			return this;
		return new PersistentTreeSet(meta(), cast impl.assoc(o, o));
	}

	public function empty():IPersistentCollection {
		return new PersistentTreeSet(meta(), cast(impl.empty(), PersistentTreeMap));
	}

	public function rseq():ISeq {
		return APersistentMap.KeySeq.create(cast(impl, Reversible).rseq());
	}

	public function withMeta(meta:IPersistentMap):PersistentTreeSet {
		if (this.meta() == meta)
			return this;
		return new PersistentTreeSet(meta, impl);
	}

	public function comparator():Comparator {
		return cast(impl, Sorted).comparator();
	}

	public function entryKey(entry:Any):Any {
		return entry;
	}

	public function seq1(ascending:Bool):ISeq {
		var m:PersistentTreeMap = cast(impl, PersistentTreeMap);
		return RT.keys(m.seq1(ascending));
	}

	public function seqFrom(key:Any, ascending:Bool):ISeq {
		var m:PersistentTreeMap = cast(impl, PersistentTreeMap);
		return RT.keys(m.seqFrom(key, ascending));
	}

	public function meta():IPersistentMap {
		return _meta;
	}
}
