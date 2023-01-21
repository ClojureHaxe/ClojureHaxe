package lang;

import haxe.Exception;
import lang.exceptions.IllegalArgumentException;
import lang.exceptions.NoSuchElementException;
import lang.exceptions.IllegalAccessError;
import haxe.ds.Vector;
import haxe.Rest;

class PersistentHashMap extends APersistentMap implements IEditableCollection implements IObj implements IMapIterable implements IKVReduce {
	public var _count:Int;
	public var root:INode;
	public var hasNull:Bool;
	public var nullValue:Any;
	public var _meta:IPersistentMap;

	public static final EMPTY:PersistentHashMap = new PersistentHashMap(0, null, false, null);
	private static final NOT_FOUND:Any = new NotFoundMap();

	static public function createFromMap(other:Map<Any, Any>):IPersistentMap {
		var ret:ITransientMap = EMPTY.asTransient();
		for (k => v in other) {
			ret = ret.assoc(k, v);
		}
		return cast ret.persistent();
	}

	public static function create(...init:Any):PersistentHashMap {
		// TODO: bug in HL: SIGNAL 11, segmentation fault if use ITransientMap
		// var ret:ITransientMap = EMPTY.asTransient();
		var ret:TransientHashMap = EMPTY.asTransient();
		var i:Int = 0;
		while (i < init.length) {
			ret = cast ret.assoc(init[i], init[i + 1]);
			i += 2;
		}
		// trace("TRANS:" + ret);
		// var z:PersistentHashMap;
		// var r:IPersistentCollection =( ret.persistent());
		// var r2:PersistentHashMap = cast r;
		// trace("RET:" + r);
		// trace("Hello");
		// return cast(r, PersistentHashMap);
		return cast ret.persistent();
	}

	public static function createWithCheck(...init:Any):PersistentHashMap {
		var ret:ITransientMap = EMPTY.asTransient();
		var i:Int = 0;
		while (i < init.length) {
			ret = ret.assoc(init[i], init[i + 1]);
			if (ret.count() != i / 2 + 1)
				throw new IllegalArgumentException("Duplicate key: " + init[i]);
			i += 2;
		}
		return cast ret.persistent();
	}

	static public function createFromSeq(items:ISeq):PersistentHashMap {
		var ret:ITransientMap = EMPTY.asTransient();
		while (items != null) {
			if (items.next() == null)
				throw new IllegalArgumentException("No value supplied for key: " + items.first());
			var k:Any = items.first();
			items = items.next();
			ret = ret.assoc(k, items.first());
			items = items.next();
		}
		return cast ret.persistent();
	}

	static public function createWithCheckFromSeq(items:ISeq):PersistentHashMap {
		var ret:ITransientMap = EMPTY.asTransient();
		var i:Int = 0;
		while (items != null) {
			if (items.next() == null)
				throw new IllegalArgumentException("No value supplied for key: " + items.first());
			ret = ret.assoc(items.first(), items.next().first());
			if (ret.count() != i + 1)
				throw new IllegalArgumentException("Duplicate key: " + items.first());

			items = items.next().next();
			++i;
		}
		return cast ret.persistent();
	}

	static public function createWithMeta(meta:IPersistentMap, ...init:Any):PersistentHashMap {
		return create(init).withMeta(meta);
	}

	public function new(count:Int, root:INode, hasNull:Bool, nullValue:Any, ?meta:IPersistentMap) {
		this._meta = meta;
		this._count = count;
		this.root = root;
		this.hasNull = hasNull;
		this.nullValue = nullValue;
	}

	static public function hash(k:Any):Int {
		return Util.hasheq(k);
	}

	public function containsKey(key:Any):Bool {
		if (key == null)
			return hasNull;
		return (root != null) ? root.find(0, hash(key), key, NOT_FOUND) != NOT_FOUND : false;
	}

	public function entryAt(key:Any):IMapEntry {
		if (key == null)
			return hasNull ? MapEntry.create(null, nullValue) : null;
		return (root != null) ? root.find(0, hash(key), key) : null;
	}

	public function assoc(key:Any, val:Any):IPersistentMap {
		if (key == null) {
			if (hasNull && val == nullValue)
				return this;
			return new PersistentHashMap(hasNull ? _count : _count + 1, root, true, val, meta());
		}
		var addedLeaf:Box = new Box(null);
		var newroot:INode = (root == null ? BitmapIndexedNode.EMPTY : root).assoc5(0, hash(key), key, val, addedLeaf);
		if (newroot == root)
			return this;
		return new PersistentHashMap(addedLeaf.val == null ? _count : _count + 1, newroot, hasNull, nullValue, meta());
	}

	public function valAt(key:Any, ?notFound:Any = null):Any {
		if (key == null)
			return hasNull ? nullValue : notFound;
		return root != null ? root.find(0, hash(key), key, notFound) : notFound;
	}

	public function assocEx(key:Any, val:Any):IPersistentMap {
		if (containsKey(key))
			throw new Exception("Key already present");
		return assoc(key, val);
	}

	public function without(key:Any):IPersistentMap {
		if (key == null)
			return hasNull ? new PersistentHashMap(_count - 1, root, false, null, meta()) : this;
		if (root == null)
			return this;
		var newroot:INode = root.without3(0, hash(key), key);
		if (newroot == root)
			return this;
		return new PersistentHashMap(_count - 1, newroot, hasNull, nullValue, meta());
	}

	static final EMPTY_ITER:Iterator<Any> = new PersistentHashMapEmptyIterator();

