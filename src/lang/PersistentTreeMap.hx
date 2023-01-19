package lang;

import lang.exceptions.IllegalArgumentException;
import lang.exceptions.UnsupportedOperationException;
import lang.exceptions.ClassCastException;
import lang.exceptions.NoSuchElementException;

class PersistentTreeMap extends APersistentMap implements IObj implements Reversible implements Sorted implements IKVReduce {
	public var comp:Comparator;
	public var tree:PTMNode;
	public var _count:Int;

	var _meta:IPersistentMap;

	static public final EMPTY:PersistentTreeMap = PersistentTreeMap.create();

	/*static public function create(other:Map<Any, Any>):IPersistentMap {
		var ret:IPersistentMap = EMPTY;
		for ( o in other.entrySet()) {
			var e:Map.Entry = cast(o, IMapEntry);
			ret = cast ret.assoc(e.getKey(), e.getValue());
		}
		return ret;
	}*/
	static public function create():PersistentTreeMap {
		return create1(RT.DEFAULT_COMPARATOR);
	}

	public function withMeta(meta:IPersistentMap):PersistentTreeMap {
		if (_meta == meta)
			return this;
		return new PersistentTreeMap(comp, tree, _count, meta);
	}

	static private function create1(comp:Comparator):PersistentTreeMap {
		return create2(null, comp);
	}

	static public function create2(meta:IPersistentMap, comp:Comparator):PersistentTreeMap {
		return new PersistentTreeMap(comp, null, 0, meta);
	}

	private function new(comp:Comparator, tree:PTMNode, _count:Int, meta:IPersistentMap) {
		this._meta = meta;
		this.comp = comp;
		this.tree = tree;
		this._count = _count;
	}

	static public function createFromISeq(items:ISeq):PersistentTreeMap {
		var ret:IPersistentMap = EMPTY;
		while (items != null) {
			if (items.next() == null)
				throw new IllegalArgumentException("No value supplied for key: " + items.first());
			ret = cast ret.assoc(items.first(), RT.second(items));
			items = items.next().next();
		}
		return cast ret;
	}

	static public function createCompISeq(comp:Comparator, items:ISeq):PersistentTreeMap {
		var ret:IPersistentMap = PersistentTreeMap.create1(comp);
		while (items != null) {
			if (items.next() == null)
				throw new IllegalArgumentException("No value supplied for key: " + items.first());
			ret = cast ret.assoc(items.first(), RT.second(items));
			items = items.next().next();
		}
		return cast ret;
	}

