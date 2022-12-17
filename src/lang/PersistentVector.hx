package lang;

import haxe.ds.Vector;
import lang.exceptions.IllegalAccessError;
import lang.exceptions.IndexOutOfBoundsException;
import lang.exceptions.IllegalArgumentException;
import lang.exceptions.IllegalStateException;
import lang.exceptions.NoSuchElementException;

class PersistentVector extends APersistentVector implements IObj implements IEditableCollection implements IReduce implements IKVReduce implements IDrop {
	public var cnt:Int;
	public var shift:Int;
	public var root:Node;
	public var tail:Vector<Any>;

	var _meta:IPersistentMap;

	public static final NO_EDIT = false;
	public static final EMPTY_NODE:Node = new Node(NO_EDIT, new Vector<Any>(32));
	public static final EMPTY:PersistentVector = new PersistentVector(0, 5, EMPTY_NODE, new Vector<Any>(0));
	private static final TRANSIENT_VECTOR_CONJ:IFn = new TransientVectorConjAFn();

	public function new(cnt:Int, shift:Int, root:Node, tail:Vector<Any>, ?meta:IPersistentMap = null) {
		this._meta = meta;
		this.cnt = cnt;
		this.shift = shift;
		this.root = root;
		this.tail = tail;
	}

	static public function adopt(items:Vector<Any>):PersistentVector {
		return new PersistentVector(items.length, 5, EMPTY_NODE, items);
	}

	static public function create(items:IReduceInit):PersistentVector {
		var ret:TransientVector = EMPTY.asTransient();
		items.reduce2(TRANSIENT_VECTOR_CONJ, ret);
		return ret.persistent();
	}

	static public function createFromISeq(items:ISeq):PersistentVector {
		var arr:Vector<Any> = new Vector<Any>(32);
		var i:Int = 0;
		while (items != null && i < 32) {
			arr[i++] = items.first();
			items = items.next();
		}
		if (items != null) { // >32, construct with array directly
			var start:PersistentVector = new PersistentVector(32, 5, EMPTY_NODE, arr);
			var ret:TransientVector = start.asTransient();
			while (items != null) {
				ret = ret.conj(items.first());
				items = items.next();
			}
			return ret.persistent();
		} else if (i == 32) { // exactly 32, skip copy
			return new PersistentVector(32, 5, EMPTY_NODE, arr);
		} else { // <32, copy to minimum array and construct
			var arr2:Vector<Any> = new Vector<Any>(i);
			U.vectorCopy(arr, 0, arr2, 0, i);
			return new PersistentVector(i, 5, EMPTY_NODE, arr2);
		}
	}

	static public function createFromItems(...items:Any):PersistentVector {
		var ret:TransientVector = EMPTY.asTransient();
		for (item in items)
			ret = ret.conj(item);
		return ret.persistent();
	}

	public function asTransient():TransientVector {
		return TransientVector.createFromPersistentVector(this);
	}

	public function tailoff():Int {
		if (cnt < 32)
			return 0;
		return ((cnt - 1) >>> 5) << 5;
	}

	public function arrayFor(i:Int):Vector<Any> {
		if (i >= 0 && i < cnt) {
			if (i >= tailoff())
				return tail;
			var node:Node = root;
			var level:Int = shift;
			while (level > 0) {
				node = cast node.array[(i >>> level) & 0x01f];
				level -= 5;
			}
			return node.array;
		}
		throw new IndexOutOfBoundsException();
	}

	public function nth1(i:Int):Any {
		var node:Vector<Any> = arrayFor(i);
		return node[i & 0x01f];
	}

	public function assocN(i:Int, val:Any):PersistentVector {
		if (i >= 0 && i < cnt) {
			if (i >= tailoff()) {
				var newTail:Vector<Any> = new Vector<Any>(tail.length);
				U.vectorCopy(tail, 0, newTail, 0, tail.length);
				newTail[i & 0x01f] = val;
				return new PersistentVector(cnt, shift, root, newTail, meta());
			}
			return new PersistentVector(cnt, shift, doAssoc(shift, root, i, val), tail, meta());
		}
		if (i == cnt)
			return cons(val);
		throw new IndexOutOfBoundsException();
	}

