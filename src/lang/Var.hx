package lang;

import lang.exceptions.IllegalStateException;
import lang.exceptions.IllegalArgumentException;
import lang.misc.Thread;
import haxe.ds.Vector;

final class Var extends ARef implements IFn implements IRef implements Settable // , Serializable
{
	static var dvals:Frame = Frame.TOP;

	@:volatile static public var rev:Int = 0;

	static var privateKey:Keyword = Keyword.create(null, "private");
	static var privateMeta:IPersistentMap = {
		var v:Vector<Any> = new Vector<Any>(2);
		v[0] = privateKey;
		v[1] = true;
		PersistentArrayMap.createFromArray(v);
	}
	static var macroKey:Keyword = Keyword.create(null, "macro");
	static var nameKey:Keyword = Keyword.create(null, "name");
	static var nsKey:Keyword = Keyword.create(null, "ns");

	@:volatile var root:Any;

	@:volatile var dyn:Bool = false;
	@:transient var threadBound:Bool = false;

	public var sym:Symbol;
	public var ns:Namespace;

	public static function getThreadBindingFrame():Any {
		return dvals;
	}

	public static function cloneThreadBindingFrame():Any {
		// return dvals.get().clone();
		return dvals.clone();
	}

	public static function resetThreadBindingFrame(frame:Any) {
		dvals = frame;
	}

	public function setDynamic(?b:Bool = true):Var {
		this.dyn = b;
		return this;
	}

	public function isDynamic():Bool {
		return dyn;
	}

	public static function intern3(ns:Namespace, sym:Symbol, root:Any):Var {
		return intern4(ns, sym, root, true);
	}

	public static function intern4(ns:Namespace, sym:Symbol, root:Any, replaceRoot:Bool):Var {
		// trace(">>>>>>>>>>>>>>>> Var intern4 :" + ns + "   " + sym + " " + root + " " + replaceRoot);
		var dvout:Var = ns.intern(sym);
		if (!dvout.hasRoot() || replaceRoot)
			dvout.bindRoot(root);
		return dvout;
	}

	public function toSymbol():Symbol {
		return Symbol.create((ns == null ? null : ns.name.name), sym.name);
	}

	public function toString():String {
		if (ns != null)
			return "#'" + ns.name + "/" + sym;
		return "#<Var: " + (sym != null ? sym.toString() : "--unnamed--") + ">";
	}

	public static function find(nsQualifiedSym:Symbol):Var {
		if (nsQualifiedSym.ns == null)
			throw new IllegalArgumentException("Symbol must be namespace-qualified");
		var ns:Namespace = Namespace.find(Symbol.internNSname(nsQualifiedSym.ns));
		if (ns == null)
			throw new IllegalArgumentException("No such namespace: " + nsQualifiedSym.ns);
		return ns.findInternedVar(Symbol.internNSname(nsQualifiedSym.name));
	}

	public static function internSym(nsName:Symbol, sym:Symbol):Var {
		var ns:Namespace = Namespace.findOrCreate(nsName);
		return intern(ns, sym);
	}

	public static function internPrivate(nsName:String, sym:String):Var {
		var ns:Namespace = Namespace.findOrCreate(Symbol.internNSname(nsName));
		var ret:Var = intern(ns, Symbol.internNSname(sym));
		ret.setMeta(privateMeta);
		return ret;
	}

	public static function intern(ns:Namespace, sym:Symbol):Var {
		return ns.intern(sym);
	}

	public static function create():Var {
		return new Var(null, null);
	}

	public static function create1(root:Any):Var {
		return new3(null, null, root);
	}

	public function new(ns:Namespace, sym:Symbol) {
		super();
		this.ns = ns;
		this.sym = sym;
		this.threadBound = false; // new AtomicBoolean(false);
		this.root = new Unbound(this);
		setMeta(PersistentHashMap.EMPTY);
	}

	public static function new3(ns:Namespace, sym:Symbol, root:Any):Var {
		var v:Var = new Var(ns, sym);
		v.root = root;
		++rev;
		return v;
	}

	public function isBound():Bool {
		return hasRoot() || (threadBound && dvals.bindings.containsKey(this));
	}

	public function get():Any {
		if (!threadBound)
			return root;
		return deref();
	}

	public function deref():Any {
		var b:TBox = getThreadBinding();
		if (b != null)
			return b.val;
		return root;
	}

	override public function setValidator(vf:IFn) {
		if (hasRoot())
			validate(vf, root);
		validator = vf;
	}

	public function alter(fn:IFn, args:ISeq):Any {
		set(fn.applyTo(RT.cons(deref(), args)));
		return this;
	}

	// TODO: Thread
	public function set(val:Any):Any {
		validate(getValidator(), val);
		var b:TBox = getThreadBinding();
		if (b != null) {
			if (!Thread.equals(Thread.currentThread(), b.thread))
				throw new IllegalStateException("Can't set!: " + sym + " from non-binding thread");
			return (b.val = val);
		}
		throw new IllegalStateException("Can't change/establish root binding of: " + sym + " with set");
	}

	public function doSet(val:Any):Any {
		return set(val);
	}

	public function doReset(val:Any):Any {
		bindRoot(val);
		return val;
	}

