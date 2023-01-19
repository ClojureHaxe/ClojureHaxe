package lang;

import lang.exceptions.IllegalArgumentException;
import lang.exceptions.NoSuchElementException;
import lang.exceptions.IllegalAccessError;
import haxe.ds.Vector;
import haxe.Rest;

class PersistentArrayMap extends APersistentMap implements IObj implements IEditableCollection implements IMapIterable implements IKVReduce implements IDrop {
	var array:Vector<Any>;

	public static final HASHTABLE_THRESHOLD:Int = 16;

	public static final EMPTY:PersistentArrayMap = PersistentArrayMap.createEmpty();

	private var _meta:IPersistentMap;

	// TODO: from map

	/*static public  create( other:Map):IPersistentMap {
		var ret:ITransientMap = EMPTY.asTransient();
		for ( o in other.entrySet()) {
			var e:Map.Entry = cast o;
			ret = ret.assoc(e.getKey(), e.getValue());
		}
		return ret.persistent();
	}*/
	static public function createEmpty():PersistentArrayMap {
		return new PersistentArrayMap(null, new Vector<Any>(0));
	}

	public function withMeta(meta:IPersistentMap):PersistentArrayMap {
		if (this.meta() == meta)
			return this;
		return new PersistentArrayMap(meta, array);
	}

	private function createInternal(init:Vector<Any>):PersistentArrayMap {
		return new PersistentArrayMap(this.meta(), init);
	}

	static public function create(...init:Any):PersistentArrayMap {
		var v:Vector<Any> = new Vector<Any>(init.length);
		var i:Int = 0;
		while (i < init.length) {
			v[i] = init[i];
			i++;
		}
		return new PersistentArrayMap(null, v);
	}

	private function createHT(init:Vector<Any>):IPersistentMap {
		return PersistentHashMap.create(meta(), init);
	}

	static public function createWithCheck(...init):PersistentArrayMap {
		var i:Int = 0;
		var v:Vector<Any> = new Vector<Any>(init.length);
		while (i < init.length) {
			var j:Int = i + 2;
			while (j < init.length) {
				if (equalKey(init[i], init[j]))
					throw new IllegalArgumentException("Duplicate key: " + init[i]);
				j += 2;
			}
			v[i] = init[i];
			v[i + 1] = init[i + 1];
			i += 2;
		}
		return PersistentArrayMap.createFromArray(v);
	}

	static public function createAsIfByAssoc(init:Vector<Any>):PersistentArrayMap {
		var complexPath:Bool, hasTrailing:Bool;
		complexPath = hasTrailing = ((init.length & 1) == 1);
		var i:Int = 0;

		while ((i < init.length) && !complexPath) {
			var j:Int = 0;
			while (j < i) {
				if (equalKey(init[i], init[j])) {
					complexPath = true;
					break;
				}
				j += 2;
			}
			i += 2;
		}

		if (complexPath)
			return createAsIfByAssocComplexPath(init, hasTrailing);

		return PersistentArrayMap.createFromArray(init);
	}

	private static function growSeedArray(seed:Vector<Any>, trailing:IPersistentCollection):Vector<Any> {
		var extraKVs:ISeq = trailing.seq();
		var seedCount:Int = seed.length - 1;
		var result:Vector<Any> = U.vectorCopyOf(seed, seedCount + (trailing.count() * 2));
		var i:Int = seedCount;
		while (extraKVs != null) {
			var e:Map.Entry = cast extraKVs.first();
			result[i] = e.getKey();
			result[i + 1] = e.getValue();
			extraKVs = extraKVs.next();
			i += 2;
		}
		return result;
	}

	private static function createAsIfByAssocComplexPath(init:Vector<Any>, hasTrailing:Bool):PersistentArrayMap {
		if (hasTrailing) {
			var trailing:IPersistentCollection = PersistentArrayMap.EMPTY.cons(init[init.length - 1]);
			init = growSeedArray(init, trailing);
		}

		// If this looks like it is doing busy-work, it is because it
		// is achieving these goals: O(n^2) run time like
		// createWithCheck(), never modify init arg, and only
		// allocate memory if there are duplicate keys.
		var n:Int = 0;
		var i:Int = 0;
		while (i < init.length) {
			var duplicateKey:Bool = false;
			var j:Int = 0;
			while (j < i) {
				if (equalKey(init[i], init[j])) {
					duplicateKey = true;
					break;
				}
				j += 2;
			}
			if (!duplicateKey)
				n += 2;
			i += 2;
		}
		if (n < init.length) {
			// Create a new shorter array with unique keys, and
			// the last value associated with each key.  To behave
			// like assoc, the first occurrence of each key must
			// be used, since its metadata may be different than
			// later equal keys.
			var nodups:Vector<Any> = new Vector<Any>(n);
			var m:Int = 0;
			var i:Int = 0;
			while (i < init.length) {
				var duplicateKey:Bool = false;
				var j:Int = 0;
				while (j < m) {
					if (equalKey(init[i], nodups[j])) {
						duplicateKey = true;
						break;
					}
					j += 2;
				}
				if (!duplicateKey) {
					var j:Int = init.length - 2;
					while (j >= i) {
						if (equalKey(init[i], init[j])) {
							break;
						}
						j -= 2;
					}
					nodups[m] = init[i];
					nodups[m + 1] = init[j + 1];
					m += 2;
				}
				i += 2;
			}
			if (m != n)
				throw new IllegalArgumentException("Internal error: m=" + m);
			init = nodups;
		}
		return PersistentArrayMap.createFromArray(init);
	}