	private function iteratorByFN(f:IFn):Iterator<Any> {
		final rootIter:Iterator<Any> = (root == null) ? EMPTY_ITER : root.iterator(f);
		if (hasNull) {
			return new PersistentHashMapIterator(rootIter, f, nullValue);
		} else
			return rootIter;
	}

	public function iterator():Iterator<Any> {
		return iteratorByFN(APersistentMap.MAKE_ENTRY);
	}

	public function keyIterator():Iterator<Any> {
		return iteratorByFN(APersistentMap.MAKE_KEY);
	}

	public function valIterator():Iterator<Any> {
		return iteratorByFN(APersistentMap.MAKE_VAL);
	}

	public function kvreduce(f:IFn, init:Any):Any {
		init = hasNull ? f.invoke(init, null, nullValue) : init;
		if (RT.isReduced(init))
			return cast(init, IDeref).deref();
		if (root != null) {
			init = root.kvreduce(f, init);
			if (RT.isReduced(init))
				return cast(init, IDeref).deref();
			else
				return init;
		}
		return init;
	}

	// TODO: fold?

	public function count():Int {
		return _count;
	}

	public function seq():ISeq {
		var s:ISeq = root != null ? root.nodeSeq() : null;
		return hasNull ? new Cons(MapEntry.create(null, nullValue), s) : s;
	}

	public function empty():IPersistentCollection {
		return EMPTY.withMeta(meta());
	}

	public static function mask(hash:Int, shift:Int):Int {
		// return ((hash << shift) >>> 27);// & 0x01f;
		return (hash >>> shift) & 0x01f;
	}

	public function withMeta(meta:IPersistentMap):PersistentHashMap {
		if (_meta == meta)
			return this;
		return new PersistentHashMap(_count, root, hasNull, nullValue, meta);
	}

	public function asTransient():TransientHashMap {
		return TransientHashMap.createFromMap(this);
	}

	public function meta():IPersistentMap {
		return _meta;
	}

	public static function cloneAndSetINode(array:Vector<INode>, i:Int, a:INode):Vector<INode> {
		var clone:Vector<INode> = array.copy();
		clone[i] = a;
		return clone;
	}

	public static function cloneAndSetAny(array:Vector<Any>, i:Int, a:Any):Vector<Any> {
		var clone:Vector<Any> = array.copy();
		clone[i] = a;
		return clone;
	}

	public static function cloneAndSet5(array:Vector<Any>, i:Int, a:Any, j:Int, b:Any):Vector<Any> {
		var clone:Vector<Any> = array.copy();
		clone[i] = a;
		clone[j] = b;
		return clone;
	}

	public static function removePair(array:Vector<Any>, i:Int):Vector<Any> {
		var newArray:Vector<Any> = new Vector<Any>(array.length - 2);
		U.vectorCopy(array, 0, newArray, 0, 2 * i);
		U.vectorCopy(array, 2 * (i + 1), newArray, 2 * i, newArray.length - 2 * i);
		return newArray;
	}

	public static function createNode6(shift:Int, key1:Any, val1:Any, key2hash:Int, key2:Any, val2:Any):INode {
		var key1hash:Int = hash(key1);
		if (key1hash == key2hash) {
			var vv:Vector<Any> = new Vector<Any>(4);
			vv[0] = key1;
			vv[1] = val1;
			vv[2] = key2;
			vv[3] = val2;
			return new HashCollisionNode(null, key1hash, 2, vv);
		}
		var addedLeaf:Box = new Box(null);
		var edit:AtomicReference = new AtomicReference();
		return BitmapIndexedNode.EMPTY.assoc6(edit, shift, key1hash, key1, val1, addedLeaf).assoc6(edit, shift, key2hash, key2, val2, addedLeaf);
	}

	public static function createNode7(edit:AtomicReference, shift:Int, key1:Any, val1:Any, key2hash:Int, key2:Any, val2:Any):INode {
		var key1hash:Int = hash(key1);
		if (key1hash == key2hash) {
			var vv:Vector<Any> = new Vector<Any>(4);
			vv[0] = key1;
			vv[1] = val1;
			vv[2] = key2;
			vv[3] = val2;
			return new HashCollisionNode(null, key1hash, 2, vv);
		}
		var addedLeaf:Box = new Box(null);
		return BitmapIndexedNode.EMPTY.assoc6(edit, shift, key1hash, key1, val1, addedLeaf).assoc6(edit, shift, key2hash, key2, val2, addedLeaf);
	}

	public static function bitpos(hash:Int, shift:Int):Int {
		return 1 << mask(hash, shift);
	}
}

// TransientHashMap =============================================================
final class TransientHashMap extends ATransientMap {
	@:volatile var edit:AtomicReference;
	@:volatile var root:INode;
	@:volatile var _count:Int;
	@:volatile var hasNull:Bool;
	@:volatile var nullValue:Any;
	final leafFlag:Box = new Box(null);

	static public function createFromMap(m:PersistentHashMap):TransientHashMap {
		return new TransientHashMap(new AtomicReference(), m.root, m._count, m.hasNull, m.nullValue);
	}

	public function new(edit:AtomicReference, root:INode, count:Int, hasNull:Bool, nullValue:Any) {
		this.edit = edit;
		this.root = root;
		this._count = count;
		this.hasNull = hasNull;
		this.nullValue = nullValue;
	}