	public static function doAssoc(level:Int, node:Node, i:Int, val:Any):Node {
		var ret:Node = new Node(node.edit, node.array.copy());
		if (level == 0) {
			ret.array[i & 0x01f] = val;
		} else {
			var subidx:Int = (i >>> level) & 0x01f;
			ret.array[subidx] = doAssoc(level - 5, cast node.array[subidx], i, val);
		}
		return ret;
	}

	public function count():Int {
		return cnt;
	}

	public function meta():IPersistentMap {
		return _meta;
	}

	public function withMeta(meta:IPersistentMap):PersistentVector {
		if (this.meta() == meta) {
			return this;
		}
		return new PersistentVector(cnt, shift, root, tail, meta);
	}

	public function cons(val:Any):PersistentVector {
		// room in tail?
		//	if(tail.length < 32)
		if (cnt - tailoff() < 32) {
			var newTail:Vector<Any> = new Vector<Any>(tail.length + 1);
			U.vectorCopy(tail, 0, newTail, 0, tail.length);
			newTail[tail.length] = val;
			return new PersistentVector(cnt + 1, shift, root, newTail, meta());
		}
		// full tail, push into tree
		var newroot:Node;
		var tailnode:Node = new Node(root.edit, tail);
		var newshift:Int = shift;
		// overflow root?
		if ((cnt >>> 5) > (1 << shift)) {
			newroot = new Node(root.edit);
			newroot.array[0] = root;
			newroot.array[1] = newPath(root.edit, shift, tailnode);
			newshift += 5;
		} else {
			newroot = pushTail(shift, root, tailnode);
		}
		var ve:Vector<Any> = new Vector<Any>(1);
		ve[0] = val;
		return new PersistentVector(cnt + 1, newshift, newroot, ve, meta());
	}

	private function pushTail(level:Int, parent:Node, tailnode:Node):Node {
		// if parent is leaf, insert node,
		// else does it map to an existing child? -> nodeToInsert = pushNode one more level
		// else alloc new path
		// return  nodeToInsert placed in copy of parent
		var subidx:Int = ((cnt - 1) >>> level) & 0x01f;
		var ret:Node = new Node(parent.edit, parent.array.copy());
		var nodeToInsert:Node;
		if (level == 5) {
			nodeToInsert = tailnode;
		} else {
			var child:Node = cast parent.array[subidx];
			nodeToInsert = (child != null) ? pushTail(level - 5, child, tailnode) : newPath(root.edit, level - 5, tailnode);
		}
		ret.array[subidx] = nodeToInsert;
		return ret;
	}

	static public function newPath(edit:Bool, level:Int, node:Node):Node {
		if (level == 0)
			return node;
		var ret:Node = new Node(edit);
		ret.array[0] = newPath(edit, level - 5, node);
		return ret;
	}

	public function chunkedSeq():IChunkedSeq {
		if (count() == 0)
			return null;
		return ChunkedSeq.create(this, 0, 0);
	}

	override public function seq():ISeq {
		return chunkedSeq();
	}

	override public function rangedIterator(start:Int, end:Int):Iterator<Any> {
		return new RangedIteratorPV(this, start, end);
	}

	override public function iterator():Iterator<Any> {
		return rangedIterator(0, count());
	}

	public function reduce1(f:IFn):Any {
		var init:Any;
		if (cnt > 0)
			init = arrayFor(0)[0];
		else
			return f.invoke();
		var step:Int = 0;
		var i:Int = 0;
		while (i < cnt) {
			var array:Vector<Any> = arrayFor(i);
			var j:Int = (i == 0) ? 1 : 0;
			while (j < array.length) {
				init = f.invoke(init, array[j]);
				if (RT.isReduced(init))
					return cast(init, IDeref).deref();
				j++;
			}
			step = array.length;
			i += step;
		}
		return init;
	}

