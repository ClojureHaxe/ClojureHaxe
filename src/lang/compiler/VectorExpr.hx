package lang.compiler;

import lang.Compiler.C;

class VectorExpr implements Expr {
	public var args:IPersistentVector;

	// final static Method vectorMethod = Method.getMethod("clojure.lang.IPersistentVector vector(Object[])");

	public function new(args:IPersistentVector) {
		this.args = args;
	}

	public function eval():Any {
		var ret:IPersistentVector = PersistentVector.EMPTY;
		var i:Int = 0;
		while (i < args.count()) {
			ret = cast ret.cons(((args.nth(i) : Expr)).eval());
			i++;
		}
		return ret;
	}

	/*
		public function emit( context:C,  objx:ObjExpr,  gen:GeneratorAdapter):Void {
			if (args.count() <= Tuple.MAX_SIZE) {
				for (int i = 0; i < args.count(); i++) {
					((Expr) args.nth(i)).emit(C.EXPRESSION, objx, gen);
				}
				gen.invokeStatic(TUPLE_TYPE, createTupleMethods[args.count()]);
			} else {
				MethodExpr.emitArgsAsArray(args, objx, gen);
				gen.invokeStatic(RT_TYPE, vectorMethod);
			}

			if (context == C.STATEMENT)
				gen.pop();
		}

		public boolean hasJavaClass() {
			return true;
		}

		public Class getJavaClass() {
			return IPersistentVector.class;
		}

	 */
	static public function parse(context:C, form:IPersistentVector):Expr {
		var constant:Bool = true;

		var args:IPersistentVector = PersistentVector.EMPTY;
		var i:Int = 0;
		while (i < form.count()) {
			var v:Expr = Compiler.analyze(context == C.EVAL ? context : C.EXPRESSION, form.nth(i));
			args = cast args.cons(v);
			if (!(U.instanceof(v, LiteralExpr)))
				constant = false;
			i++;
		}
		var ret:Expr = new VectorExpr(args);
        // TODO: check if (cast form) works (IObj should be)
		if (U.instanceof(form, IObj) && (cast form).meta() != null)
			return new MetaExpr(ret, MapExpr.parse(context == C.EVAL ? context : C.EXPRESSION, (cast form).meta()));
		else if (constant) {
			var rv:IPersistentVector = PersistentVector.EMPTY;
			var i:Int = 0;
			while (i < args.count()) {
				var ve:LiteralExpr = args.nth(i);
				rv = cast rv.cons(ve.val());
				i++;
			}

			return new ConstantExpr(rv);
		} else
			return ret;
	}
}