	public function doAssoc(key:Any, val:Any):ITransientMap {
		if (key == null) {
			if (this.nullValue != val)
				this.nullValue = val;
			if (!hasNull) {
				this._count++;
				this.hasNull = true;
			}
			return this;
		}
		//		Box leafFlag = new Box(null);
		leafFlag.val = null;
		var n:INode = (root == null ? BitmapIndexedNode.EMPTY : root).assoc6(edit, 0, PersistentHashMap.hash(key), key, val, leafFlag);
		if (n != this.root)
			this.root = n;
		if (leafFlag.val != null)
			this._count++;
		return this;
	}

	public function doWithout(key:Any):ITransientMap {
		if (key == null) {
			if (!hasNull)
				return this;
			hasNull = false;
			nullValue = null;
			this._count--;
			return this;
		}
		if (root == null)
			return this;
		//		Box leafFlag = new Box(null);
		leafFlag.val = null;
		var n:INode = root.without5(edit, 0, PersistentHashMap.hash(key), key, leafFlag);
		if (n != root)
			this.root = n;
		if (leafFlag.val != null)
			this._count--;
		return this;
	}

	public function doPersistent():IPersistentMap {
		edit = null;
		return new PersistentHashMap(_count, root, hasNull, nullValue);
	}

	public function doValAt(key:Any, notFound:Any):Any {
		if (key == null)
			if (hasNull)
				return nullValue;
			else
				return notFound;
		if (root == null)
			return notFound;
		return root.find(0, PersistentHashMap.hash(key), key, notFound);
	}

	public function doCount():Int {
		return _count;
	}

	public function ensureEditable() {
		if (edit == null)
			throw new IllegalAccessError("Transient used after persistent! call");
	}
}

class PersistentHashMapIterator {
	private var seen:Bool = false;
	private var rootIter:Iterator<Any>;
	private var nullValue:Any;
	private var f:IFn;

	public function new(rootIter:Iterator<Any>, f:IFn, nullValue:Any) {
		this.rootIter = rootIter;
		this.nullValue = nullValue;
		this.f = f;
	}

	public function hasNext():Bool {
		if (!seen)
			return true;
		else
			return rootIter.hasNext();
	}

	public function next():Any {
		if (!seen) {
			seen = true;
			return f.invoke2(null, nullValue);
		} else
			return rootIter.next();
	}
}

class PersistentHashMapEmptyIterator {
	public function new() {}

	public function hasNext():Bool {
		return false;
	}

	public function next():Any {
		throw new NoSuchElementException();
		return null;
	}
}

class NotFoundMap {
	public function new() {};
}

// INode ==================================================================================
interface INode {
	public function assoc5(shift:Int, hash:Int, key:Any, val:Any, addedLeaf:Box):INode;

	public function without3(shift:Int, hash:Int, key:Any):INode;

	// public function find(shift:Int, hash:Int, key:Any):IMapEntry;
	public function find(shift:Int, hash:Int, key:Any, ?notFound:Any):Any;

	public function nodeSeq():ISeq;

	public function assoc6(edit:AtomicReference, shift:Int, hash:Int, key:Any, val:Any, addedLeaf:Box):INode;

	public function without5(edit:AtomicReference, shift:Int, hash:Int, key:Any, removedLeaf:Box):INode;

	public function kvreduce(f:IFn, init:Any):Any;

	// TODO: should be?
	// public function fold(combinef:IFn, reducef:IFn, fjtask:IFn, fjfork:IFn, fjjoin:IFn):Any;
	// returns the result of (f [k v]) for each iterated element
	public function iterator(f:IFn):Iterator<Any>;
}

// ArrayNode ==================================================================================
class ArrayNode implements INode {
	var _count:Int;
	var array:Vector<INode>;
	var edit:AtomicReference;

	public function new(edit:AtomicReference, count:Int, array:Vector<INode>) {
		this.array = array;
		this.edit = edit;
		this._count = count;
	}

	public function assoc5(shift:Int, hash:Int, key:Any, val:Any, addedLeaf:Box):INode {
		var idx:Int = PersistentHashMap.mask(hash, shift);
		var node:INode = array[idx];
		if (node == null)
			return new ArrayNode(null, _count + 1,
				PersistentHashMap.cloneAndSetINode(array, idx, BitmapIndexedNode.EMPTY.assoc5(shift + 5, hash, key, val, addedLeaf)));
		var n:INode = node.assoc5(shift + 5, hash, key, val, addedLeaf);
		if (n == node)
			return this;
		return new ArrayNode(null, _count, PersistentHashMap.cloneAndSetINode(array, idx, n));
	}

	public function without3(shift:Int, hash:Int, key:Any):INode {
		var idx:Int = PersistentHashMap.mask(hash, shift);
		var node:INode = array[idx];
		if (node == null)
			return this;
		var n:INode = node.without3(shift + 5, hash, key);
		if (n == node)
			return this;
		if (n == null) {
			if (_count <= 8) // shrink
				return pack(null, idx);
			return new ArrayNode(null, _count - 1, PersistentHashMap.cloneAndSetINode(array, idx, n));
		} else
			return new ArrayNode(null, _count, PersistentHashMap.cloneAndSetINode(array, idx, n));
	}

	public function without5(edit:AtomicReference, shift:Int, hash:Int, key:Any, removedLeaf:Box):INode {
		var idx:Int = PersistentHashMap.mask(hash, shift);
		var node:INode = array[idx];
		if (node == null)
			return this;
		var n:INode = node.without5(edit, shift + 5, hash, key, removedLeaf);
		if (n == node)
			return this;
		if (n == null) {
			if (_count <= 8) // shrink
				return pack(edit, idx);
			var editable:ArrayNode = editAndSet(edit, idx, n);
			editable._count--;
			return editable;
		}
		return editAndSet(edit, idx, n);
	}

