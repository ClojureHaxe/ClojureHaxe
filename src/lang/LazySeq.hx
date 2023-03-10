package lang;

import haxe.ds.Vector;
import lang.exceptions.UnsupportedOperationException;

final class LazySeq extends Obj implements ISeq implements Sequential implements IPending implements IHashEq // implements List
implements Collection {
	// private static final long serialVersionUID = 7700080124382322592L;
	private var fn:IFn;
	private var sv:Any;
	private var s:ISeq;

	public static function createFromFn(fn:IFn) {
		return new LazySeq(null, null, fn);
	}

	private function new(meta:IPersistentMap, s:ISeq, ?fn = null) {
		super(meta);
		this.fn = fn;
		this.s = s;
	}

	public function withMeta(meta:IPersistentMap):Obj {
		if (super.meta() == meta)
			return this;
		return new LazySeq(meta, seq());
	}

	// TODO: syncrhonized
	final public function sval():Any {
		if (fn != null) {
			sv = fn.invoke0();
			fn = null;
		}
		if (sv != null)
			return sv;
		return s;
	}

	// TODO: syncrhonized
	final public function seq():ISeq {
		sval();
		if (sv != null) {
			var ls:Any = sv;
			sv = null;
			while (U.instanceof(ls, LazySeq)) {
				ls = (cast ls).sval();
			}
			s = RT.seq(ls);
		}
		return s;
	}

	public function count():Int {
		var c:Int = 0;
		var s:ISeq = seq();
		while (s != null) {
			++c;
			s = s.next();
		}
		return c;
	}

	public function first():Any {
		seq();
		if (s == null)
			return null;
		return s.first();
	}

	public function next():ISeq {
		seq();
		if (s == null)
			return null;
		return s.next();
	}

	public function more():ISeq {
		seq();
		if (s == null)
			return PersistentList.EMPTY;
		return s.more();
	}

	public function cons(o:Any):ISeq {
		return RT.cons(o, seq());
	}

	public function empty():IPersistentCollection {
		return PersistentList.EMPTY;
	}

	public function equiv(o:Any):Bool {
		var s:ISeq = seq();
		if (s != null)
			return s.equiv(o);
		else
			return U.instanceof(o, Sequential) || U.instanceof(o, List) && RT.seq(o) == null;
	}

	public function hashCode():Int {
		var s:ISeq = seq();
		if (s == null)
			return 1;
		return Util.hash(s);
	}

	public function hasheq():Int {
		return Murmur3.hashOrdered(this);
	}

	public function equals(o:Any):Bool {
		var s:ISeq = seq();
		if (s != null)
			// TODO: provide equals
			return s == o;
		// return s.equals(o);
		else
			return U.instanceof(o, Sequential) || U.instanceof(o, List) && RT.seq(o) == null;
	}

	// java.util.Collection implementation

	public function toArray():Vector<Any> {
		return RT.seqToArray(seq());
	}

	public function add(o:Any):Bool {
		throw new UnsupportedOperationException();
	}

	public function remove(o:Any):Bool {
		throw new UnsupportedOperationException();
	}

	public function addAll(c:Collection):Bool {
		throw new UnsupportedOperationException();
	}

	public function clear() {
		throw new UnsupportedOperationException();
	}

	public function retainAll(c:Collection):Bool {
		throw new UnsupportedOperationException();
	}

	public function removeAll(c:Collection):Bool {
		throw new UnsupportedOperationException();
	}

	public function containsAll(c:Collection):Bool {
		for (o in U.getIterator(c)) {
			if (!contains(o))
				return false;
		}
		return true;
	}

	/*public function toArray(a:Vector<Any>):Vector<Any> {
		return RT.seqToPassedArray(seq(), a);
	}*/
	public function size():Int {
		return count();
	}

	public function isEmpty():Bool {
		return seq() == null;
	}

	public function contains(o:Any):Bool {
		var s:ISeq = seq();
		while (s != null) {
			if (Util.equiv(s.first(), o))
				return true;
			s = s.next();
		}
		return false;
	}

	public function iterator():Iterator<Any> {
		return new SeqIterator(this);
	}

	/*
		//////////// List stuff /////////////////
		private List reify() {
			return new ArrayList(this);
		}

		public List subList(int fromIndex, int toIndex) {
			return reify().subList(fromIndex, toIndex);
		}

		public Object set(int index, Object element) {
			throw new UnsupportedOperationException();
		}

		public Object remove(int index) {
			throw new UnsupportedOperationException();
		}

		public int indexOf(Object o) {
			ISeq s = seq();
			for (int i = 0; s != null; s = s.next(), i++) {
				if (Util.equiv(s.first(), o))
					return i;
			}
			return -1;
		}

		public int lastIndexOf(Object o) {
			return reify().lastIndexOf(o);
		}

		public ListIterator listIterator() {
			return reify().listIterator();
		}

		public ListIterator listIterator(int index) {
			return reify().listIterator(index);
		}

		public Object get(int index) {
			return RT.nth(this, index);
		}

		public void add(int index, Object element) {
			throw new UnsupportedOperationException();
		}

		public boolean addAll(int index, Collection c) {
			throw new UnsupportedOperationException();
		}


		synchronized public boolean isRealized() {
			return fn == null;
		}

	 */
	// TODO: sunchronized
	public function isRealized():Bool {
		return fn == null;
	}
}
