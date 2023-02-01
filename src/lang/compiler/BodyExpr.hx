package lang.compiler;

import lang.Compiler.C;

class BodyExpr implements Expr implements MaybePrimitiveExpr {
	public var exprs:PersistentVector;

	/*public final function exprs():PersistentVector {
		return exprs;
	}*/
	public function new(exprs:PersistentVector) {
		this.exprs = exprs;
	}

	public function eval():Any {
		var ret:Any = null;
		for (o in exprs) {
			var e:Expr = o;
			ret = e.eval();
		}
		return ret;
	}

	/*
		public boolean canEmitPrimitive() {
			return lastExpr() instanceof MaybePrimitiveExpr && ((MaybePrimitiveExpr) lastExpr()).canEmitPrimitive();
		}

		public void emitUnboxed(C context, ObjExpr objx, GeneratorAdapter gen) {
			for (int i = 0; i < exprs.count() - 1; i++) {
				Expr e = (Expr) exprs.nth(i);
				e.emit(C.STATEMENT, objx, gen);
			}
			MaybePrimitiveExpr last = (MaybePrimitiveExpr) exprs.nth(exprs.count() - 1);
			last.emitUnboxed(context, objx, gen);
		}

		public void emit(C context, ObjExpr objx, GeneratorAdapter gen) {
			for (int i = 0; i < exprs.count() - 1; i++) {
				Expr e = (Expr) exprs.nth(i);
				e.emit(C.STATEMENT, objx, gen);
			}
			Expr last = (Expr) exprs.nth(exprs.count() - 1);
			last.emit(context, objx, gen);
		}

		public boolean hasJavaClass() {
			return lastExpr().hasJavaClass();
		}

		public Class getJavaClass() {
			return lastExpr().getJavaClass();
		}
	 */
	private function lastExpr():Expr {
		return exprs.nth(exprs.count() - 1);
	}
}

class BodyExprParser implements IParser {
	public function new() {}

	public function parse(context:C, frms:Any):Expr {
		var forms:ISeq = frms;
		if (Util.equals(RT.first(forms), Compiler.DO))
			forms = RT.next(forms);
		var exprs:PersistentVector = PersistentVector.EMPTY;
		while (forms != null) {
			var e:Expr = (context != C.EVAL
				&& (context == C.STATEMENT || forms.next() != null)) ? Compiler.analyze(C.STATEMENT, forms.first()) : Compiler.analyze(context, forms.first());
			exprs = exprs.cons(e);
			forms = forms.next();
		}
		if (exprs.count() == 0)
			exprs = exprs.cons(Compiler.NIL_EXPR);
		return new BodyExpr(exprs);
	}
}