	public function reduce2(f:IFn, init:Any) {
		var step:Int = 0;
		var i:Int = 0;
		while (i < cnt) {
			var array:Vector<Any> = arrayFor(i);
			var j:Int = 0;
			while (j < array.length) {
				init = f.invoke(init, array[j]);
				if (RT.isReduced(init))
					return cast(init, IDeref).deref();
				++j;
			}
			step = array.length;
			i += step;
		}
		return init;
	}

	public function kvreduce(f:IFn, init:Any):Any {
		var step:Int = 0;
		var i:Int = 0;
		while (i < cnt) {
			var array:Vector<Any> = arrayFor(i);
			var j:Int = 0;
			while (j < array.length) {
				init = f.invoke(init, j + i, array[j]);
				if (RT.isReduced(init))
					return cast(init, IDeref).deref();
				++j;
			}
			step = array.length;
			i += step;
		}
		return init;
	}

	public function drop(n:Int):Sequential {
		if (n < 0) {
			return this;
		} else if (n < cnt) {
			var offset:Int = n % 32;
			return new ChunkedSeq(this, this.arrayFor(n), n - offset, offset);
		} else {
			return null;
		}
	}

	public function empty():IPersistentCollection {
		return EMPTY.withMeta(meta());
	}

	public function pop():PersistentVector {
		if (cnt == 0)
			throw new IllegalStateException("Can't pop empty vector");
		if (cnt == 1)
			return EMPTY.withMeta(meta());
		// if(tail.length > 1)
		if (cnt - tailoff() > 1) {
			var newTail:Vector<Any> = new Vector<Any>(tail.length - 1);
			U.vectorCopy(tail, 0, newTail, 0, newTail.length);
			return new PersistentVector(cnt - 1, shift, root, newTail, meta());
		}
		var newtail:Vector<Any> = arrayFor(cnt - 2);

		var newroot:Node = popTail(shift, root);
		var newshift:Int = shift;
		if (newroot == null) {
			newroot = EMPTY_NODE;
		}
		if (shift > 5 && newroot.array[1] == null) {
			newroot = cast newroot.array[0];
			newshift -= 5;
		}
		return new PersistentVector(cnt - 1, newshift, newroot, newtail, meta());
	}

	private function popTail(level:Int, node:Node):Node {
		var subidx:Int = ((cnt - 2) >>> level) & 0x01f;
		if (level > 5) {
			var newchild:Node = popTail(level - 5, cast node.array[subidx]);
			if (newchild == null && subidx == 0)
				return null;
			else {
				var ret:Node = new Node(root.edit, node.array.copy());
				ret.array[subidx] = newchild;
				return ret;
			}
		} else if (subidx == 0)
			return null;
		else {
			var ret:Node = new Node(root.edit, node.array.copy());
			ret.array[subidx] = null;
			return ret;
		}
	}
}

// ChunkedSeq ========================================================================
class ChunkedSeq extends ASeq implements IChunkedSeq implements Counted implements IReduce implements IDrop {
	public final vec:PersistentVector;

	final node:Vector<Any>;
	final i:Int;

	public final offset:Int;

	public function new(vec:PersistentVector, node:Vector<Any>, i:Int, offset:Int, ?meta:IPersistentMap) {
		super(meta);
		this.vec = vec;
		this.node = node;
		this.i = i;
		this.offset = offset;
	}

	static public function create(vec:PersistentVector, i:Int, offset:Int):ChunkedSeq {
		return new ChunkedSeq(vec, vec.arrayFor(i), i, offset);
	}

	public function chunkedFirst():IChunk {
		return new ArrayChunk(node, offset);
	}

	public function chunkedNext():ISeq {
		if (i + node.length < vec.cnt)
			return create(vec, i + node.length, 0);
		return null;
	}

	public function chunkedMore():ISeq {
		var s:ISeq = chunkedNext();
		if (s == null)
			return PersistentList.EMPTY;
		return s;
	}

	override public function withMeta(meta:IPersistentMap):Obj {
		if (meta == this._meta)
			return this;
		return new ChunkedSeq(vec, node, i, offset, meta);
	}

	public function first():Any {
		return node[offset];
	}

	public function next():ISeq {
		if (offset + 1 < node.length)
			return new ChunkedSeq(vec, node, i, offset + 1);
		return chunkedNext();
	}