	public function containsKey(key:Any):Bool {
		return entryAt(key) != null;
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

	public function assocEx(key:Any, val:Any):PersistentTreeMap {
		var found:Box = new Box(null);
		var t:PTMNode = add(tree, key, val, found);
		if (t == null) // null == already contains key
		{
			throw Util.runtimeException("Key already present");
		}
		return new PersistentTreeMap(comp, t.blacken(), _count + 1, meta());
	}

	public function assoc(key:Any, val:Any):PersistentTreeMap {
		var found:Box = new Box(null);
		var t:PTMNode = add(tree, key, val, found);
		if (t == null) // null == already contains key
		{
			var foundNode:PTMNode = cast found.val;
			if (foundNode.val() == val) // note only get same collection on identity of val, not equals()
				return this;
			return new PersistentTreeMap(comp, replace(tree, key, val), _count, meta());
		}
		return new PersistentTreeMap(comp, t.blacken(), _count + 1, meta());
	}

	public function without(key:Any):PersistentTreeMap {
		var found:Box = new Box(null);
		var t:PTMNode = remove(tree, key, found);
		if (t == null) {
			if (found.val == null) // null == doesn't contain key
				return this;
			// empty
			return create2(meta(), comp);
		}
		return new PersistentTreeMap(comp, t.blacken(), _count - 1, meta());
	}

	public function seq():ISeq {
		if (_count > 0)
			return PTMSeq.createFromNode(tree, true, _count);
		return null;
	}

	public function empty():IPersistentCollection {
		return PersistentTreeMap.create2(meta(), comp);
	}

	public function rseq():ISeq {
		if (_count > 0)
			return PTMSeq.createFromNode(tree, false, _count);
		return null;
	}

	public function comparator():Comparator {
		return comp;
	}

	public function entryKey(entry:Any):Any {
		return cast(entry, IMapEntry).key();
	}

	public function seq1(ascending:Bool):ISeq {
		if (_count > 0)
			return PTMSeq.createFromNode(tree, ascending, _count);
		return null;
	}

	public function seqFrom(key:Any, ascending:Bool):ISeq {
		if (_count > 0) {
			var stack:ISeq = null;
			var t:PTMNode = tree;
			while (t != null) {
				var c:Int = doCompare(key, t._key);
				if (c == 0) {
					stack = RT.cons(t, stack);
					return PTMSeq.create2(stack, ascending);
				} else if (ascending) {
					if (c < 0) {
						stack = RT.cons(t, stack);
						t = t.left();
					} else
						t = t.right();
				} else {
					if (c > 0) {
						stack = RT.cons(t, stack);
						t = t.right();
					} else
						t = t.left();
				}
			}
			if (stack != null)
				return PTMSeq.create2(stack, ascending);
		}
		return null;
	}

	public function iterator():NodeIterator {
		return new NodeIterator(tree, true);
	}

	public function kvreduce(f:IFn, init:Any):Any {
		if (tree != null)
			init = tree.kvreduce(f, init);
		if (RT.isReduced(init))
			init = cast(init, IDeref).deref();
		return init;
	}

	public function reverseIterator():NodeIterator {
		return new NodeIterator(tree, false);
	}

	public function keys():Iterator<Any> {
		return keys1(iterator());
	}

	public function vals():Iterator<Any> {
		return vals1(iterator());
	}

	public function keys1(it:NodeIterator):Iterator<Any> {
		return new KeyIterator(it);
	}

	public function vals1(it:NodeIterator):Iterator<Any> {
		return new ValIterator(it);
	}

	public function minKey():Any {
		var t:PTMNode = min();
		return t != null ? t._key : null;
	}

	public function min():PTMNode {
		var t:PTMNode = tree;
		if (t != null) {
			while (t.left() != null)
				t = t.left();
		}
		return t;
	}

	public function maxKey():Any {
		var t:PTMNode = max();
		return t != null ? t._key : null;
	}

	public function max():PTMNode {
		var t:PTMNode = tree;
		if (t != null) {
			while (t.right() != null)
				t = t.right();
		}
		return t;
	}

	public function depth():Int {
		return depth1(tree);
	}

	private function depth1(t:PTMNode):Int {
		if (t == null)
			return 0;
		return Std.int(1 + Math.max(depth1(t.left()), depth1(t.right())));
	}

	public function valAt(key:Any, ?notFound:Any = null) {
		var n:PTMNode = entryAt(key);
		return (n != null) ? n.val() : notFound;
	}

	/*
		public function valAt( key:Any):Any {
			return valAt(key, null);
		}
	 */
	public function capacity():Int {
		return _count;
	}

	public function count():Int {
		return _count;
	}

	public function entryAt(key:Any):PTMNode {
		var t:PTMNode = tree;
		while (t != null) {
			var c:Int = doCompare(key, t._key);
			if (c == 0)
				return t;
			else if (c < 0)
				t = t.left();
			else
				t = t.right();
		}
		return t;
	}

	public function doCompare(k1:Any, k2:Any):Int {
		// trace("Compare " + k1 + " and " + k2 + " = " + comp.compare(k1, k2));
		return comp.compare(k1, k2);
	}

	function add(t:PTMNode, key:Any, val:Any, found:Box):PTMNode {
		if (t == null) {
			// TODO: check
			if (comp == RT.DEFAULT_COMPARATOR
				&& !(key == null || U.instanceof(key, String) || (U.isNumber(key)) || (U.instanceof(key, Comparable))))
				throw new ClassCastException("Default comparator requires nil, Number, or Comparable: " + key);
			if (val == null)
				return new Red(key);
			return new RedVal(key, val);
		}
		var c:Int = doCompare(key, t._key);
		if (c == 0) {
			found.val = t;
			return null;
		}
		var ins:PTMNode = c < 0 ? add(t.left(), key, val, found) : add(t.right(), key, val, found);
		if (ins == null) // found below
			return null;
		if (c < 0)
			return t.addLeft(ins);
		return t.addRight(ins);
	}

	function remove(t:PTMNode, key:Any, found:Box):PTMNode {
		if (t == null)
			return null; // not found indicator
		var c:Int = doCompare(key, t._key);
		if (c == 0) {
			found.val = t;
			return append(t.left(), t.right());
		}
		var del:PTMNode = c < 0 ? remove(t.left(), key, found) : remove(t.right(), key, found);
		if (del == null && found.val == null) // not found below
			return null;
		if (c < 0) {
			if (U.instanceof(t.left(), Black))
				return balanceLeftDel(t._key, t.val(), del, t.right());
			else
				return red(t._key, t.val(), del, t.right());
		}
		if (U.instanceof(t.right(), Black))
			return balanceRightDel(t._key, t.val(), t.left(), del);
		return red(t._key, t.val(), t.left(), del);
	}

	static function append(left:PTMNode, right:PTMNode):PTMNode {
		if (left == null)
			return right;
		else if (right == null)
			return left;
		else if (U.instanceof(left, Red)) {
			if (U.instanceof(right, Red)) {
				var app:PTMNode = append(left.right(), right.left());
				if (U.instanceof(app, Red))
					return red(app._key, app.val(), red(left._key, left.val(), left.left(), app.left()),
						red(right._key, right.val(), app.right(), right.right()));
				else
					return red(left._key, left.val(), left.left(), red(right._key, right.val(), app, right.right()));
			} else
				return red(left._key, left.val(), left.left(), append(left.right(), right));
		} else if (U.instanceof(right, Red))
			return red(right._key, right.val(), append(left, right.left()), right.right());
		else // black/black
		{
			var app:PTMNode = append(left.right(), right.left());
			if (U.instanceof(app, Red))
				return red(app._key, app.val(), black(left._key, left.val(), left.left(), app.left()),
					black(right._key, right.val(), app.right(), right.right()));
			else
				return balanceLeftDel(left._key, left.val(), left.left(), black(right._key, right.val(), app, right.right()));
		}
	}

	static public function balanceLeftDel(key:Any, val:Any, del:PTMNode, right:PTMNode):PTMNode {
		if (U.instanceof(del, Red))
			return red(key, val, del.blacken(), right);
		else if (U.instanceof(right, Black))
			return rightBalance(key, val, del, right.redden());
		else if (U.instanceof(right, Red) && U.instanceof(right.left(), Black))
			return red(right.left()._key, right.left().val(), black(key, val, del, right.left().left()),
				rightBalance(right._key, right.val(), right.left().right(), right.right().redden()));
		else
			throw new UnsupportedOperationException("Invariant violation");
	}

	static public function balanceRightDel(key:Any, val:Any, left:PTMNode, del:PTMNode):PTMNode {
		if (U.instanceof(del, Red))
			return red(key, val, left, del.blacken());
		else if (U.instanceof(left, Black))
			return leftBalance(key, val, left.redden(), del);
		else if (U.instanceof(left, Red) && U.instanceof(left.right(), Black))
			return red(left.right()._key, left.right().val(), leftBalance(left._key, left.val(), left.left().redden(), left.right().left()),
				black(key, val, left.right().right(), del));
		else
			throw new UnsupportedOperationException("Invariant violation");
	}

	static public function leftBalance(key:Any, val:Any, ins:PTMNode, right:PTMNode):PTMNode {
		if (U.instanceof(ins, Red) && U.instanceof(ins.left(), Red))
			return red(ins._key, ins.val(), ins.left().blacken(), black(key, val, ins.right(), right));
		else if (U.instanceof(ins, Red) && U.instanceof(ins.right(), Red))
			return red(ins.right()._key, ins.right().val(), black(ins._key, ins.val(), ins.left(), ins.right().left()),
				black(key, val, ins.right().right(), right));
		else
			return black(key, val, ins, right);
	}

	static public function rightBalance(key:Any, val:Any, left:PTMNode, ins:PTMNode):PTMNode {
		if (U.instanceof(ins, Red) && U.instanceof(ins.right(), Red))
			return red(ins._key, ins.val(), black(key, val, left, ins.left()), ins.right().blacken());
		else if (U.instanceof(ins, Red) && U.instanceof(ins.left(), Red))
			return red(ins.left()._key, ins.left().val(), black(key, val, left, ins.left().left()),
				black(ins._key, ins.val(), ins.left().right(), ins.right()));
		else
			return black(key, val, left, ins);
	}

	public function replace(t:PTMNode, key:Any, val:Any):PTMNode {
		var c:Int = doCompare(key, t._key);
		return t.replace(t._key, c == 0 ? val : t.val(), c < 0 ? replace(t.left(), key, val) : t.left(), c > 0 ? replace(t.right(), key, val) : t.right());
	}

	static public function red(key:Any, val:Any, left:PTMNode, right:PTMNode):Red {
		if (left == null && right == null) {
			if (val == null)
				return new Red(key);
			return new RedVal(key, val);
		}
		if (val == null)
			return new RedBranch(key, left, right);
		return new RedBranchVal(key, val, left, right);
	}

	static public function black(key:Any, val:Any, left:PTMNode, right:PTMNode):Black {
		if (left == null && right == null) {
			if (val == null)
				return new Black(key);
			return new BlackVal(key, val);
		}
		if (val == null)
			return new BlackBranch(key, left, right);
		return new BlackBranchVal(key, val, left, right);
	}

	public function meta():IPersistentMap {
		return _meta;
	}
}

// Node ==============================================================================================
abstract class PTMNode extends AMapEntry {
	public var _key:Any;

