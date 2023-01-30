package lang.compiler;

import lang.Compiler.C;
import haxe.Exception;

class DefExpr implements Expr {
	public var varr:Var;
	public var init:Expr;
	public var meta:Expr;
	public var initProvided:Bool;
	public var isDynamic:Bool;
	public var source:String;
	public var line:Int;
	public var column:Int;

	/*
		final static Method bindRootMethod = Method.getMethod("void bindRoot(Object)");
		final static Method setTagMethod = Method.getMethod("void setTag(clojure.lang.Symbol)");
		final static Method setMetaMethod = Method.getMethod("void setMeta(clojure.lang.IPersistentMap)");
		final static Method setDynamicMethod = Method.getMethod("clojure.lang.Var setDynamic(boolean)");
		final static Method symintern = Method.getMethod("clojure.lang.Symbol intern(String, String)");
	 */
	public function new(source:String, line:Int, column:Int, varr:Var, init:Expr, meta:Expr, initProvided:Bool, isDynamic:Bool) {
		this.source = source;
		this.line = line;
		this.column = column;
		this.varr = varr;
		this.init = init;
		this.meta = meta;
		this.isDynamic = isDynamic;
		this.initProvided = initProvided;
	}

	private function includesExplicitMetadata(expr:MapExpr):Bool {
		var i:Int = 0;
		while (i < expr.keyvals.count()) {
			var k:Keyword = cast(expr.keyvals.nth(i), KeywordExpr).k;
			if ((k != RT.FILE_KEY) && (k != RT.DECLARED_KEY) && (k != RT.LINE_KEY) && (k != RT.COLUMN_KEY))
				return true;
			i += 2;
		}
		return false;
	}

	public function eval():Any {
		try {
			if (initProvided) {
				//			if(init instanceof FnExpr && ((FnExpr) init).closes.count()==0)
				//				var.bindRoot(new FnLoaderThunk((FnExpr) init,var));
				//			else
				varr.bindRoot(init.eval());
			}
			if (meta != null) {
				var metaMap:IPersistentMap = cast meta.eval();
				if (initProvided || true) // includesExplicitMetadata((MapExpr) meta))
					varr.setMeta(metaMap);
			}
			return varr.setDynamic(isDynamic);
		} catch (e:Exception) {
			if (!U.instanceof(e, CompilerException))
				throw new CompilerException(source, line, column, Compiler.DEF, CompilerException.PHASE_EXECUTION, e);
			else
				throw e;
		}
	}
}

class DefExprParser implements IParser {
	public function new() {}

	public function parse(context:C, form:Any):Expr {
		var docstring:String = null;
		if (RT.count(form) == 4 && U.instanceof(RT.third(form), String)) {
			docstring = RT.third(form);
			form = RT.list(RT.first(form), RT.second(form), RT.fourth(form));
		}
		if (RT.count(form) > 3)
			throw Util.runtimeException("Too many arguments to def");
		else if (RT.count(form) < 2)
			throw Util.runtimeException("Too few arguments to def");
		else if (!U.instanceof(RT.second(form), Symbol))
			throw Util.runtimeException("First argument to def must be a Symbol");
		var sym:Symbol = RT.second(form);
		var v:Var = Compiler.lookupVar(sym, true);
		if (v == null)
			throw Util.runtimeException("Can't refer to qualified var that doesn't exist");
		if (!v.ns.equals(Compiler.currentNS())) {
			if (sym.ns == null) {
				v = Compiler.currentNS().intern(sym);
				Compiler.registerVar(v);
			} else
				throw Util.runtimeException("Can't create defs outside of current ns");
		}
		var mm:IPersistentMap = sym.meta();
		var isDynamic:Bool = RT.booleanCast(RT.get(mm, Compiler.dynamicKey));
		if (isDynamic)
			v.setDynamic();
		if (!isDynamic && StringTools.startsWith(sym.name, "*") && StringTools.endsWith(sym.name, "*") && sym.name.length > 2) {
			RT.errPrintWriter()
				.format("Warning: %1$s not declared dynamic and thus is not dynamically rebindable, "
					+ "but its name suggests otherwise. Please either indicate ^:dynamic %1$s or change the name. (%2$s:%3$d)\n",
					sym, Compiler.SOURCE_PATH.get(), Compiler.LINE.get());
		}
		if (RT.booleanCast(RT.get(mm, Compiler.arglistsKey))) {
			var vm:IPersistentMap = v.meta();
			vm = cast RT.assoc(vm, Compiler.arglistsKey, RT.second(mm.valAt(Compiler.arglistsKey)));
			v.setMeta(vm);
		}
		var source_path:Any = Compiler.SOURCE_PATH.get();
		source_path = source_path == null ? "NO_SOURCE_FILE" : source_path;
		mm = cast RT.assoc(mm, RT.LINE_KEY, Compiler.LINE.get()).assoc(RT.COLUMN_KEY, Compiler.COLUMN.get()).assoc(RT.FILE_KEY, source_path);
		if (docstring != null)
			mm = cast RT.assoc(mm, RT.DOC_KEY, docstring);
		mm = Compiler.elideMeta(mm);
		var meta:Expr = mm.count() == 0 ? null : Compiler.analyze(context == C.EVAL ? context : C.EXPRESSION, mm);
		return new DefExpr(Compiler.SOURCE.deref(), Compiler.lineDeref(), Compiler.columnDeref(), v,
			Compiler.analyze3(context == C.EVAL ? context : C.EXPRESSION, RT.third(form), v.sym.name), meta, RT.count(form) == 3, isDynamic);
	}
}