	override public function count():Int {
		return vec.cnt - (i + offset);
	}

	override public function iterator():Iterator<Any> {
		return vec.rangedIterator(i + offset, vec.cnt);
	}

	public function reduce1(f:IFn):Any {
		var acc:Any;
		if (i + offset < vec.cnt)
			acc = node[offset];
		else
			return f.invoke();
		var j:Int = offset + 1;
		while (j < node.length) {
			acc = f.invoke(acc, node[j]);
			if (RT.isReduced(acc))
				return cast(acc, IDeref).deref();
			++j;
		}

		var step:Int = 0;
		var ii:Int = i + node.length;
		while (ii < vec.cnt) {
			var array:Vector<Any> = vec.arrayFor(ii);
			var j:Int = 0;
			while (j < array.length) {
				acc = f.invoke(acc, array[j]);
				if (RT.isReduced(acc))
					return cast(acc, IDeref).deref();
				++j;
			}
			step = array.length;
			ii += step;
		}
		return acc;
	}

	public function reduce2(f:IFn, init:Any):Any {
		var acc:Any = init;
		var j:Int = offset;
		while (j < node.length) {
			acc = f.invoke(acc, node[j]);
			if (RT.isReduced(acc))
				return cast(acc, IDeref).deref();
			++j;
		}
		var step:Int = 0;
		var ii:Int = i + node.length;
		while (ii < vec.cnt) {
			var array:Vector<Any> = vec.arrayFor(ii);
			var j:Int = 0;
			while (j < array.length) {
				acc = f.invoke(acc, array[j]);
				if (RT.isReduced(acc))
					return cast(acc, IDeref).deref();
				++j;
			}
			step = array.length;
			ii += step;
		}
		return acc;
	}

	public function drop(n:Int):Sequential {
		var o:Int = offset + n;
		if (o < node.length) { // in current array
			return new ChunkedSeq(vec, node, i, o);
		} else {
			var i:Int = this.i + o;
			if (i < vec.cnt) { // in vec
				// TODO: not need this
				// var array:Vector<Any> = vec.arrayFor(i);
				var newOffset:Int = i % 32;
				return new ChunkedSeq(vec, vec.arrayFor(i), i - newOffset, newOffset);
			} else {
				return null;
			}
		}
	}
}

// RangedIterator ========================================================================
class RangedIteratorPV {
	var i:Int;
	var end:Int;
	var base:Int;
	var v:PersistentVector;
	var array:Vector<Any>;

	public function new(v:PersistentVector, start:Int, end:Int) {
		this.v = v;
		this.i = start;
		this.end = end;
		this.base = i - (i % 32);
		this.array = (start < v.count()) ? v.arrayFor(i) : null;
	}

	public function hasNext():Bool {
		return i < end;
	}

	public function next():Any {
		if (i < end) {
			if (i - base == 32) {
				array = v.arrayFor(i);
				base += 32;
			}
			return array[i++ & 0x01f];
		} else {
			throw new NoSuchElementException();
		}
	}
}

// Node ====================================================================================
class Node {
	// transient public final AtomicReference<Thread> edit;
	public var edit:Bool;
	public var array:Vector<Any>;

	public function new(edit:Bool, ?array:Vector<Any> = null) {
		this.edit = edit;
		this.array = if (array != null) array else new Vector<Any>(32);
	}
}

// TransientVectorConjAFn ===================================================================
class TransientVectorConjAFn extends AFn {
	public function new() {}

	override public function invoke2(coll:Any, val:Any):Any {
		return cast(coll, ITransientVector).conj(val);
	}

	override public function invoke1(coll:Any):Any {
		return coll;
	}
}

class NotFound {
	public function new() {};
}

// TransientVector ===========================================================================
class TransientVector extends AFn implements ITransientVector implements ITransientAssociative2 implements Counted {
	@:volatile var cnt:Int;
	@:volatile var shift:Int;
	@:volatile var root:Node;
	@:volatile var tail:Vector<Any>;