	public function new(key:Any) {
		_key = key;
	}

	override public function key():Any {
		return _key;
	}

	override public function val():Any {
		return null;
	}

	public function getKey():Any {
		return key();
	}

	public function getValue():Any {
		return val();
	}

	public function left():PTMNode {
		return null;
	}

	public function right():PTMNode {
		return null;
	}

	abstract public function addLeft(ins:PTMNode):PTMNode;

	abstract public function addRight(ins:PTMNode):PTMNode;

	abstract public function removeLeft(del:PTMNode):PTMNode;

	abstract public function removeRight(del:PTMNode):PTMNode;

	abstract public function blacken():PTMNode;

	abstract public function redden():PTMNode;

	public function balanceLeft(parent:PTMNode):PTMNode {
		return PersistentTreeMap.black(parent._key, parent.val(), this, parent.right());
	}

	public function balanceRight(parent:PTMNode):PTMNode {
		return PersistentTreeMap.black(parent._key, parent.val(), parent.left(), this);
	}

	abstract public function replace(key:Any, val:Any, left:PTMNode, right:PTMNode):PTMNode;

	public function kvreduce(f:IFn, init:Any):Any {
		if (left() != null) {
			init = left().kvreduce(f, init);
			if (RT.isReduced(init))
				return init;
		}
		init = f.invoke3(init, key(), val());
		if (RT.isReduced(init))
			return init;

		if (right() != null) {
			init = right().kvreduce(f, init);
		}
		return init;
	}
}

// Black =========================================================================================
class Black extends PTMNode {
	public function new(key:Any) {
		super(key);
	}