	/*public function   find(int shift, int hash, Object key):IMapEntry {
		var idx:Int = mask(hash, shift);
		INode node = array[idx];
		if (node == null)
			return null;
		return node.find(shift + 5, hash, key);
	}*/
	public function find(shift:Int, hash:Int, key:Any, ?notFound:Any = null):Any {
		var idx:Int = PersistentHashMap.mask(hash, shift);
		var node:INode = array[idx];
		if (node == null)
			return notFound;
		return node.find(shift + 5, hash, key, notFound);
	}

	public function nodeSeq():ISeq {
		return ArrayNodeSeq.createFromNodes(array);
	}

	public function iterator(f:IFn):Iterator<Any> {
		return new ArrayNodeIter(array, f);
	}

	public function kvreduce(f:IFn, init:Any):Any {
		for (node in array) {
			if (node != null) {
				init = node.kvreduce(f, init);
				if (RT.isReduced(init))
					return init;
			}
		}
		return init;
	}

	/*
		public Object fold(final IFn combinef, final IFn reducef,
						   final IFn fjtask, final IFn fjfork, final IFn fjjoin) {
			List<Callable> tasks = new ArrayList();
			for (final INode node : array) {
				if (node != null) {
					tasks.add(new Callable() {
						public Object call() throws Exception {
							return node.fold(combinef, reducef, fjtask, fjfork, fjjoin);
						}
					});
				}
			}

			return foldTasks(tasks, combinef, fjtask, fjfork, fjjoin);
		}
	 */
	/*
		static public Object foldTasks(List<Callable> tasks, final IFn combinef,
									   final IFn fjtask, final IFn fjfork, final IFn fjjoin) {

			if (tasks.isEmpty())
				return combinef.invoke();

			if (tasks.size() == 1) {
				Object ret = null;
				try {
					return tasks.get(0).call();
				} catch (Exception e) {
					throw Util.sneakyThrow(e);
				}
			}

			List<Callable> t1 = tasks.subList(0, tasks.size() / 2);
			final List<Callable> t2 = tasks.subList(tasks.size() / 2, tasks.size());

			Object forked = fjfork.invoke(fjtask.invoke(new Callable() {
				public Object call() throws Exception {
					return foldTasks(t2, combinef, fjtask, fjfork, fjjoin);
				}
			}));

			return combinef.invoke(foldTasks(t1, combinef, fjtask, fjfork, fjjoin), fjjoin.invoke(forked));
		}
	 */
	private function ensureEditable(edit:AtomicReference):ArrayNode {
		if (this.edit == edit)
			return this;
		return new ArrayNode(edit, _count, this.array.copy());
	}

	private function editAndSet(edit:AtomicReference, i:Int, n:INode):ArrayNode {
		var editable:ArrayNode = ensureEditable(edit);
		editable.array[i] = n;
		return editable;
	}

	private function pack(edit:AtomicReference, idx:Int):INode {
		var newArray:Vector<Any> = new Vector<Any>(2 * (_count - 1));
		var j:Int = 1;
		var bitmap:Int = 0;
		var i:Int = 0;
		while (i < idx) {
			if (array[i] != null) {
				newArray[j] = array[i];
				bitmap |= 1 << i;
				j += 2;
			}
			i++;
		}
		i = idx + 1;
		while (i < array.length) {
			if (array[i] != null) {
				newArray[j] = array[i];
				bitmap |= 1 << i;
				j += 2;
			}
			i++;
		}
		return new BitmapIndexedNode(edit, bitmap, newArray);
	}

	public function assoc6(edit:AtomicReference, shift:Int, hash:Int, key:Any, val:Any, addedLeaf:Box):INode {
		var idx:Int = PersistentHashMap.mask(hash, shift);
		var node:INode = array[idx];
		if (node == null) {
			var editable:ArrayNode = editAndSet(edit, idx, BitmapIndexedNode.EMPTY.assoc6(edit, shift + 5, hash, key, val, addedLeaf));
			editable._count++;
			return editable;
		}
		var n:INode = node.assoc6(edit, shift + 5, hash, key, val, addedLeaf);
		if (n == node)
			return this;
		return editAndSet(edit, idx, n);
	}
}

// ArrayNodeIter ===============================================================
class ArrayNodeIter {
	private var array:Vector<INode>;
	private var f:IFn;
	private var i:Int = 0;
	private var nestedIter:Iterator<Any>;

	public function new(array:Vector<INode>, f:IFn) {
		this.array = array;
		this.f = f;
	}

	public function hasNext():Bool {
		while (true) {
			if (nestedIter != null)
				if (nestedIter.hasNext())
					return true;
				else
					nestedIter = null;

			if (i < array.length) {
				var node:INode = array[i++];
				if (node != null)
					nestedIter = node.iterator(f);
			} else
				return false;
		}
	}

	public function next():Any {
		if (hasNext())
			return nestedIter.next();
		else
			throw new NoSuchElementException();
	}
	/*public void remove() {
		throw new UnsupportedOperationException();
	}*/
}

/// ArrayNodeSeq =====================================================================================================
class ArrayNodeSeq extends ASeq {
	var nodes:Vector<INode>;
	var i:Int;
	var s:ISeq;

	public static function createFromNodes(nodes:Vector<INode>):ISeq {
		return create(null, nodes, 0, null);
	}