	public function setMeta(m:IPersistentMap) {
		// ensure these basis keys
		resetMeta((cast m.assoc(nameKey, sym)).assoc(nsKey, ns));
	}

	// TODO;
	public function setMacro() {
		alterMeta(assoc, RT.list(macroKey, RT.T));
	}

	public function isMacro():Bool {
		return RT.booleanCast(meta().valAt(macroKey));
	}

	public function isPublic():Bool {
		return !RT.booleanCast(meta().valAt(privateKey));
	}

	public function getRawRoot():Any {
		return root;
	}

	public function getTag():Any {
		return meta().valAt(RT.TAG_KEY);
	}

	public function setTag(tag:Symbol) {
		alterMeta(assoc, RT.list(RT.TAG_KEY, tag));
	}

	public function hasRoot():Bool {
		return !(U.instanceof(root, Unbound));
	}

	/*synchronized*/
	public function bindRoot(root:Any) {
		validate(getValidator(), root);
		var oldroot:Any = this.root;
		this.root = root;
		++rev;
		alterMeta(dissoc, RT.list(macroKey));
		notifyWatches(oldroot, this.root);
	}

	/*synchronized*/
	public function swapRoot(root:Any) {
		validate(getValidator(), root);
		var oldroot:Any = this.root;
		this.root = root;
		++rev;
		notifyWatches(oldroot, root);
	}

	/*synchronized*/
	public function unbindRoot() {
		this.root = new Unbound(this);
		++rev;
	}

	/*synchronized*/
	public function commuteRoot(fn:IFn) {
		var newRoot:Any = fn.invoke(root);
		validate(getValidator(), newRoot);
		var oldroot:Any = root;
		this.root = newRoot;
		++rev;
		notifyWatches(oldroot, newRoot);
	}

	/*synchronized*/
	public function alterRoot(fn:IFn, args:ISeq):Any {
		var newRoot:Any = fn.applyTo(RT.cons(root, args));
		validate(getValidator(), newRoot);
		var oldroot:Any = root;
		this.root = newRoot;
		++rev;
		notifyWatches(oldroot, newRoot);
		return newRoot;
	}

	public static function pushThreadBindings(bindings:Associative) {
		var f:Frame = dvals;
		var bmap:Associative = f.bindings;
		var bs:ISeq = bindings.seq();
		while (bs != null) {
			var e:IMapEntry = cast(bs.first(), IMapEntry);
			var v:Var = cast e.key();
			if (!v.dyn)
				throw new IllegalStateException("Can't dynamically bind non-dynamic var: " + v.ns + "/" + v.sym);
			v.validate(v.getValidator(), e.val());
			v.threadBound = true;
			bmap = bmap.assoc(v, new TBox(Thread.currentThread(), e.val()));
			bs = bs.next();
		}
		dvals = new Frame(bmap, f);
	}

	public static function popThreadBindings() {
		var f:Frame = dvals.prev;
		if (f == null) {
			throw new IllegalStateException("Pop without matching push");
		} else if (f == Frame.TOP) {
			// TODO:
			// dvals.remove();
			dvals = f;
		} else {
			dvals = f; // .set(f);
		}
	}

	public static function getThreadBindings():Associative {
		var f:Frame = dvals; //  dvals.get();
		var ret:IPersistentMap = PersistentHashMap.EMPTY;
		var bs:ISeq = f.bindings.seq();
		while (bs != null) {
			var e:IMapEntry = bs.first();
			var v:Var = e.key();
			var b:TBox = e.val();
			ret = cast ret.assoc(v, b.val);
			bs = bs.next();
		}
		return ret;
	}

	public function getThreadBinding():TBox {
		if (threadBound) {
			var e:IMapEntry = dvals.bindings.entryAt(this);
			if (e != null)
				return cast e.val();
		}
		return null;
	}

	public function fn():IFn {
		return deref();
	}

	static final assoc:IFn = new AssocFN();
	static final dissoc:IFn = new DissocFN();
}

class AssocFN extends AFn {
	public function new() {}

	override public function invoke3(m:Any, k:Any, v:Any):Any {
		return RT.assoc(m, k, v);
	}
}

class DissocFN extends AFn {
	public function new() {}

	override public function invoke2(c:Any, k:Any):Any {
		return RT.dissoc(c, k);
	}
}

class TBox {
	@:volatile public var val:Any;

	public var thread:Any;

	public function new(t:Any, val:Any) {
		this.thread = t;
		this.val = val;
	}
}

class Unbound extends AFn {
	var v:Var;

	public function new(v:Var) {
		this.v = v;
	}

	public function toString():String {
		return "Unbound: " + v;
	}

	override public function throwArity(n:Int):Any {
		throw new IllegalStateException("Attempting to call unbound fn: " + v);
	}
}

class Frame {
	public static final TOP:Frame = new Frame(PersistentHashMap.EMPTY, null);

	// Var->TBox
	public var bindings:Associative;

	// Var->val
	//	Associative frameBindings;
	public var prev:Frame;

	public function new(bindings:Associative, prev:Frame) {
		//		this.frameBindings = frameBindings;
		this.bindings = bindings;
		this.prev = prev;
	}

	public function clone():Frame {
		return new Frame(this.bindings, null);
	}
}