	public function addLeft(ins:PTMNode):PTMNode {
		return ins.balanceLeft(this);
	}

	public function addRight(ins:PTMNode):PTMNode {
		return ins.balanceRight(this);
	}

	public function removeLeft(del:PTMNode):PTMNode {
		return PersistentTreeMap.balanceLeftDel(_key, val(), del, right());
	}

	public function removeRight(del:PTMNode):PTMNode {
		return PersistentTreeMap.balanceRightDel(_key, val(), left(), del);
	}

	public function blacken():PTMNode {
		return this;
	}

	public function redden():PTMNode {
		return new Red(_key);
	}

	public function replace(key:Any, val:Any, left:PTMNode, right:PTMNode):PTMNode {
		return PersistentTreeMap.black(key, val, left, right);
	}
}

class BlackVal extends Black {
	var _val:Any;

	public function new(key:Any, val:Any) {
		super(key);
		this._val = val;
	}

	override public function val():Any {
		return _val;
	}

	override public function redden():PTMNode {
		return new RedVal(_key, _val);
	}
}

class BlackBranch extends Black {
	var _left:PTMNode;

	var _right:PTMNode;

	public function new(key:Any, left:PTMNode, right:PTMNode) {
		super(key);
		this._left = left;
		this._right = right;
	}

