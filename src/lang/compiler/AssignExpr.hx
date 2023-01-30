package lang.compiler;

class AssignExpr implements Expr {
	public var target:AssignableExpr;
	public var val:Expr;

	public function new(target:AssignableExpr, val:Expr) {
		this.target = target;
		this.val = val;
	}

	public function eval():Any {
		return target.evalAssign(val);
	}
	/*
		public void emit(C context, ObjExpr objx, GeneratorAdapter gen) {
			target.emitAssign(context, objx, gen, val);
		}

		public boolean hasJavaClass() {
			return val.hasJavaClass();
		}

		public Class getJavaClass() {
			return val.getJavaClass();
		}

		static class Parser implements IParser {
			public Expr parse(C context, Object frm) {
				ISeq form = (ISeq) frm;
				if (RT.length(form) != 3)
					throw new IllegalArgumentException("Malformed assignment, expecting (set! target val)");
				Expr target = analyze(C.EXPRESSION, RT.second(form));
				if (!(target instanceof AssignableExpr))
					throw new IllegalArgumentException("Invalid assignment target");
				return new AssignExpr((AssignableExpr) target, analyze(C.EXPRESSION, RT.third(form)));
			}
		}
	 */
}