	private static function create(meta:IPersistentMap, nodes:Vector<INode>, i:Int, s:ISeq):ISeq {
		if (s != null)
			return new ArrayNodeSeq(meta, nodes, i, s);
		var j:Int = i;
		while (j < nodes.length) {
			if (nodes[j] != null) {
				var ns:ISeq = nodes[j].nodeSeq();
				if (ns != null)
					return new ArrayNodeSeq(meta, nodes, j + 1, ns);
			}
			j++;
		}
		return null;
	}

	private function new(meta:IPersistentMap, nodes:Vector<INode>, i:Int, s:ISeq) {
		super(meta);
		this.nodes = nodes;
		this.i = i;
		this.s = s;
	}

	public function withMeta(meta:IPersistentMap):Obj {
		if (super.meta() == meta)
			return this;
		return new ArrayNodeSeq(meta, nodes, i, s);
	}

	public function first():Any {
		return s.first();
	}

	public function next():ISeq {
		return create(null, nodes, i, s.next());
	}
}

// BitmapIndexedNode ==============================================================================
class BitmapIndexedNode implements INode {
	public static final EMPTY:BitmapIndexedNode = new BitmapIndexedNode(null, 0, new Vector<Any>(0));

	var bitmap:Int;
	var array:Vector<Any>;
	var edit:AtomicReference;

	// TODO: Move to utils
	public static function bitCount(i:Int):Int {
		i -= i >>> 1 & 1431655765;
		i = (i & 858993459) + (i >>> 2 & 858993459);
		i = i + (i >>> 4) & 252645135;
		i += i >>> 8;
		i += i >>> 16;
		return i & 63;
	}

	public final function index(bit:Int):Int {
		return bitCount(bitmap & (bit - 1));
	}

	public function new(edit:AtomicReference, bitmap:Int, array:Vector<Any>) {
		this.bitmap = bitmap;
		this.array = array;
		this.edit = edit;
	}

	public function assoc5(shift:Int, hash:Int, key:Any, val:Any, addedLeaf:Box):INode {
		var bit:Int = PersistentHashMap.bitpos(hash, shift);
		var idx:Int = index(bit);
		if ((bitmap & bit) != 0) {
			var keyOrNull:Any = array[2 * idx];
			var valOrNode:Any = array[2 * idx + 1];
			if (keyOrNull == null) {
				var n:INode = cast(valOrNode, INode).assoc5(shift + 5, hash, key, val, addedLeaf);
				if (n == valOrNode)
					return this;
				return new BitmapIndexedNode(null, bitmap, PersistentHashMap.cloneAndSetAny(array, 2 * idx + 1, n));
			}
			if (Util.equiv(key, keyOrNull)) {
				if (val == valOrNode)
					return this;
				return new BitmapIndexedNode(null, bitmap, PersistentHashMap.cloneAndSetAny(array, 2 * idx + 1, val));
			}
			addedLeaf.val = addedLeaf;
			return new BitmapIndexedNode(null, bitmap,
				PersistentHashMap.cloneAndSet5(array, 2 * idx, null, 2 * idx + 1,
					PersistentHashMap.createNode6(shift + 5, keyOrNull, valOrNode, hash, key, val)));
		} else {
			var n:Int = bitCount(bitmap);
			if (n >= 16) {
				var nodes:Vector<INode> = new Vector<INode>(32);
				var jdx:Int = PersistentHashMap.mask(hash, shift);
				nodes[jdx] = EMPTY.assoc5(shift + 5, hash, key, val, addedLeaf);
				var j:Int = 0;
				var i:Int = 0;
				while (i < 32) {
					if (((bitmap >>> i) & 1) != 0) {
						if (array[j] == null)
							nodes[i] = cast array[j + 1];
						else
							nodes[i] = EMPTY.assoc5(shift + 5, PersistentHashMap.hash(array[j]), array[j], array[j + 1], addedLeaf);
						j += 2;
					}
					i++;
				}
				return new ArrayNode(null, n + 1, nodes);
			} else {
				var newArray:Vector<Any> = new Vector<Any>(2 * (n + 1));
				U.vectorCopy(array, 0, newArray, 0, 2 * idx);
				newArray[2 * idx] = key;
				addedLeaf.val = addedLeaf;
				newArray[2 * idx + 1] = val;
				U.vectorCopy(array, 2 * idx, newArray, 2 * (idx + 1), 2 * (n - idx));
				return new BitmapIndexedNode(null, bitmap | bit, newArray);
			}
		}
	}

	public function without3(shift:Int, hash:Int, key:Any):INode {
		var bit:Int = PersistentHashMap.bitpos(hash, shift);
		if ((bitmap & bit) == 0)
			return this;
		var idx:Int = index(bit);
		var keyOrNull:Any = array[2 * idx];
		var valOrNode:Any = array[2 * idx + 1];
		if (keyOrNull == null) {
			var n:INode = cast(valOrNode, INode).without3(shift + 5, hash, key);
			if (n == valOrNode)
				return this;
			if (n != null)
				return new BitmapIndexedNode(null, bitmap, PersistentHashMap.cloneAndSetAny(array, 2 * idx + 1, n));
			if (bitmap == bit)
				return null;
			return new BitmapIndexedNode(null, bitmap ^ bit, PersistentHashMap.removePair(array, idx));
		}
		if (Util.equiv(key, keyOrNull)) {
			if (bitmap == bit)
				return null;
			return new BitmapIndexedNode(null, bitmap ^ bit, PersistentHashMap.removePair(array, idx));
		}
		return this;
	}