	override public function left():PTMNode {
		return _left;
	}

	override public function right():PTMNode {
		return _right;
	}

	override function redden():PTMNode {
		return new RedBranch(_key, _left, _right);
	}
}

class BlackBranchVal extends BlackBranch {
	var _val:Any;

	public function new(key:Any, val:Any, left:PTMNode, right:PTMNode) {
		super(key, left, right);
		this._val = val;
	}

	override public function val():Any {
		return _val;
	}

	override public function redden():PTMNode {
		return new RedBranchVal(_key, _val, _left, _right);
	}
}

// Red ===============================================================================

class Red extends PTMNode {
	public function new(key:Any) {
		super(key);
	}

	public function addLeft(ins:PTMNode):PTMNode {
		return PersistentTreeMap.red(_key, val(), ins, right());
	}

	public function addRight(ins:PTMNode):PTMNode {
		return PersistentTreeMap.red(_key, val(), left(), ins);
	}

	public function removeLeft(del:PTMNode):PTMNode {
		return PersistentTreeMap.red(_key, val(), del, right());
	}

	public function removeRight(del:PTMNode):PTMNode {
		return PersistentTreeMap.red(_key, val(), left(), del);
	}

	public function blacken():PTMNode {
		return new Black(_key);
	}

	public function redden():PTMNode {
		throw new UnsupportedOperationException("Invariant violation");
	}

	public function replace(key:Any, val:Any, left:PTMNode, right:PTMNode):PTMNode {
		return PersistentTreeMap.red(key, val, left, right);
	}
}

class RedVal extends Red {
	var _val:Any;

	public function new(key:Any, val:Any) {
		super(key);
		this._val = val;
	}

	override public function val():Any {
		return _val;
	}

	override public function blacken():PTMNode {
		return new BlackVal(_key, _val);
	}
}

class RedBranch extends Red {
	var _left:PTMNode;

	var _right:PTMNode;

	public function new(key:Any, left:PTMNode, right:PTMNode) {
		super(key);
		this._left = left;
		this._right = right;
	}

	override public function left():PTMNode {
		return _left;
	}

	override public function right():PTMNode {
		return _right;
	}

	override public function balanceLeft(parent:PTMNode):PTMNode {
		if (U.instanceof(_left, Red))
			return PersistentTreeMap.red(_key, val(), _left.blacken(), PersistentTreeMap.black(parent._key, parent.val(), _right, parent.right()));
		else if (U.instanceof(right, Red))
			return PersistentTreeMap.red(_right._key, _right.val(), PersistentTreeMap.black(key, val(), _left, _right.left()),
				PersistentTreeMap.black(parent._key, parent.val(), _right.right(), parent.right()));
		else
			return super.balanceLeft(parent);
	}

	override public function balanceRight(parent:PTMNode):PTMNode {
		if (U.instanceof(_right, Red))
			return PersistentTreeMap.red(_key, val(), PersistentTreeMap.black(parent._key, parent.val(), parent.left(), _left), _right.blacken());
		else if (U.instanceof(left, Red))
			return PersistentTreeMap.red(_left._key, _left.val(), PersistentTreeMap.black(parent._key, parent.val(), parent.left(), _left.left()),
				PersistentTreeMap.black(key, val(), _left.right(), _right));
		else
			return super.balanceRight(parent);
	}

