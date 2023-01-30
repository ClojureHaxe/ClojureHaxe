package lang.compiler;

import lang.Compiler.C;

class SetExpr implements Expr {
	public var keys:IPersistentVector;

	// final static Method setMethod = Method.getMethod("clojure.lang.IPersistentSet set(Object[])");

	public function new(keys:IPersistentVector) {
		this.keys = keys;
	}

	public function eval():Any {
		var ret:Array<Any> = new Array<Any>();
		var i:Int = 0;
		while (i < keys.count()) {
			ret[i] = (keys.nth(i) : Expr).eval();
			i++;
		}
		return RT.set(...ret);
	}

	/*
		public function emit( context:C,  objx:ObjExpr,  gen:GeneratorAdapter):Void {
			MethodExpr.emitArgsAsArray(keys, objx, gen);
			gen.invokeStatic(RT_TYPE, setMethod);
			if (context == C.STATEMENT)
				gen.pop();
		}

		public boolean hasJavaClass() {
			return true;
		}

		public Class getJavaClass() {
			return IPersistentSet.class;
		}
	 */
	static public function parse(context:C, form:IPersistentSet):Expr {
		var keys:IPersistentVector = PersistentVector.EMPTY;
		var constant:Bool = true;
		var s:ISeq = RT.seq(form);
		while (s != null) {
			var e:Any = s.first();
			var expr:Expr = Compiler.analyze(context == C.EVAL ? context : C.EXPRESSION, e);
			keys = cast keys.cons(expr);
			if (!U.instanceof(expr, LiteralExpr))
				constant = false;
			s = s.next();
		}
		var ret:Expr = new SetExpr(keys);
		if (U.instanceof(form, IObj) && (cast form).meta() != null)
			return new MetaExpr(ret, MapExpr.parse(context == C.EVAL ? context : C.EXPRESSION, (cast form).meta()));
		else if (constant) {
			var set:IPersistentSet = PersistentHashSet.EMPTY;
			var i:Int = 0;
			while (i < keys.count()) {
				var ve:LiteralExpr = keys.nth(i);
				set = cast set.cons(ve.val());
				i++;
			}
			return new ConstantExpr(set);
		} else
			return ret;
	}
}