	public function new(cnt:Int, shift:Int, root:Node, tail:Vector<Any>) {
		this.cnt = cnt;
		this.shift = shift;
		this.root = root;
		this.tail = tail;
	}

	public static function createFromPersistentVector(v:PersistentVector):TransientVector {
		return new TransientVector(v.cnt, v.shift, editableRoot(v.root), editableTail(v.tail));
	}

	public function count():Int {
		ensureEditable0();
		return cnt;
	}

	public function ensureEditable(node:Node):Node {
		if (node.edit == root.edit)
			return node;
		return new Node(root.edit, node.array.copy());
	}

	public function ensureEditable0() {
		if (root.edit == false)
			throw new IllegalAccessError("Transient used after persistent! call");
	}

	static public function editableRoot(node:Node):Node {
		return new Node(true, node.array.copy());
	}

	public function persistent():PersistentVector {
		ensureEditable0();
		root.edit = false;
		var trimmedTail:Vector<Any> = new Vector<Any>(cnt - tailoff());
		// TODO: vectorCopy
		// System.arraycopy(tail, 0, trimmedTail, 0, trimmedTail.length);
		U.vectorCopy(tail, 0, trimmedTail, 0, trimmedTail.length);
		return new PersistentVector(cnt, shift, root, trimmedTail);
	}

	static function editableTail(tl:Vector<Any>):Vector<Any> {
		var ret:Vector<Any> = new Vector<Any>(32);
		// TODO:
		// System.arraycopy(tl, 0, ret, 0, tl.length);
		U.vectorCopy(tl, 0, ret, 0, tl.length);
		return ret;
	}

	public function conj(val:Any):TransientVector {
		ensureEditable0();
		var i:Int = cnt;
		// room in tail?
		if (i - tailoff() < 32) {
			tail[i & 0x01f] = val;
			++cnt;
			return this;
		}
		// full tail, push into tree
		var newroot:Node;
		var tailnode:Node = new Node(root.edit, tail);
		tail = new Vector<Any>(32);
		tail[0] = val;
		var newshift:Int = shift;
		// overflow root?
		if ((cnt >>> 5) > (1 << shift)) {
			newroot = new Node(root.edit);
			newroot.array[0] = root;
			newroot.array[1] = PersistentVector.newPath(root.edit, shift, tailnode);
			newshift += 5;
		} else
			newroot = pushTail(shift, root, tailnode);
		root = newroot;
		shift = newshift;
		++cnt;
		return this;
	}

	private function pushTail(level:Int, parent:Node, tailnode:Node):Node {
		// if parent is leaf, insert node,
		// else does it map to an existing child? -> nodeToInsert = pushNode one more level
		// else alloc new path
		// return  nodeToInsert placed in parent
		parent = ensureEditable(parent);
		var subidx:Int = ((cnt - 1) >>> level) & 0x01f;
		var ret:Node = parent;
		var nodeToInsert:Node;
		if (level == 5) {
			nodeToInsert = tailnode;
		} else {
			var child:Node = cast parent.array[subidx];
			nodeToInsert = (child != null) ? pushTail(level - 5, child, tailnode) : PersistentVector.newPath(root.edit, level - 5, tailnode);
		}
		ret.array[subidx] = nodeToInsert;
		return ret;
	}

	private function tailoff():Int {
		if (cnt < 32)
			return 0;
		return ((cnt - 1) >>> 5) << 5;
	}

	private function arrayFor(i:Int):Vector<Any> {
		if (i >= 0 && i < cnt) {
			if (i >= tailoff())
				return tail;
			var node:Node = root;
			var level:Int = shift;
			while (level > 0) {
				node = cast node.array[(i >>> level) & 0x01f];
				level -= 5;
			}
			return node.array;
		}
		throw new IndexOutOfBoundsException();
		return null;
	}

	private function editableArrayFor(i:Int):Vector<Any> {
		if (i >= 0 && i < cnt) {
			if (i >= tailoff())
				return tail;
			var node:Node = root;
			var level:Int = shift;
			while (level > 0) {
				node = ensureEditable(cast(node.array[(i >>> level) & 0x01f], Node));
				level -= 5;
			}
			return node.array;
		}
		throw new IndexOutOfBoundsException();
		return null;
	}

