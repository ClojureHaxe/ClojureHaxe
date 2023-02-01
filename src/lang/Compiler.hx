package lang;

import haxe.Exception;
import lang.exceptions.IllegalArgumentException;
import lang.exceptions.IllegalStateException;
import lang.exceptions.ArityException;
import lang.compiler.*;

enum C {
	STATEMENT; // value ignored
	EXPRESSION; // value required
	RETURN; // tail position relative to enclosing recur frame
	EVAL;
}

enum PATHTYPE {
	PATH;
	BRANCH;
}

enum PSTATE {
	REQ;
	REST;
	DONE;
}

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
	static public final TRY:Symbol = Symbol.intern1("try");
	static public final CATCH:Symbol = Symbol.intern1("catch");
	static public final FINALLY:Symbol = Symbol.intern1("finally");
	static public final THROW:Symbol = Symbol.intern1("throw");
	static public final MONITOR_ENTER:Symbol = Symbol.intern1("monitor-enter");
	static public final MONITOR_EXIT:Symbol = Symbol.intern1("monitor-exit");
	static public final IMPORT:Symbol = Symbol.intern("clojure.core", "import*");
	static public final DEFTYPE:Symbol = Symbol.intern1("deftype*");
	static public final CASE:Symbol = Symbol.intern1("case*");

	static final CLASS:Symbol = Symbol.intern1("Class");
	static final NEW:Symbol = Symbol.intern1("new");
	static final THIS:Symbol = Symbol.intern1("this");
	static final REIFY:Symbol = Symbol.intern1("reify*");

	static final LIST:Symbol = Symbol.intern("clojure.core", "list");
	static final HASHMAP:Symbol = Symbol.intern("clojure.core", "hash-map");
	static final VECTOR:Symbol = Symbol.intern("clojure.core", "vector");
	static final IDENTITY:Symbol = Symbol.intern("clojure.core", "identity");

	static public final _AMP_:Symbol = Symbol.internNSname("&");
	static final ISEQ:Symbol = Symbol.intern1("clojure.lang.ISeq");

	static final loadNs:Keyword = Keyword.intern(null, "load-ns");
	static final inlineKey:Keyword = Keyword.intern(null, "inline");
	static final inlineAritiesKey:Keyword = Keyword.intern(null, "inline-arities");
	static final staticKey:Keyword = Keyword.intern(null, "static");
	static public final arglistsKey:Keyword = Keyword.intern(null, "arglists");
	static final INVOKE_STATIC:Symbol = Symbol.intern1("invokeStatic");

	static final volatileKey:Keyword = Keyword.intern(null, "volatile");
	static final implementsKey:Keyword = Keyword.intern(null, "implements");
	static final COMPILE_STUB_PREFIX:String = "compile__stub";

	static final protocolKey:Keyword = Keyword.intern(null, "protocol");
	static final onKey:Keyword = Keyword.intern(null, "on");
	static public final dynamicKey:Keyword = Keyword.intern1("dynamic");
	static public final redefKey:Keyword = Keyword.intern(null, "redef");

	static public final NS:Symbol = Symbol.internNSname("ns");
	static public final IN_NS:Symbol = Symbol.internNSname("in-ns");

	static public final specials:IPersistentMap = PersistentHashMap.create( //
		DEF, new DefExpr.DefExprParser(), //
		// LOOP, new LetExpr.Parser(),
		// RECUR, new RecurExpr.Parser(),
		IF, new IfExpr.IfExprParser(), //
		// CASE, new CaseExpr.Parser(),
		LET, new LetExpr.LetExprParser(), //
		// LETFN, new LetFnExpr.Parser(),
		// DO, new BodyExpr.Parser(),
		// FN, null,
		// QUOTE, new ConstantExpr.Parser(),
		// THE_VAR, new TheVarExpr.Parser(),
		// IMPORT, new ImportExpr.Parser(),
		// DOT, new HostExpr.Parser(),
		// ASSIGN, new AssignExpr.Parser(),
		// DEFTYPE, new NewInstanceExpr.DeftypeParser(),
		// REIFY, new NewInstanceExpr.ReifyParser(),
		// TRY, new TryExpr.Parser(),
		// THROW, new ThrowExpr.Parser(),
		// MONITOR_ENTER, new MonitorEnterExpr.Parser(),
		// MONITOR_EXIT, new MonitorExitExpr.Parser(),
		// CATCH, null,
		// FINALLY, null,
		// NEW, new NewExpr.Parser(),
		_AMP_, null);

	private static final MAX_POSITIONAL_ARITY:Int = 20;
	// symbol->localbinding
	static public final LOCAL_ENV:Var = Var.create1(null).setDynamic();
	// vector<localbinding>
	static public final LOOP_LOCALS:Var = Var.create().setDynamic();
	// Label
	static public final LOOP_LABEL:Var = Var.create().setDynamic();
	// vector<object>
	static public final CONSTANTS:Var = Var.create().setDynamic();
	// IdentityHashMap
	static public final CONSTANT_IDS:Var = Var.create().setDynamic();
	// vector<keyword>
	static public final KEYWORD_CALLSITES:Var = Var.create().setDynamic();
	// vector<var>
	static public final PROTOCOL_CALLSITES:Var = Var.create().setDynamic();
	// set<var>
	static public final VAR_CALLSITES:Var = Var.create().setDynamic();
	// keyword->constid
	static public final KEYWORDS:Var = Var.create().setDynamic();
	// var->constid
	static public final VARS:Var = Var.create().setDynamic();
	// FnFrame
	static public final METHOD:Var = Var.create1(null).setDynamic();
	// null or not
	static public final IN_CATCH_FINALLY:Var = Var.create1(null).setDynamic();
	static public final METHOD_RETURN_CONTEXT:Var = Var.create1(null).setDynamic();
	static public final NO_RECUR:Var = Var.create1(null).setDynamic();
	// DynamicClassLoader
	static public final LOADER:Var = Var.create().setDynamic();
	// String
	static public final SOURCE:Var = Var.intern3(Namespace.findOrCreate(Symbol.intern1("clojure.core")), Symbol.intern1("*source-path*"), "NO_SOURCE_FILE")
		.setDynamic();
	// String
	static public final SOURCE_PATH:Var = Var.intern3(Namespace.findOrCreate(Symbol.intern1("clojure.core")), Symbol.intern1("*file*"), "NO_SOURCE_PATH")
		.setDynamic();
	// String
	static public final COMPILE_PATH:Var = Var.intern3(Namespace.findOrCreate(Symbol.intern1("clojure.core")), Symbol.intern1("*compile-path*"), null)
		.setDynamic();
	// boolean
	static public final COMPILE_FILES = Var.intern3(Namespace.findOrCreate(Symbol.intern1("clojure.core")), Symbol.intern1("*compile-files*"), false)
		.setDynamic();
	static public final INSTANCE:Var = Var.intern(Namespace.findOrCreate(Symbol.intern1("clojure.core")), Symbol.intern1("instance?"));
	static public final ADD_ANNOTATIONS:Var = Var.intern(Namespace.findOrCreate(Symbol.intern1("clojure.core")), Symbol.intern1("add-annotations"));

	static public final disableLocalsClearingKey:Keyword = Keyword.intern1("disable-locals-clearing");
	static public final directLinkingKey:Keyword = Keyword.intern1("direct-linking");
	static public final elideMetaKey:Keyword = Keyword.intern1("elide-meta");

	// TODO: read system props from env?
	static public var COMPILER_OPTIONS:Var = Var.intern3(Namespace.findOrCreate(Symbol.intern1("clojure.core")), Symbol.intern1("*compiler-options*"),
		PersistentArrayMap.EMPTY)
		.setDynamic();

	static public function getCompilerOption(k:Keyword):Any {
		return RT.get(COMPILER_OPTIONS.deref(), k);
	}

	static public function elideMeta(m:Any) {
		var elides:Any = getCompilerOption(elideMetaKey);
		if (elides != null) {
			for (k in U.getIterator(elides)) {
				m = RT.dissoc(m, k);
			}
		}
		return m;
	}

	// Integer
	static public final LINE:Var = Var.create1(0).setDynamic();
	static public final COLUMN:Var = Var.create1(0).setDynamic();

	static public function lineDeref():Int {
		return LINE.deref();
	}

	static public function columnDeref():Int {
		return COLUMN.deref();
	}

	// Integer
	static public final LINE_BEFORE:Var = Var.create1(0).setDynamic();
	static public final COLUMN_BEFORE:Var = Var.create1(0).setDynamic();
	static public final LINE_AFTER:Var = Var.create1(0).setDynamic();
	static public final COLUMN_AFTER:Var = Var.create1(0).setDynamic();

	// Integer
	static public final NEXT_LOCAL_NUM:Var = Var.create1(0).setDynamic();

	// Integer
	static public final RET_LOCAL_NUM:Var = Var.create().setDynamic();

	static public final COMPILE_STUB_SYM:Var = Var.create1(null).setDynamic();
	static public final COMPILE_STUB_CLASS:Var = Var.create1(null).setDynamic();

	// PathNode chain
	static public final CLEAR_PATH:Var = Var.create1(null).setDynamic();

	// tail of PathNode chain
	static public final CLEAR_ROOT:Var = Var.create1(null).setDynamic();

	// LocalBinding -> Set<LocalBindingExpr>
	static public final CLEAR_SITES:Var = Var.create1(null).setDynamic();

	// 370
	static public function isSpecial(sym:Any):Bool {
		return specials.containsKey(sym);
	}

	// 374
	static function inTailCall(context:C):Bool {
		return (context == C.RETURN) && (METHOD_RETURN_CONTEXT.deref() != null) && (IN_CATCH_FINALLY.deref() == null);
	}

	// ====================================================================================================
	// Exprs
	// ====================================================================================================
	static public final NIL_EXPR:NilExpr = new NilExpr();
	static public final TRUE_EXPR:BooleanExpr = new BooleanExpr(true);
	static public final FALSE_EXPR:BooleanExpr = new BooleanExpr(false);

	// ====================================================================================================
	// Munge
	// ====================================================================================================
	static public final CHAR_MAP:IPersistentMap = PersistentHashMap.create( //
		'-', "_", //
		':', "_COLON_", //
		'+', "_PLUS_", //
		'>', "_GT_", //
		'<', "_LT_", //
		'=', "_EQ_", //
		'~', "_TILDE_", //
		'!', "_BANG_", //
		'@', "_CIRCA_", //
		'#', "_SHARP_", //
		'\'', "_SINGLEQUOTE_", //
		'"', "_DOUBLEQUOTE_", //
		'%', "_PERCENT_", //
		'^', "_CARET_", //
		'&', "_AMPERSAND_", //
		'*', "_STAR_", //
		'|', "_BAR_", //
		'{', "_LBRACE_", //
		'}', "_RBRACE_", //
		'[', "_LBRACK_", //
		']', "_RBRACK_", //
		'/', "_SLASH_", //
		'\\', "_BSLASH_", //
		'?',
		"_QMARK_");

	// static  public final  DEMUNGE_MAP:IPersistentMap;
	// static  public final Pattern DEMUNGE_PATTERN;

	static public function munge(name:String):String {
		var sb:StringBuf = new StringBuf();
		var i:Int = 0;
		while (i < name.length) {
			var c:String = name.charAt(i);
			var sub:String = CHAR_MAP.valAt(c);
			if (sub != null)
				sb.add(sub);
			else
				sb.add(c);
			i++;
		}
		return sb.toString();
	}

	// ====================================================================================================
	// END Munge
	// ====================================================================================================

	static function clearPathRoot():PathNode {
		return CLEAR_ROOT.get();
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

	static public function resolve2(sym:Symbol, allowPrivate:Bool):Any {
		return resolveIn(currentNS(), sym, allowPrivate);
	}

	static public function resolve(sym:Symbol):Any {
		return resolveIn(currentNS(), sym, false);
	}

	static public function namespaceFor(sym:Symbol):Namespace {
		return namespaceFor2(currentNS(), sym);
	}

	static public function namespaceFor2(inns:Namespace, sym:Symbol):Namespace {
		var nsSym:Symbol = Symbol.internNSname(sym.ns);
		var ns:Namespace = inns.lookupAlias(nsSym);
		if (ns == null) {
			ns = Namespace.find(nsSym);
		}
		return ns;
	}

	static public function resolveIn(n:Namespace, sym:Symbol, allowPrivate:Bool):Any {
		// note - ns-qualified vars must already exist
		if (sym.ns != null) {
			var ns:Namespace = namespaceFor2(n, sym);
			if (ns == null)
				throw Util.runtimeException("No such namespace: " + sym.ns);

			var v:Var = ns.findInternedVar(Symbol.intern1(sym.name));
			if (v == null)
				throw Util.runtimeException("No such var: " + sym);
			else if (v.ns != currentNS() && !v.isPublic() && !allowPrivate)
				throw new IllegalStateException("var: " + sym + " is not public");
			return v;
		} else if (sym.name.indexOf('.') > 0 || sym.name.charAt(0) == '[') {
			return RT.classForName(sym.name);
		} else if (sym.equals(NS))
			return RT.NS_VAR;
		else if (sym.equals(IN_NS))
			return RT.IN_NS_VAR;
		else {
			if (Util.equals(sym, COMPILE_STUB_SYM.get()))
				return COMPILE_STUB_CLASS.get();
			var o:Any = n.getMapping(sym);
			if (o == null) {
				if (RT.booleanCast(RT.ALLOW_UNRESOLVED_VARS.deref())) {
					return sym;
				} else {
					throw Util.runtimeException("Unable to resolve symbol: " + sym + " in this context");
				}
			}
			return o;
		}
	}

	public static function registerLocal(sym:Symbol, tag:Symbol, init:Expr, isArg:Bool):LocalBinding {
		var num:Int = getAndIncLocalNum();
		var b:LocalBinding = new LocalBinding(num, sym, tag, init, isArg, clearPathRoot());
		var localsMap:IPersistentMap = LOCAL_ENV.deref();
		LOCAL_ENV.set(RT.assoc(localsMap, b.sym, b));
		var method:ObjMethod = METHOD.deref();
		method.locals = cast RT.assoc(method.locals, b, b);
		method.indexlocals = cast RT.assoc(method.indexlocals, num, b);
		return b;
	}

	private static function getAndIncLocalNum():Int {
		var num:Int = NEXT_LOCAL_NUM.deref();
		var m:ObjMethod = METHOD.deref();
		if (num > m.maxLocal)
			m.maxLocal = num;
		NEXT_LOCAL_NUM.set(num + 1);
		return num;
	}

	// 6200
	public static function analyze(context:C, form:Any):Expr {
		return analyze3(context, form, null);
	}

	public static function analyze3(context:C, form:Any, name:String):Expr {
		try {
			if (U.instanceof(form, LazySeq)) {
				var mform:Any = form;
				form = RT.seq(form);
				if (form == null)
					form = PersistentList.EMPTY;
				form = cast(form, IObj).withMeta(RT.meta(mform));
			}
			if (form == null)
				return NIL_EXPR;
			else if (RT.T == form #if (cpp || python) && U.isBool(form) #end) // isBool check only for CPP and Python cause 1 == true
				return TRUE_EXPR;
			else if (RT.F == form #if (cpp || python) && U.isBool(form) #end) // isBool check only for CPP and Python  cause 1 == true
				return FALSE_EXPR;
			if (U.instanceof(form, Symbol))
				return analyzeSymbol(form);
			else if (U.instanceof(form, Keyword))
				return registerKeyword(form);
			else if (U.isNumber(form))
				return NumberExpr.parse(form);
			else if (U.instanceof(form, String))
				return new StringExpr(form);
			else if (U.instanceof(form, IPersistentCollection)
				&& !(U.instanceof(form, IRecord))
				&& !(U.instanceof(form, IType))
				&& cast(form, IPersistentCollection).count() == 0) {
				var ret:Expr = new EmptyExpr(form);
				if (RT.meta(form) != null)
					ret = new MetaExpr(ret, MapExpr.parse(context == C.EVAL ? context : C.EXPRESSION, cast(form, IObj).meta()));
				return ret;
			} else if (U.instanceof(form, ISeq))
				return analyzeSeq(context, form, name);
			else if (U.instanceof(form, IPersistentVector))
				return VectorExpr.parse(context, form);
			else if (U.instanceof(form, IRecord))
				return new ConstantExpr(form);
			else if (U.instanceof(form, IType))
				return new ConstantExpr(form);
			else if (U.instanceof(form, IPersistentMap))
				return MapExpr.parse(context, form);
			else if (U.instanceof(form, IPersistentSet))
				return SetExpr.parse(context, form);
			return new ConstantExpr(form);
		} catch (e:Exception) {
			if (!(U.instanceof(e, CompilerException)))
				throw CompilerException.create4(SOURCE_PATH.deref(), lineDeref(), columnDeref(), e);
			else
				throw e;
		}
	}

	static public function isMacro(op:Any):Var {
		// no local macros for now
		if (U.instanceof(op, Symbol) && referenceLocal(op) != null)
			return null;
		if (U.instanceof(op, Symbol) || U.instanceof(op, Var)) {
			var v:Var = (U.instanceof(op, Var)) ? op : lookupVar3(op, false, false);
			if (v != null && v.isMacro()) {
				if (v.ns != currentNS() && !v.isPublic())
					throw new IllegalStateException("var: " + v + " is not public");
				return v;
			}
		}
		return null;
	}

	// 6384
	public static function preserveTag(src:ISeq, dst:Any):Any {
		var tag:Symbol = tagOf(src);
		if (tag != null && U.instanceof(dst, IObj)) {
			var meta:IPersistentMap = RT.meta(dst);
			return (dst : IObj).withMeta(cast RT.assoc(meta, RT.TAG_KEY, tag));
		}
		return dst;
	}

	// 6422
	public static function macroexpand1(x:Any):Any {
		if (U.instanceof(x, ISeq)) {
			var form:ISeq = cast x;
			var op:Any = RT.first(form);
			if (isSpecial(op))
				return x;
			// macro expansion
			/*var v:Var = isMacro(op);
				if (v != null) {
					// TODO:
					// checkSpecs(v, form);

					try {
						var args:ISeq = RT.cons(form, RT.cons(Compiler.LOCAL_ENV.get(), form.next()));
						return v.applyTo(args);
					} catch ( e:ArityException) {
						// hide the 2 extra params for a macro
						if (e.name  == (munge(v.ns.name.name) + "$" + munge(v.sym.name))) {
							throw new ArityException(e.actual - 2, e.name);
						} else {
							throw e;
						}
					} catch (e:CompilerException) {
						throw e;
					}  catch ( e:Exception) {
						if (U.instanceof(e, IllegalArgumentException) ||U.instanceof(e, IllegalStateException) 
							|| U.instanceof(e, ExceptionInfo)  )
						throw new CompilerException(SOURCE_PATH.deref(), lineDeref(), columnDeref(),
								(U.instanceof(op, Symbol)  ?  op : null),
								CompilerException.PHASE_MACRO_SYNTAX_CHECK,
								e);
								else
						throw new CompilerException( SOURCE_PATH.deref(), lineDeref(), columnDeref(),
								(U.instanceof(op, Symbol) ?  op : null),
								// e.getClass().equals(Exception.class) TODO:
								(U.instanceof(e,Exception) ? CompilerException.PHASE_MACRO_SYNTAX_CHECK : CompilerException.PHASE_MACROEXPANSION),
								e);
					}
			} else*/ {

				if (U.instanceof(op, Symbol)) {
					var sym:Symbol = cast op;
					var sname:String = sym.name;
					// (.substring s 2 5) => (. s substring 2 5)
					if (sym.name.charAt(0) == '.') {
						if (RT.length(form) < 2)
							throw new IllegalArgumentException("Malformed member expression, expecting (.member target ...)");
						var meth:Symbol = Symbol.intern1(sname.substring(1));
						var target:Any = RT.second(form);
						/*if (HostExpr.maybeClass(target, false) != null) {
							target = cast(RT.list(IDENTITY, target), IObj).withMeta(RT.map(RT.TAG_KEY, CLASS));
						}*/
						// return preserveTag(form, RT.listStar4(DOT, target, meth, form.next().next()));
						// TODO:
						return null;
					} else if (namesStaticMember(sym)) {
						var target:Symbol = Symbol.intern1(sym.ns);
						/*var c:Class<Dynamic> = HostExpr.maybeClass(target, false);
							if (c != null) {
								var meth:Symbol = Symbol.intern1(sym.name);
								return preserveTag(form, RT.listStar4(DOT, target, meth, form.next()));
						}*/
					} else {
						var idx:Int = sname.lastIndexOf('.');
						if (idx == sname.length - 1)
							return RT.listStar3(NEW, Symbol.intern1(sname.substring(0, idx)), form.next());
					}
				}
			}
		}
		return x;
	}

	// 6499
	static function macroexpand(form:Any):Any {
		var exf:Any = macroexpand1(form);
		if (exf != form)
			return macroexpand(exf);
		return form;
	}

	// 6506
	private static function analyzeSeq(context:C, form:ISeq, name:String):Expr {
		trace(">>>>>>>>>>>> analyzeSeq: " + context + " " + form);
		var line:Any = lineDeref();
		var column:Any = columnDeref();
		if (RT.meta(form) != null && RT.meta(form).containsKey(RT.LINE_KEY))
			line = RT.meta(form).valAt(RT.LINE_KEY);
		if (RT.meta(form) != null && RT.meta(form).containsKey(RT.COLUMN_KEY))
			column = RT.meta(form).valAt(RT.COLUMN_KEY);
		Var.pushThreadBindings(RT.map(LINE, line, COLUMN, column));
		var op:Any = null;
		try {
			var me:Any = macroexpand1(form);
			var ret:Expr = if (me != form) {
				analyze3(context, me, name);
			} else {
				op = RT.first(form);
				if (op == null)
					throw new IllegalArgumentException("Can't call nil, form: " + form);
				// TODO:
				// var inl:IFn = isInline(op, RT.count(RT.next(form)));
				// if (inl != null)
				//	analyze(context, preserveTag(form, inl.applyTo(RT.next(form))));
				// else
				{
					var p:IParser;
					// TODO:
					// if (FN.equals(op))
					//	FnExpr.parse(context, form, name);
					// else
					trace("Check specials: " + op);
					if ((p = specials.valAt(op)) != null) {
						return p.parse(context, form);
					}
					// TOOD:
					// else
					//	InvokeExpr.parse(context, form);
					return null;
				}
			}
			Var.popThreadBindings();
			return ret;
		} catch (e:Exception) {
			Var.popThreadBindings();
			var s:Symbol = (op != null && U.instanceof(op, Symbol)) ? op : null;
			if (!(U.instanceof(e, CompilerException))) {
				throw CompilerException.create5(SOURCE_PATH.deref(), lineDeref(), columnDeref(), s, e);
			} else
				throw e;
		}
	}

	static function consumeWhitespaces(pushbackReader:LineNumberingPushbackReader) {
		var ch:Int = LispReader.read1(pushbackReader);
		while (LispReader.isWhitespace(ch))
			ch = LispReader.read1(pushbackReader);
		LispReader.unread(pushbackReader, ch);
	}

	private static final OPTS_COND_ALLOWED:Any = RT.mapUniqueKeys(LispReader.OPT_READ_COND, LispReader.COND_ALLOW);

	private static function readerOpts(sourceName:String):Any {
		if (sourceName != null && StringTools.endsWith(sourceName, ".cljc"))
			return OPTS_COND_ALLOWED;
		else
			return null;
	}

	// 6550
	public static function eval(form:Any):Any {
		return eval2(form, true);
	}

	// 6554
	public static function eval2(form:Any, freshLoader:Bool):Any {
		// var createdLoader:Bool = false;

		// Var.pushThreadBindings(RT.map(LOADER, RT.makeClassLoader()));
		// createdLoader = true;
		trace(">>>>>>>>>>>>>> EVAL: " + form);

		try {
			var meta:IPersistentMap = RT.meta(form);
			var line:Any = (meta != null ? meta.valAt(RT.LINE_KEY, LINE.deref()) : LINE.deref());
			var column:Any = (meta != null ? meta.valAt(RT.COLUMN_KEY, COLUMN.deref()) : COLUMN.deref());
			var bindings:IPersistentMap = RT.mapUniqueKeys(LINE, line, COLUMN, column);
			if (meta != null) {
				var eval_file:Any = meta.valAt(RT.EVAL_FILE_KEY);
				if (eval_file != null) {
					bindings = cast bindings.assoc(SOURCE_PATH, eval_file);
					try {
						// TODO: FILE?
						// bindings = bindings.assoc(SOURCE, new File((String) eval_file).getName());
						bindings = cast bindings.assoc(SOURCE, eval_file);
					} catch (t:Exception) {}
				}
			}
			Var.pushThreadBindings(bindings);
			try {
				// form = macroexpand(form);
				if (U.instanceof(form, ISeq) && Util.equals(RT.first(form), DO)) {
					var s:ISeq = RT.next(form);
					while (RT.next(s) != null) {
						eval2(RT.first(s), false);
						s = RT.next(s);
					}
					return eval2(RT.first(s), false);
				}
				/*else if ((U.instanceof(form, IType))
					|| (U.instanceof(form, IPersistentCollection)
						&& !(U.instanceof(RT.first(form), Symbol) && StringTools.startsWith(cast(RT.first(form), Symbol).name, "def")))) {
					var fexpr:ObjExpr = cast analyze(C.EXPRESSION, RT.list(FN, PersistentVector.EMPTY, form), "eval" + RT.nextID());
					var fn:IFn = fexpr.eval();
					return fn.invoke();
				}*/
				else {
					var expr:Expr = analyze(C.EVAL, form);
					trace("EXPR EVAL RET:" + expr.eval());
					return expr.eval();
				}
			} catch (e:Exception) {
				Var.popThreadBindings();
				// TODO: need throw?
				throw(e);
			}
		} catch (e:Exception) {
			// if (createdLoader)
			//    Var.popThreadBindings();
			// TODO: need throw?
			throw(e);
		}
	}

	public static function registerConstant(o:Any):Int {
		// TODO:
		/*
			if (!CONSTANTS.isBound())
				return -1;
			var v:PersistentVector = CONSTANTS.deref();
			IdentityHashMap<Object, Integer> ids = (IdentityHashMap<Object, Integer>) CONSTANT_IDS.deref();
			Integer i = ids.get(o);
			if (i != null)
				return i;
			CONSTANTS.set(RT.conj(v, o));
			ids.put(o, v.count());
			return v.count();
		 */
		return 0;
	}

	private static function registerKeyword(keyword:Keyword):KeywordExpr {
		if (!KEYWORDS.isBound())
			return new KeywordExpr(keyword);

		var keywordsMap:IPersistentMap = KEYWORDS.deref();
		var id:Any = RT.get(keywordsMap, keyword);
		if (id == null) {
			KEYWORDS.set(RT.assoc(keywordsMap, keyword, registerConstant(keyword)));
		}
		return new KeywordExpr(keyword);
	}

	// 6667
	static function fwdPath(p1:PathNode):ISeq {
		var ret:ISeq = null;
		while (p1 != null) {
			ret = RT.cons(p1, ret);
			p1 = p1.parent;
		}
		return ret;
	}

	static public function commonPath(n1:PathNode, n2:PathNode):PathNode {
		var xp:ISeq = fwdPath(n1);
		var yp:ISeq = fwdPath(n2);
		if (RT.first(xp) != RT.first(yp))
			return null;
		while (RT.second(xp) != null && RT.second(xp) == RT.second(yp)) {
			xp = xp.next();
			yp = yp.next();
		}
		return RT.first(xp);
	}

	private static function analyzeSymbol(sym:Symbol):Expr {
		trace("Analyze symbol: " + sym);
		var tag:Symbol = tagOf(sym);
		if (sym.ns == null) // ns-qualified syms are always Vars
		{
			var b:LocalBinding = referenceLocal(sym);
			if (b != null) {
				return new LocalBindingExpr(b, tag);
			}
		}
		/*else {
			if (namespaceFor(sym) == null) {
				var nsSym:Symbol = Symbol.intern1(sym.ns);
				Class c = HostExpr.maybeClass(nsSym, false);
				if (c != null) {
					if (Reflector.getField(c, sym.name, true) != null)
						return new StaticFieldExpr(lineDeref(), columnDeref(), c, sym.name, tag);
					throw Util.runtimeException("Unable to find static field: " + sym.name + " in " + c);
				}
			}
		}*/
		var o:Any = resolve(sym);
		trace("RESOVLE: " + o + " " + RT.booleanCast(RT.get((o : Var).meta(), RT.CONST_KEY)));
		if (U.instanceof(o, Var)) {
			var v:Var = o;
			if (isMacro(v) != null)
				throw Util.runtimeException("Can't take value of a macro: " + v);
			if (RT.booleanCast(RT.get(v.meta(), RT.CONST_KEY)))
				return analyze(C.EXPRESSION, RT.list(QUOTE, v.get()));
			registerVar(v);
			return new VarExpr(v, tag);
		} else if (U.instanceof(o, Class))
			return new ConstantExpr(o);
		else if (U.instanceof(o, Symbol))
			return new UnresolvedVarExpr(o);

		throw Util.runtimeException("Unable to resolve symbol: " + sym + " in this context");
	}

	static public function lookupVar3(sym:Symbol, internNew:Bool, registerMacro:Bool):Var {
		var varr:Var = null;
		// note - ns-qualified vars in other namespaces must already exist
		if (sym.ns != null) {
			var ns:Namespace = namespaceFor(sym);
			if (ns == null)
				return null;
			// throw Util.runtimeException("No such namespace: " + sym.ns);
			var name:Symbol = Symbol.intern1(sym.name);
			if (internNew && ns == currentNS())
				varr = currentNS().intern(name);
			else
				varr = ns.findInternedVar(name);
		} else if (sym.equals(NS))
			varr = RT.NS_VAR;
		else if (sym.equals(IN_NS))
			varr = RT.IN_NS_VAR;
		else {
			// is it mapped?
			var o:Any = currentNS().getMapping(sym);
			if (o == null) {
				// introduce a new var in the current ns
				if (internNew)
					varr = currentNS().intern(Symbol.intern1(sym.name));
			} else if (U.instanceof(o, Var)) {
				varr = o;
			} else {
				throw Util.runtimeException("Expecting var, but " + sym + " is mapped to " + o);
			}
		}
		if (varr != null && (!varr.isMacro() || registerMacro))
			registerVar(varr);
		return varr;
	}

	static public function lookupVar(sym:Symbol, internNew:Bool):Var {
		return lookupVar3(sym, internNew, true);
	}

	// 6881
	public static function registerVar(varr:Var) {
		if (!VARS.isBound())
			return;
		var varsMap:IPersistentMap = VARS.deref();
		var id:Any = RT.get(varsMap, varr);
		if (id == null) {
			VARS.set(RT.assoc(varsMap, varr, registerConstant(varr)));
		}
		// trace(">>>>>>>>>>>> REGISTER VARS: " +  VARS);
	}

	static public function currentNS():Namespace {
		return RT.CURRENT_NS.deref();
	}

	/*
		static public function closeOver( b:LocalBinding,  method:ObjMethod) {
			if (b != null && method != null) {
				var lb:LocalBinding =  RT.get(method.locals, b);
				if (lb == null) {
					method.objx.closes = RT.assoc(method.objx.closes, b, b);
					closeOver(b, method.parent);
				} else {
					if (lb.idx == 0)
						method.usesThis = true;
					if (IN_CATCH_FINALLY.deref() != null) {
						method.localsUsedInCatchFinally = (PersistentHashSet) method.localsUsedInCatchFinally.cons(b.idx);
					}
				}
			}
		}
	 */
	static private function referenceLocal(sym:Symbol):LocalBinding {
		if (!LOCAL_ENV.isBound())
			return null;
		var b:LocalBinding = RT.get(LOCAL_ENV.deref(), sym);
		if (b != null) {
			var method:ObjMethod = METHOD.deref();
			if (b.idx == 0)
				method.usesThis = true;
			// TODO: CLOSE OVER!
			// closeOver(b, method);
		}
		return b;
	}

	// 6927
	public static function tagOf(o:Any):Symbol {
		var tag:Any = RT.get(RT.meta(o), RT.TAG_KEY);
		if (U.instanceof(tag, Symbol))
			return tag;
		else if (U.instanceof(tag, String))
			return Symbol.intern(null, tag);
		return null;
	}

	// line 6969
	public static function load(data:String, sourcePath:String, sourceName:String):Any {
		trace("Compiler/load");
		var EOF:Any = U.object();
		var ret:Any = null;
		var pushbackReader:LineNumberingPushbackReader = new LineNumberingPushbackReader(data);
		consumeWhitespaces(pushbackReader);
		Var.pushThreadBindings(RT.mapUniqueKeys( // LOADER, RT.makeClassLoader(),
			SOURCE_PATH,
			sourcePath, SOURCE, sourceName, METHOD, null, LOCAL_ENV, null, LOOP_LOCALS, null, NEXT_LOCAL_NUM, 0, RT.READEVAL, RT.T, RT.CURRENT_NS,
			RT.CURRENT_NS.deref(), LINE_BEFORE, pushbackReader.getLineNumber(), COLUMN_BEFORE, pushbackReader.getColumnNumber(), LINE_AFTER,
			pushbackReader.getLineNumber(), COLUMN_AFTER, pushbackReader.getColumnNumber(), RT.UNCHECKED_MATH, RT.UNCHECKED_MATH.deref(),
			RT.WARN_ON_REFLECTION, RT.WARN_ON_REFLECTION.deref(), RT.DATA_READERS, RT.DATA_READERS.deref()));
		var readerOpts:Any = readerOpts(sourceName);
		trace("Before cycle, readerOpts: " + readerOpts);
		try {
			var r:Any = LispReader.read5(pushbackReader, false, EOF, false, readerOpts);
			trace(">>>>> LOAD READ: " + r);
			while (r != EOF) {
				consumeWhitespaces(pushbackReader);
				LINE_AFTER.set(pushbackReader.getLineNumber());
				COLUMN_AFTER.set(pushbackReader.getColumnNumber());
				ret = eval2(r, false);
				trace("EVAL RET: " + ret);
				LINE_BEFORE.set(pushbackReader.getLineNumber());
				COLUMN_BEFORE.set(pushbackReader.getColumnNumber());
				r = LispReader.read5(pushbackReader, false, EOF, false, readerOpts);
			}
		} catch (e:LispReader.ReaderExceptionLR) {
			Var.popThreadBindings();
			if (U.instanceof(e, LispReader.ReaderExceptionLR))
				throw new CompilerException(sourcePath, e.line, e.column, null, CompilerException.PHASE_READ, e.previous);
		} catch (e:Exception) {
			Var.popThreadBindings();
			if (!(U.instanceof(e, CompilerException)))
				throw new CompilerException(sourcePath, LINE_BEFORE.deref(), COLUMN_BEFORE.deref(), null, CompilerException.PHASE_EXECUTION, e);
			else
				throw e;
		}
		Var.popThreadBindings();
		return ret;
	}
}