	static public function createFromArray(init:Vector<Any>):PersistentArrayMap {
		return new PersistentArrayMap(null, init);
	}

	public function new(meta:IPersistentMap, init:Vector<Any>) {
		this._meta = meta;
		this.array = init;
	}

	public function count():Int {
		return array.length >> 1;
	}

	public function containsKey(key:Any):Bool {
		return indexOf(key) >= 0;
	}

	public function entryAt(key:Any):IMapEntry {
		var i:Int = indexOf(key);
		if (i >= 0)
			return MapEntry.create(array[i], array[i + 1]);
		return null;
	}

	public function assocEx(key:Any, val:Any):IPersistentMap {
		var i:Int = indexOf(key);
		var newArray:Vector<Any>;
		if (i >= 0) {
			throw Util.runtimeException("Key already present");
		} else // didn't have key, grow
		{
			if (array.length >= HASHTABLE_THRESHOLD)
				return createHT(array).assocEx(key, val);
			newArray = new Vector<Any>(array.length + 2);
			if (array.length > 0)
				U.vectorCopy(array, 0, newArray, 2, array.length);
			newArray[0] = key;
			newArray[1] = val;
		}
		return createInternal(newArray);
	}

	public function assoc(key:Any, val:Any):IPersistentMap {
		var i:Int = indexOf(key);
		var newArray:Vector<Any>;
		if (i >= 0) // already have key, same-sized replacement
		{
			if (array[i + 1] == val) // no change, no op
				return this;
			newArray = array.copy();
			newArray[i + 1] = val;
		} else // didn't have key, grow
		{
			if (array.length >= HASHTABLE_THRESHOLD)
				return cast createHT(array).assoc(key, val);
			newArray = new Vector<Any>(array.length + 2);
			if (array.length > 0)
				U.vectorCopy(array, 0, newArray, 0, array.length);
			newArray[newArray.length - 2] = key;
			newArray[newArray.length - 1] = val;
		}
		return createInternal(newArray);
	}

	public function without(key:Any):IPersistentMap {
		var i:Int = indexOf(key);
		if (i >= 0) // have key, will remove
		{
			var newlen:Int = array.length - 2;
			if (newlen == 0)
				return cast empty();
			var newArray:Vector<Any> = new Vector<Any>(newlen);
			U.vectorCopy(array, 0, newArray, 0, i);
			U.vectorCopy(array, i + 2, newArray, i, newlen - i);
			return createInternal(newArray);
		}
		// don't have key, no op
		return this;
	}

	public function empty():IPersistentMap {
		return cast EMPTY.withMeta(meta());
	}

	final public function valAt(key:Any, ?notFound:Any):Any {
		var i:Int = indexOf(key);
		if (i >= 0)
			return array[i + 1];
		return notFound;
	}

	public function capacity():Int {
		return count();
	}

	private function indexOfObject(key:Any):Int {
		var ep:Util.EquivPred = Util.equivPred(key);
		var i:Int = 0;
		while (i < array.length) {
			if (ep.equiv(key, array[i]))
				return i;
			i += 2;
		}
		return -1;
	}

	private function indexOf(key:Any):Int {
		// TODO: implement keyword properly?
		/*if (U.instanceof(key, Keyword)) {
			var i:Int = 0;
			while (i < array.length) {
				if (key == array[i])
					return i;
				i += 2;
			}
			return -1;
		} else*/
		return indexOfObject(key);
	}

	static public function equalKey(k1:Any, k2:Any):Bool {
		if (U.instanceof(k1, Keyword))
			return k1 == k2;
		return Util.equiv(k1, k2);
	}

	public function iterator():Iterator<Any> {
		return Iter.create(array, APersistentMap.MAKE_ENTRY);
	}

	public function keyIterator():Iterator<Any> {
		return Iter.create(array, APersistentMap.MAKE_KEY);
	}

	public function valIterator():Iterator<Any> {
		return Iter.create(array, APersistentMap.MAKE_VAL);
	}

	public function seq():ISeq {
		if (array.length > 0)
			return new PersistentArraySeq(array, 0);
		return null;
	}

	public function drop(n:Int):Sequential {
		if (array.length > 0) {
			return (cast(seq(), PersistentArraySeq)).drop(n);
		} else {
			return null;
		}
	}

	public function meta():IPersistentMap {
		return _meta;
	}

	// <Seq>
	// <Iter>