	override public function blacken():PTMNode {
		return new BlackBranch(_key, _left, _right);
	}
}

class RedBranchVal extends RedBranch {
	var _val:Any;

	public function new(key:Any, val:Any, left:PTMNode, right:PTMNode) {
		super(key, left, right);
		this._val = val;
	}

	override public function val():Any {
		return _val;
	}

	override public function blacken():PTMNode {
		return new BlackBranchVal(_key, _val, _left, _right);
	}
}

// Seq ==================================================================================================
class PTMSeq extends ASeq {
	var stack:ISeq;
	var asc:Bool;
	var cnt:Int;

	static public function create2(stack:ISeq, asc:Bool):PTMSeq {
		return new PTMSeq(null, stack, asc, -1);
		/*this.stack = stack;
			this.asc = asc;
			this.cnt = -1; */
	}

	static public function create3(stack:ISeq, asc:Bool, cnt:Int):PTMSeq {
		/*this.stack = stack;
			this.asc = asc;
			this.cnt = cnt; */
		return new PTMSeq(null, stack, asc, cnt);
	}

	public function new(meta:IPersistentMap, stack:ISeq, asc:Bool, cnt:Int) {
		super(meta);
		this.stack = stack;
		this.asc = asc;
		this.cnt = cnt;
	}

	static public function createFromNode(t:PTMNode, asc:Bool, cnt:Int):PTMSeq {
		// return new Seq(push(t, null, asc), asc, cnt);
		return create3(push(t, null, asc), asc, cnt);
	}

	static public function push(t:PTMNode, stack:ISeq, asc:Bool):ISeq {
		while (t != null) {
			stack = RT.cons(t, stack);
			t = asc ? t.left() : t.right();
		}
		return stack;
	}

	public function first():Any {
		return stack.first();
	}

	public function next():ISeq {
		var t:PTMNode = cast stack.first();
		var nextstack:ISeq = push(asc ? t.right() : t.left(), stack.next(), asc);
		if (nextstack != null) {
			return PTMSeq.create3(nextstack, asc, cnt - 1);
		}
		return null;
	}

	override public function count():Int {
		if (cnt < 0)
			return super.count();
		return cnt;
	}

	public function withMeta(meta:IPersistentMap):Obj {
		if (super.meta() == meta)
			return this;
		return new PTMSeq(meta, stack, asc, cnt);
	}
}

// Iterators
class NodeIterator {
	var stack = new Array<Any>();
	var asc:Bool;

	public function new(t:PTMNode, asc:Bool) {
		this.asc = asc;
		push(t);
	}

	public function push(t:PTMNode) {
		while (t != null) {
			stack.push(t);
			t = asc ? t.left() : t.right();
		}
	}

	public function hasNext():Bool {
		return stack.length > 0;
	}

	public function next():Any {
		try {
			var t:PTMNode = stack.pop();
			push(asc ? t.right() : t.left());
			return t;
		} catch (e) {
			throw new NoSuchElementException();
		}
	}

	public function remove() {
		throw new UnsupportedOperationException();
	}
}

class KeyIterator {
	var it:NodeIterator;

	public function new(it:NodeIterator) {
		this.it = it;
	}

	public function hasNext():Bool {
		return it.hasNext();
	}

	public function next():Any {
		return cast(it.next(), PTMNode).key();
	}

	public function remove() {
		throw new UnsupportedOperationException();
	}
}

class ValIterator {
	var it:NodeIterator;

	public function new(it:NodeIterator) {
		this.it = it;
	}

	public function hasNext():Bool {
		return it.hasNext();
	}

	public function next():Any {
		return cast(it.next(), PTMNode).val();
	}

	public function remove() {
		throw new UnsupportedOperationException();
	}
}