	/*public IMapEntry find(int shift, int hash, Object key) {
		int bit = bitpos(hash, shift);
		if ((bitmap & bit) == 0)
			return null;
		int idx = index(bit);
		Object keyOrNull = array[2 * idx];
		Object valOrNode = array[2 * idx + 1];
		if (keyOrNull == null)
			return ((INode) valOrNode).find(shift + 5, hash, key);
		if (Util.equiv(key, keyOrNull))
			return (IMapEntry) MapEntry.create(keyOrNull, valOrNode);
		return null;
	}*/
	public function find(shift:Int, hash:Int, key:Any, ?notFound:Any = null):Any {
		var bit:Int = PersistentHashMap.bitpos(hash, shift);
		if ((bitmap & bit) == 0)
			return notFound;
		var idx:Int = index(bit);
		var keyOrNull:Any = array[2 * idx];
		var valOrNode:Any = array[2 * idx + 1];
		if (keyOrNull == null)
			return cast(valOrNode, INode).find(shift + 5, hash, key, notFound);
		if (Util.equiv(key, keyOrNull))
			return valOrNode;
		return notFound;
	}

	public function nodeSeq():ISeq {
		return NodeSeq.create1(array);
	}

	public function iterator(f:IFn):Iterator<Any> {
		return new NodeIter(array, f);
	}

	public function kvreduce(f:IFn, init:Any):Any {
		return NodeSeq.kvreduce(array, f, init);
	}

	/*public function fold(combinef:IFn, reducef:IFn, fjtask:IFn, fjfork:IFn,  fjjoin:IFn):Any {
		return NodeSeq.kvreduce(array, reducef, combinef.invoke());
	}*/
	private function ensureEditable(edit:AtomicReference):BitmapIndexedNode {
		if (this.edit == edit)
			return this;
		var n:Int = bitCount(bitmap);
		var newArray:Vector<Any> = new Vector<Any>(n >= 0 ? 2 * (n + 1) : 4); // make room for next assoc
		U.vectorCopy(array, 0, newArray, 0, 2 * n);
		return new BitmapIndexedNode(edit, bitmap, newArray);
	}

	private function editAndSet3(edit:AtomicReference, i:Int, a:Any):BitmapIndexedNode {
		var editable:BitmapIndexedNode = ensureEditable(edit);
		editable.array[i] = a;
		return editable;
	}

	private function editAndSet5(edit:AtomicReference, i:Int, a:Any, j:Int, b:Any):BitmapIndexedNode {
		var editable:BitmapIndexedNode = ensureEditable(edit);
		editable.array[i] = a;
		editable.array[j] = b;
		return editable;
	}

	private function editAndRemovePair(edit:AtomicReference, bit:Int, i:Int):BitmapIndexedNode {
		if (bitmap == bit)
			return null;
		var editable:BitmapIndexedNode = ensureEditable(edit);
		editable.bitmap ^= bit;
		U.vectorCopy(editable.array, 2 * (i + 1), editable.array, 2 * i, editable.array.length - 2 * (i + 1));
		editable.array[editable.array.length - 2] = null;
		editable.array[editable.array.length - 1] = null;
		return editable;
	}

	public function assoc6(edit:AtomicReference, shift:Int, hash:Int, key:Any, val:Any, addedLeaf:Box):INode {
		var bit:Int = PersistentHashMap.bitpos(hash, shift);
		var idx:Int = index(bit);
		// trace("BitmapNode assoc6 : ", key, idx, (bitmap & bit) != 0);
		// trace(array);
		if ((bitmap & bit) != 0) {
			var keyOrNull:Any = array[2 * idx];
			var valOrNode:Any = array[2 * idx + 1];
			if (keyOrNull == null) {
				var n:INode = cast(valOrNode, INode).assoc6(edit, shift + 5, hash, key, val, addedLeaf);
				if (n == valOrNode)
					return this;
				return editAndSet3(edit, 2 * idx + 1, n);
			}
			if (Util.equiv(key, keyOrNull)) {
				if (val == valOrNode)
					return this;
				return editAndSet3(edit, 2 * idx + 1, val);
			}
			addedLeaf.val = addedLeaf;
			return editAndSet5(edit, 2 * idx, null, 2 * idx + 1, PersistentHashMap.createNode7(edit, shift + 5, keyOrNull, valOrNode, hash, key, val));
		} else {
			var n:Int = bitCount(bitmap);
			if (n * 2 < array.length) {
				addedLeaf.val = addedLeaf;
				var editable:BitmapIndexedNode = ensureEditable(edit);
				U.vectorCopy(editable.array, 2 * idx, editable.array, 2 * (idx + 1), 2 * (n - idx));
				editable.array[2 * idx] = key;
				editable.array[2 * idx + 1] = val;
				editable.bitmap |= bit;
				return editable;
			}
			if (n >= 16) {
				var nodes:Vector<INode> = new Vector<INode>(32);
				var jdx:Int = PersistentHashMap.mask(hash, shift);
				nodes[jdx] = EMPTY.assoc6(edit, shift + 5, hash, key, val, addedLeaf);
				var j:Int = 0;
				var i:Int = 0;
				while (i < 32) {
					if (((bitmap >>> i) & 1) != 0) {
						if (array[j] == null)
							nodes[i] = cast array[j + 1];
						else
							nodes[i] = EMPTY.assoc6(edit, shift + 5, PersistentHashMap.hash(array[j]), array[j], array[j + 1], addedLeaf);
						j += 2;
					}
					i++;
				}
				return new ArrayNode(edit, n + 1, nodes);
			} else {
				var newArray:Vector<Any> = new Vector<Any>(2 * (n + 4));
				U.vectorCopy(array, 0, newArray, 0, 2 * idx);
				newArray[2 * idx] = key;
				addedLeaf.val = addedLeaf;
				newArray[2 * idx + 1] = val;
				U.vectorCopy(array, 2 * idx, newArray, 2 * (idx + 1), 2 * (n - idx));
				var editable:BitmapIndexedNode = ensureEditable(edit);
				editable.array = newArray;
				editable.bitmap |= bit;
				return editable;
			}
		}
	}

