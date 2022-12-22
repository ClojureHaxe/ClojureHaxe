package lang;

import lang.exceptions.IllegalArgumentException;
import lang.exceptions.IllegalStateException;
import lang.exceptions.NullPointerException;

// TODO: make concurent
class Namespace extends AReference {
	public var name:Symbol;

	public var mappings:IPersistentMap;
	public var aliases:IPersistentMap;

	public static var namespaces:Map<Symbol, Namespace> = new Map<Symbol, Namespace>();

	public function toString():String {
		return name.toString();
	}

	public function new(name:Symbol) {
		super(name.meta());
		this.name = name;
		mappings = RT.DEFAULT_IMPORTS;
		aliases = RT.map();
	}

	public function all():ISeq {
		return RT.seq(namespaces.iterator());
	}

	public function getName():Symbol {
		return name;
	}

	public function getMappings():IPersistentMap {
		return mappings;
	}

	private function isInternedMapping(sym:Symbol, o:Any):Bool {
		return (U.instanceof(o, Var) && cast(o, Var).ns == this && cast(o, Var).sym.equals(sym));
	}

	public function intern(sym:Symbol):Var {
		if (sym.ns != null) {
			throw new IllegalArgumentException("Can't intern namespace-qualified symbol");
		}

		var map:IPersistentMap = getMappings();
		var o:Any;
		var v:Var = null;

		if ((o = map.valAt(sym)) == null) {
			if (v == null) {
				v = new Var(this, sym);
			}
			mappings = cast mappings.assoc(sym, v);
		}

		/*while ((o = map.valAt(sym)) == null) {
			if (v == null)
				v = new Var(this, sym);
			var newMap:IPersistentMap = cast map.assoc(sym, v);
			mappings.compareAndSet(map, newMap);
			map = getMappings();
		}*/

		if (isInternedMapping(sym, o))
			return o;

		if (v == null)
			v = new Var(this, sym);

		if (checkReplacement(sym, o, v)) {
			mappings = cast mappings.assoc(sym, v);
			// while (!mappings.compareAndSet(map, map.assoc(sym, v)))
			//	map = getMappings();

			return v;
		}

		return o;
	}

	/*
		 This method checks if a namespace's mapping is applicable and warns on problematic cases.
		 It will return a boolean indicating if a mapping is replaceable.
		 The semantics of what constitutes a legal replacement mapping is summarized as follows:

		| classification | in namespace ns        | newval = anything other than ns/name | newval = ns/name                    |
		|----------------+------------------------+--------------------------------------+-------------------------------------|
		| native mapping | name -> ns/name        | no replace, warn-if newval not-core  | no replace, warn-if newval not-core |
		| alias mapping  | name -> other/whatever | warn + replace                       | warn + replace                      |
	 */
	private function checkReplacement(sym:Symbol, old:Any, neu:Any):Bool {
		if (U.instanceof(old, Var)) {
			var ons:Namespace = cast(old, Var).ns;
			var nns:Namespace = U.instanceof(neu, Var) ? cast(neu, Var).ns : null;

			if (isInternedMapping(sym, old)) {
				if (nns != RT.CLOJURE_NS) {
					RT.errPrint("REJECTED: attempt to replace interned var " + old + " with " + neu + " in " + name + ", you must ns-unmap first");
					return false;
				} else
					return false;
			}
		}
		RT.errPrint("WARNING: " + sym + " already refers to: " + old + " in namespace: " + name + ", being replaced by: " + neu);
		return true;
	}

	private function reference(sym:Symbol, val:Any):Any {
		if (sym.ns != null) {
			throw new IllegalArgumentException("Can't intern namespace-qualified symbol");
		}

		var map:IPersistentMap = getMappings();
		var o:Any;
		if ((o = map.valAt(sym)) == null) {
			var newMap:IPersistentMap = cast map.assoc(sym, val);
			// mappings.compareAndSet(map, newMap);
			mappings = newMap;
			map = getMappings();
		}
		if (o == val)
			return o;

		if (checkReplacement(sym, o, val)) {
			mappings = cast map.assoc(sym, val);
			// while (!mappings.compareAndSet(map, map.assoc(sym, val)))
			//     map = getMappings();

			return val;
		}

		return o;
	}

