package lang.compiler;

import haxe.ds.Vector;

import lang.Compiler.C;

class ConstantExpr extends LiteralExpr {
	// stuff quoted vals in classloader at compile time, pull out at runtime
	// this won't work for static compilation...
	public var v:Any;
	public var id:Int;

	public function new(v:Any) {
		this.v = v;
		this.id = Compiler.registerConstant(v);
		//		this.id = RT.nextID();
		//		DynamicClassLoader loader = (DynamicClassLoader) LOADER.get();
		//		loader.registerQuotedVal(id, v);
	}

	public function val():Any {
		return v;
	}
	/*
		public function emit( context:C,  objx:ObjExpr,  gen:GeneratorAdapter) {
			objx.emitConstant(gen, id);

			if (context == C.STATEMENT) {
				gen.pop();

			}
		}

		public function hasJavaClass():Bool {
			return Modifier.isPublic(v.getClass().getModifiers());
		}

		public Class getJavaClass() {
			if (v instanceof APersistentMap)
				return APersistentMap.class;
			else if (v instanceof APersistentSet)
				return APersistentSet.class;
			else if (v instanceof APersistentVector)
				return APersistentVector.class;
			else
				return v.getClass();
		}
	 */
}

class ConstantExprParser implements IParser {
	static var formKey:Keyword = Keyword.intern1("form");

	public function parse(context:C, form:Any):Expr {
		var argCount:Int = RT.count(form) - 1;
		if (argCount != 1) {
			var exData:IPersistentMap = PersistentArrayMap.create(formKey, form);
			throw ExceptionInfo.create("Wrong number of args (" + argCount + ") passed to quote", exData);
		}
		var v:Any = RT.second(form);

		if (v == null)
			return Compiler.NIL_EXPR;
		else if (v == RT.T)
			return Compiler.TRUE_EXPR;
		else if (v == RT.F)
			return Compiler.FALSE_EXPR;
		if (U.isNumber(v))
			return NumberExpr.parse(v);
		else if (U.instanceof(v, String))
			return new StringExpr(v);
		else if (U.instanceof(v, IPersistentCollection)
			&& (cast(v, IPersistentCollection).count() == 0)
			&& (!(U.instanceof(v, IObj)) || (v : IObj).meta() == null))
			return new EmptyExpr(v);
		else
			return new ConstantExpr(v);
	}
}
