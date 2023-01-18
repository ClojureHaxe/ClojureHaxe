package lang;

class Compiler {
	static public final DEF:Symbol = Symbol.internNSname("def");
	static public final LOOP:Symbol = Symbol.internNSname("loop*");
	static public final RECUR:Symbol = Symbol.internNSname("recur");
	static public final IF:Symbol = Symbol.internNSname("if");
	static public final LET:Symbol = Symbol.internNSname("let*");
	static public final LETFN:Symbol = Symbol.internNSname("letfn*");
	static public final DO:Symbol = Symbol.internNSname("do");
	static public final FN:Symbol = Symbol.internNSname("fn*");
	static public final FNONCE:Symbol = cast Symbol.internNSname("fn*").withMeta(RT.map(Keyword.intern(null, "once"), RT.T));
	static public final QUOTE:Symbol = Symbol.internNSname("quote");
	static public final THE_VAR:Symbol = Symbol.internNSname("var");
	static public final DOT:Symbol = Symbol.internNSname(".");
	static public final ASSIGN:Symbol = Symbol.internNSname("set!");

	static public final _AMP_:Symbol = Symbol.internNSname("&");

	static public final NS:Symbol = Symbol.internNSname("ns");
	static public final IN_NS:Symbol = Symbol.internNSname("in-ns");

	static public function currentNS():Namespace {
		return RT.CURRENT_NS.deref();
	}

	static public function isSpecial(sym:Any):Bool {
		// TODO:
		// return specials.containsKey(sym);
		return false;
	}

	static public function maybeResolveIn(n:Namespace, sym:Symbol):Any {
		// note - ns-qualified vars must already exist
		if (sym.ns != null) {
			var ns:Namespace = namespaceFor2(n, sym);
			if (ns == null)
				return null;
			var v:Var = ns.findInternedVar(Symbol.internNSname(sym.name));
			if (v == null)
				return null;
			return v;
		} else if (sym.name.indexOf('.') > 0 && !StringTools.endsWith(sym.name, ".") || sym.name.charAt(0) == '[') {
			try {
				return RT.classForName(sym.name);
			} catch (e) {
				/*if (U.instanceof(e,  ClassNotFoundException))
						return null;
					else
						return Util.sneakyThrow(e);
				 */
				return null;
			}
		} else if (sym.equals(NS))
			return RT.NS_VAR;
		else if (sym.equals(IN_NS))
			return RT.IN_NS_VAR;
		else {
			var o:Any = n.getMapping(sym);
			return o;
		}
	}

	static public function resolveSymbol(sym:Symbol):Symbol {
		// already qualified or classname?
		if (sym.name.indexOf('.') > 0)
			return sym;
		if (sym.ns != null) {
			var ns:Namespace = namespaceFor(sym);
			if (ns == null || (ns.name.name == null ? sym.ns == null : ns.name.name == sym.ns))
				return sym;
			return Symbol.intern(ns.name.name, sym.name);
		}
		var o:Any = currentNS().getMapping(sym);
		if (o == null)
			return Symbol.intern(currentNS().name.name, sym.name);
		else if (U.instanceof(o, Class))
			return Symbol.intern(null, Type.getClassName(o));
		else if (U.instanceof(o, Var)) {
			var v:Var = cast o;
			return Symbol.intern(v.ns.name.name, v.sym.name);
		}
		return null;
	}

	public static function namesStaticMember(sym:Symbol):Bool {
		return sym.ns != null && namespaceFor(sym) == null;
	}

	static public function namespaceFor(sym:Symbol):Namespace {
		return namespaceFor2(currentNS(), sym);
	}

	static public function namespaceFor2(inns:Namespace, sym:Symbol):Namespace {
		// note, presumes non-nil sym.ns
		// first check against currentNS' aliases...
		var nsSym:Symbol = Symbol.internNSname(sym.ns);
		var ns:Namespace = inns.lookupAlias(nsSym);
		if (ns == null) {
			// ...otherwise check the Namespaces map.
			ns = Namespace.find(nsSym);
		}
		return ns;
	}
}