	public function kvreduce(f:IFn, init:Any):Any {
		var i:Int = 0;
		while (i < array.length) {
			init = f.invoke3(init, array[i], array[i + 1]);
			if (RT.isReduced(init))
				return cast(init, IDeref).deref();
			i += 2;
		}
		return init;
	}

	public function asTransient():ITransientMap {
		return new TransientArrayMap(array);
	}
}

// Seq =============================================================
class PersistentArraySeq extends ASeq implements Counted implements IReduce implements IDrop {
	var array:Vector<Any>;
	var i:Int = 0;

	public function new(array:Vector<Any>, i:Int, ?meta:IPersistentMap) {
		super(meta);
		this.array = array;
		this.i = i;
	}

	public function first():Any {
		return MapEntry.create(array[i], array[i + 1]);
	}

	public function next():ISeq {
		if (i + 2 < array.length)
			return new PersistentArraySeq(array, i + 2);
		return null;
	}

	override public function count():Int {
		return (array.length - i) >> 1;
	}

	public function drop(n:Int):Sequential {
		if (n < count()) {
			return new PersistentArraySeq(array, i + (2 * n));
		} else {
			return null;
		}
	}

	public function withMeta(meta:IPersistentMap):Obj {
		if (super.meta() == meta)
			return this;
		return new PersistentArraySeq(array, i, meta);
	}

	override public function iterator():Iterator<Any> {
		return new Iter(array, i - 2, APersistentMap.MAKE_ENTRY);
	}

	public function reduce1(f:IFn):Any {
		if (i < array.length) {
			var acc:Any = MapEntry.create(array[i], array[i + 1]);
			var j:Int = i + 2;
			while (j < array.length) {
				// TODO: Check invoke
				acc = f.invoke2(acc, MapEntry.create(array[j], array[j + 1]));
				if (RT.isReduced(acc))
					return cast(acc, IDeref).deref();
				j += 2;
			}
			return acc;
		} else {
			return f.invoke();
		}
	}

	public function reduce2(f:IFn, init:Any):Any {
		var acc:Any = init;
		var j:Int = i;
		while (j < array.length) {
			acc = f.invoke(acc, MapEntry.create(array[j], array[j + 1]));
			if (RT.isReduced(acc))
				return cast(acc, IDeref).deref();
			j += 2;
		}
		return acc;
	}
}

// Iter ==============================================================================
class Iter {
	var f:IFn;
	var array:Vector<Any>;
	var i:Int;

	// for iterator
	static public function create(array:Vector<Any>, f:IFn):Iter {
		return new Iter(array, -2, f);
	}

	// for entryAt
	public function new(array:Vector<Any>, i:Int, f:IFn) {
		this.array = array;
		this.i = i;
		this.f = f;
	}

	public function hasNext():Bool {
		return i < array.length - 2;
	}

	public function next():Any {
		try {
			i += 2;
			return f.invoke2(array[i], array[i + 1]);
		} catch (e) {
			throw new NoSuchElementException();
		}
	}
}

// TransientArrayMap ===========================================
final class TransientArrayMap extends ATransientMap {
	@:volatile var len:Int;
	var array:Vector<Any>;
	@:volatile var owner:Any;

	public function new(array:Vector<Any>) {
		this.owner = this; // this thread, but what the difference
		var l:Int = PersistentArrayMap.HASHTABLE_THRESHOLD > array.length ? PersistentArrayMap.HASHTABLE_THRESHOLD : array.length;
		this.array = new Vector<Any>(l);
		U.vectorCopy(array, 0, this.array, 0, array.length);
		this.len = array.length;
	}

	private function indexOf(key:Any):Int {
		var i:Int = 0;
		while (i < len) {
			if (PersistentArrayMap.equalKey(array[i], key))
				return i;
			i += 2;
		}
		return -1;
	}

	public function doAssoc(key:Any, val:Any):ITransientMap {
		var i:Int = indexOf(key);
		if (i >= 0) // already have key,
		{
			if (array[i + 1] != val) // no change, no op
				array[i + 1] = val;
		} else // didn't have key, grow
		{
			if (len >= array.length)
				return PersistentHashMap.create(array).asTransient().assoc(key, val);
			array[len++] = key;
			array[len++] = val;
		}
		return this;
	}

	public function doWithout(key:Any):ITransientMap {
		var i:Int = indexOf(key);
		if (i >= 0) // have key, will remove
		{
			if (len >= 2) {
				array[i] = array[len - 2];
				array[i + 1] = array[len - 1];
			}
			len -= 2;
		}
		return this;
	}

	public function doValAt(key:Any, notFound:Any):Any {
		var i:Int = indexOf(key);
		if (i >= 0)
			return array[i + 1];
		return notFound;
	}

	public function doCount():Int {
		return len >> 1;
	}

	public function doPersistent():IPersistentMap {
		ensureEditable();
		owner = null;
		var a:Vector<Any> = new Vector<Any>(len);
		U.vectorCopy(array, 0, a, 0, len);
		return PersistentArrayMap.createFromArray(a);
	}

	public function ensureEditable() {
		if (owner == null)
			throw new IllegalAccessError("Transient used after persistent! call");
	}
}