	public function valAt(key:Any, ?notFound:Any = null):Any {
		ensureEditable0();
		if (Util.isInteger(key)) {
			var i = cast key;
			if (i >= 0 && i < cnt)
				return nth1(i);
		}
		return notFound;
	}

	private static final NOT_FOUND:NotFound = new NotFound();

	public function containsKey(key:Any) {
		return valAt(key, NOT_FOUND) != NOT_FOUND;
	}

	public final function entryAt(key:Any):IMapEntry {
		var v:Any = valAt(key, NOT_FOUND);
		if (v != NOT_FOUND)
			return MapEntry.create(key, v);
		return null;
	}

	override public function invoke1(arg1:Any):Any {
		// note - relies on ensureEditable in nth
		if (Util.isInteger(arg1)) {
			var i:Int = cast arg1;
			return nth1(i);
		}
		throw new IllegalArgumentException("Key must be integer");
	}

	public function nth1(i:Int):Any {
		ensureEditable0();
		var node:Vector<Any> = arrayFor(i);
		return node[i & 0x01f];
	}

	public function nth2(i:Int, notFound:Any):Any {
		if (i >= 0 && i < count())
			return nth1(i);
		return notFound;
	}

	public function nth(...args:Any):Any {
		switch (args.length) {
			case 1:
				return nth1(cast args[0]);
			case 2:
				return nth2(cast args[0], cast args[1]);
			default:
				throwArity(args.length);
				return null;
		}
	}

	public function assocN(i:Int, val:Any):TransientVector {
		ensureEditable0();
		if (i >= 0 && i < cnt) {
			if (i >= tailoff()) {
				tail[i & 0x01f] = val;
				return this;
			}
			root = doAssoc(shift, root, i, val);
			return this;
		}
		if (i == cnt)
			return conj(val);
		throw new IndexOutOfBoundsException();
	}

	public function assoc(key:Any, val:Any):TransientVector {
		// note - relies on ensureEditable in assocN
		if (Util.isInteger(key)) {
			var i:Int = cast key;
			return assocN(i, val);
		}
		throw new IllegalArgumentException("Key must be integer");
	}

	private function doAssoc(level:Int, node:Node, i:Int, val:Any):Node {
		node = ensureEditable(node);
		var ret:Node = node;
		if (level == 0) {
			ret.array[i & 0x01f] = val;
		} else {
			var subidx:Int = (i >>> level) & 0x01f;
			ret.array[subidx] = doAssoc(level - 5, cast(node.array[subidx], Node), i, val);
		}
		return ret;
	}

	public function pop():TransientVector {
		ensureEditable0();
		if (cnt == 0)
			throw new IllegalStateException("Can't pop empty vector");
		if (cnt == 1) {
			cnt = 0;
			return this;
		}
		var i:Int = cnt - 1;
		// pop in tail?
		if ((i & 0x01f) > 0) {
			--cnt;
			return this;
		}

		var newtail:Vector<Any> = editableArrayFor(cnt - 2);

		var newroot:Node = popTail(shift, root);
		var newshift:Int = shift;
		if (newroot == null) {
			newroot = new Node(root.edit);
		}
		if (shift > 5 && newroot.array[1] == null) {
			newroot = ensureEditable(cast(newroot.array[0], Node));
			newshift -= 5;
		}
		root = newroot;
		shift = newshift;
		--cnt;
		tail = newtail;
		return this;
	}

	private function popTail(level:Int, node:Node):Node {
		node = ensureEditable(node);
		var subidx:Int = ((cnt - 2) >>> level) & 0x01f;
		if (level > 5) {
			var newchild:Node = popTail(level - 5, cast(node.array[subidx], Node));
			if (newchild == null && subidx == 0)
				return null;
			else {
				var ret:Node = node;
				ret.array[subidx] = newchild;
				return ret;
			}
		} else if (subidx == 0)
			return null;
		else {
			var ret:Node = node;
			ret.array[subidx] = null;
			return ret;
		}
	}
}