	public function without5(edit:AtomicReference, shift:Int, hash:Int, key:Any, removedLeaf:Box):INode {
		var bit:Int = PersistentHashMap.bitpos(hash, shift);
		if ((bitmap & bit) == 0)
			return this;
		var idx:Int = index(bit);
		var keyOrNull:Any = array[2 * idx];
		var valOrNode:Any = array[2 * idx + 1];
		if (keyOrNull == null) {
			var n:INode = (cast valOrNode).without(edit, shift + 5, hash, key, removedLeaf);
			if (n == valOrNode)
				return this;
			if (n != null)
				return editAndSet3(edit, 2 * idx + 1, n);
			if (bitmap == bit)
				return null;
			return editAndRemovePair(edit, bit, idx);
		}
		if (Util.equiv(key, keyOrNull)) {
			removedLeaf.val = removedLeaf;
			// TODO: collapse
			return editAndRemovePair(edit, bit, idx);
		}
		return this;
	}
}

class HashCollisionNode implements INode {
	var hash:Int;
	var _count:Int;
	var array:Vector<Any>;
	var edit:AtomicReference;

	public function new(edit:AtomicReference, hash:Int, count:Int, array:Vector<Any>) {
		this.edit = edit;
		this.hash = hash;
		this._count = count;
		this.array = array;
	}

	public function assoc5(shift:Int, hash:Int, key:Any, val:Any, addedLeaf:Box):INode {
		if (hash == this.hash) {
			var idx:Int = findIndex(key);
			if (idx != -1) {
				if (array[idx + 1] == val)
					return this;
				return new HashCollisionNode(null, hash, _count, PersistentHashMap.cloneAndSetAny(array, idx + 1, val));
			}
			var newArray:Vector<Any> = new Vector<Any>(2 * (_count + 1));
			U.vectorCopy(array, 0, newArray, 0, 2 * _count);
			newArray[2 * _count] = key;
			newArray[2 * _count + 1] = val;
			addedLeaf.val = addedLeaf;
			return new HashCollisionNode(edit, hash, _count + 1, newArray);
		}
		// nest it in a bitmap node
		var vv:Vector<Any> = new Vector<Any>(2);
		vv[0] = null;
		vv[1] = this;
		return new BitmapIndexedNode(null, PersistentHashMap.bitpos(this.hash, shift), vv).assoc5(shift, hash, key, val, addedLeaf);
	}

	public function without3(shift:Int, hash:Int, key:Any):INode {
		var idx:Int = findIndex(key);
		if (idx == -1)
			return this;
		if (_count == 1)
			return null;
		// TODO: check ids >> 1 == idx / 2
		return new HashCollisionNode(null, hash, _count - 1, PersistentHashMap.removePair(array, idx >> 1));
	}

	/*public function find(int shift, int hash, Object key):IMapEntry {
		int idx = findIndex(key);
		if (idx < 0)
			return null;
		else
			return (IMapEntry) MapEntry.create(array[idx], array[idx + 1]);
	}*/
	public function find(shift:Int, hash:Int, key:Any, notFound:Any = null):Any {
		var idx:Int = findIndex(key);
		if (idx < 0)
			return notFound;
		else
			return array[idx + 1];
	}

	public function nodeSeq():ISeq {
		return NodeSeq.create1(array);
	}

	public function iterator(f:IFn):Iterator<Any> {
		return new NodeIter(array, f);
	}

	public function kvreduce(f:IFn, init:Any):Any {
		return NodeSeq.kvreduce(array, f, init);
	}

	public function fold(combinef:IFn, reducef:IFn, fjtask:IFn, fjfork:IFn, fjjoin:IFn):Any {
		return NodeSeq.kvreduce(array, reducef, combinef.invoke());
	}

	public function findIndex(key:Any):Int {
		var i:Int = 0;
		while (i < 2 * _count) {
			if (Util.equiv(key, array[i]))
				return i;
			i += 2;
		}
		return -1;
	}

	private function ensureEditable1(edit:AtomicReference):HashCollisionNode {
		if (this.edit == edit)
			return this;
		var newArray:Vector<Any> = new Vector<Any>(2 * (_count + 1)); // make room for next assoc
		U.vectorCopy(array, 0, newArray, 0, 2 * _count);
		return new HashCollisionNode(edit, hash, _count, newArray);
	}

	private function ensureEditable3(edit:AtomicReference, count:Int, array:Vector<Any>):HashCollisionNode {
		if (this.edit == edit) {
			this.array = array;
			this._count = count;
			return this;
		}
		return new HashCollisionNode(edit, hash, count, array);
	}

	private function editAndSet3(edit:AtomicReference, i:Int, a:Any):HashCollisionNode {
		var editable:HashCollisionNode = ensureEditable1(edit);
		editable.array[i] = a;
		return editable;
	}

	private function editAndSet5(edit:AtomicReference, i:Int, a:Any, j:Int, b:Any):HashCollisionNode {
		var editable:HashCollisionNode = ensureEditable1(edit);
		editable.array[i] = a;
		editable.array[j] = b;
		return editable;
	}