	public static function areDifferentInstancesOfSameClassName(cls1:Class<Any>, cls2:Class<Any>):Bool {
		return (cls1 != cls2); // && (cls1.getName().equals(cls2.getName()));
	}

	private function referenceClass(sym:Symbol, val:Any):Any {
		if (sym.ns != null) {
			throw new IllegalArgumentException("Can't intern namespace-qualified symbol");
		}
		var map:IPersistentMap = getMappings();
		var c:Any = map.valAt(sym);
		while ((c == null) || (areDifferentInstancesOfSameClassName(c, val))) {
			var newMap:IPersistentMap = cast map.assoc(sym, val);
			// mappings.compareAndSet(map, newMap);
			mappings = newMap;
			map = getMappings();
			c = map.valAt(sym);
		}
		if (c == val)
			return c;

		throw new IllegalStateException(sym + " already refers to: " + c + " in namespace: " + name);
		return null;
	}

	public function unmap(sym:Symbol) {
		if (sym.ns != null) {
			throw new IllegalArgumentException("Can't unintern namespace-qualified symbol");
		}
		var map:IPersistentMap = getMappings();
		while (map.containsKey(sym)) {
			var newMap:IPersistentMap = map.without(sym);
			// mappings.compareAndSet(map, newMap);
			mappings = newMap;
			map = getMappings();
		}
	}

	public function importClass(sym:Symbol, c:Any):Any {
		return referenceClass(sym, c);
	}

	public function importClassClass(c:Any):Any {
		// String n = c.getName();
		var n:String = Type.getClassName(cast c);
		return importClass(Symbol.internNSname(n.substring(n.lastIndexOf('.') + 1)), c);
	}

	public function refer(sym:Symbol, v:Var):Var {
		return cast reference(sym, v);
	}

	public static function findOrCreate(name:Symbol):Namespace {
		var ns:Namespace = namespaces.get(name);
		if (ns != null)
			return ns;
		var newns:Namespace = new Namespace(name);
		namespaces.set(name, newns);
		return newns;
		/*if (namespaces.get(name) == null) {
			namespaces.set(name, newns);
		}*/
		// ns = namespaces.putIfAbsent(name, newns);
		// return ns == null ? newns : ns;
	}

	public static function remove(name:Symbol):Namespace {
		if (name.equals(RT.CLOJURE_NS.name))
			throw new IllegalArgumentException("Cannot remove clojure namespace");
		var v:Namespace = namespaces.get(name);
		namespaces.remove(name);
		return v;
	}

	public static function find(name:Symbol):Namespace {
		return namespaces.get(name);
	}

	public function findInternedVar(symbol:Symbol):Var {
		var o:Any = mappings.valAt(symbol);
		if (o != null && U.instanceof(o, Var) && cast(o, Var).ns == this)
			return cast o;
		return null;
	}

	public function getAliases():IPersistentMap {
		return aliases;
	}

	public function lookupAlias(alias:Symbol):Namespace {
		var map:IPersistentMap = getAliases();
		return map.valAt(alias);
	}

	public function addAlias(alias:Symbol, ns:Namespace) {
		if (alias == null || ns == null)
			throw new NullPointerException("Expecting Symbol + Namespace");
		var map:IPersistentMap = getAliases();
		while (!map.containsKey(alias)) {
			var newMap:IPersistentMap = cast map.assoc(alias, ns);
			// aliases.compareAndSet(map, newMap);
			aliases = newMap;
			map = getAliases();
		}
		// you can rebind an alias, but only to the initially-aliased namespace.
		if (cast(map.valAt(alias), Namespace).name.equals(ns.name))
			throw new IllegalStateException("Alias " + alias + " already exists in namespace " + name + ", aliasing " + map.valAt(alias));
	}

	public function removeAlias(alias:Symbol) {
		var map:IPersistentMap = getAliases();
		while (map.containsKey(alias)) {
			var newMap:IPersistentMap = map.without(alias);
			// aliases.compareAndSet(map, newMap);
			aliases = newMap;
			map = getAliases();
		}
	}

	private function readResolve():Any {
		// ensures that serialized namespaces are "deserialized" to the
		// namespace in the present runtime
		return findOrCreate(name);
	}
}