	public function assoc6(edit:AtomicReference, shift:Int, hash:Int, key:Any, val:Any, addedLeaf:Box):INode {
		if (hash == this.hash) {
			var idx:Int = findIndex(key);
			if (idx != -1) {
				if (array[idx + 1] == val)
					return this;
				return editAndSet3(edit, idx + 1, val);
			}
			if (array.length > 2 * _count) {
				addedLeaf.val = addedLeaf;
				var editable:HashCollisionNode = editAndSet5(edit, 2 * _count, key, 2 * _count + 1, val);
				editable._count++;
				return editable;
			}
			var newArray:Vector<Any> = new Vector<Any>(array.length + 2);
			U.vectorCopy(array, 0, newArray, 0, array.length);
			newArray[array.length] = key;
			newArray[array.length + 1] = val;
			addedLeaf.val = addedLeaf;
			return ensureEditable3(edit, _count + 1, newArray);
		}
		// nest it in a bitmap node
		var vv:Vector<Any> = new Vector<Any>(4);
		vv[0] = null;
		vv[1] = this;
		vv[2] = null;
		vv[3] = null;
		return new BitmapIndexedNode(edit, PersistentHashMap.bitpos(this.hash, shift), vv).assoc6(edit, shift, hash, key, val, addedLeaf);
	}

	public function without5(edit:AtomicReference, shift:Int, hash:Int, key:Any, removedLeaf:Box):INode {
		var idx:Int = findIndex(key);
		if (idx == -1)
			return this;
		removedLeaf.val = removedLeaf;
		if (_count == 1)
			return null;
		var editable:HashCollisionNode = ensureEditable1(edit);
		editable.array[idx] = editable.array[2 * _count - 2];
		editable.array[idx + 1] = editable.array[2 * _count - 1];
		editable.array[2 * _count - 2] = editable.array[2 * _count - 1] = null;
		editable._count--;
		return editable;
	}
}

// NodeIter ==========================================================
class NodeIterNull {
	public function new() {}
}

class NodeIter /*implements Iterator */ {
	private static final NULL:Any = new NodeIterNull();

	var array:Vector<Any>;
	var f:IFn;
	private var i:Int = 0;
	private var nextEntry:Any = NULL;
	private var nextIter:Iterator<Any>;

	public function new(array:Vector<Any>, f:IFn) {
		this.array = array;
		this.f = f;
	}

	private function advance():Bool {
		while (i < array.length) {
			var key:Any = array[i];
			var nodeOrVal:Any = array[i + 1];
			i += 2;
			if (key != null) {
				nextEntry = f.invoke2(key, nodeOrVal);
				return true;
			} else if (nodeOrVal != null) {
				var iter:Iterator<Any> = cast(nodeOrVal, INode).iterator(f);
				if (iter != null && iter.hasNext()) {
					nextIter = iter;
					return true;
				}
			}
		}
		return false;
	}

	public function hasNext():Bool {
		if (nextEntry != NULL || nextIter != null)
			return true;
		return advance();
	}

	public function next():Any {
		var ret:Any = nextEntry;
		if (ret != NULL) {
			nextEntry = NULL;
			return ret;
		} else if (nextIter != null) {
			ret = nextIter.next();
			if (!nextIter.hasNext())
				nextIter = null;
			return ret;
		} else if (advance())
			return next();
		throw new NoSuchElementException();
	}
}

/// NodeSeq ======================================================
class NodeSeq extends ASeq {
	var array:Vector<Any>;
	var i:Int;
	var s:ISeq;

	public static function create2(array:Vector<Any>, i:Int):NodeSeq {
		return new NodeSeq(null, array, i, null);
	}

	static public function create1(array:Vector<Any>):ISeq {
		return create3(array, 0, null);
	}

	static public function kvreduce(array:Vector<Any>, f:IFn, init:Any):Any {
		var i:Int = 0;
		while (i < array.length) {
			if (array[i] != null)
				init = f.invoke(init, array[i], array[i + 1]);
			else {
				var node:INode = cast array[i + 1];
				if (node != null)
					init = node.kvreduce(f, init);
			}
			if (RT.isReduced(init))
				return init;
			i += 2;
		}
		return init;
	}

	private static function create3(array:Vector<Any>, i:Int, s:ISeq):ISeq {
		if (s != null)
			return new NodeSeq(null, array, i, s);
		var j:Int = i;
		while (j < array.length) {
			if (array[j] != null)
				return new NodeSeq(null, array, j, null);
			var node:INode = cast array[j + 1];
			if (node != null) {
				var nodeSeq:ISeq = node.nodeSeq();
				if (nodeSeq != null)
					return new NodeSeq(null, array, j + 2, nodeSeq);
			}
			j += 2;
		}
		return null;
	}

	public function new(meta:IPersistentMap, array:Vector<Any>, i:Int, s:ISeq) {
		super(meta);
		this.array = array;
		this.i = i;
		this.s = s;
	}

	public function withMeta(meta:IPersistentMap):Obj {
		if (super.meta() == meta)
			return this;
		return new NodeSeq(meta, array, i, s);
	}

	public function first():Any {
		if (s != null)
			return s.first();
		return MapEntry.create(array[i], array[i + 1]);
	}

	public function next():ISeq {
		if (s != null)
			return create3(array, i, s.next());
		return create3(array, i + 2, null);
	}
}

class AtomicReference {
	public function new() {}
}
