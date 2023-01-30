package lang.compiler;

class VarExpr implements Expr implements AssignableExpr {
	public var varr:Var;
	public var tag:Any;

	// final static Method getMethod = Method.getMethod("Object get()");
	// final static Method setMethod = Method.getMethod("Object set(Object)");
	// Class jc;

	public function new(varr:Var, tag:Symbol) {
		this.varr = varr;
		this.tag = tag != null ? tag : varr.getTag();
	}

	public function eval():Any {
		return varr.deref();
	}

	/*
		public void emit(C context, ObjExpr objx, GeneratorAdapter gen) {
			objx.emitVarValue(gen, var);
			if (context == C.STATEMENT) {
				gen.pop();
			}
		}

		public boolean hasJavaClass() {
			return tag != null;
		}

		public Class getJavaClass() {
			if (jc == null)
				jc = HostExpr.tagToClass(tag);
			return jc;
		}
	 */
	public function evalAssign(val:Expr):Any {
		return varr.set(val.eval());
	}
	/*
		public void emitAssign(C context, ObjExpr objx, GeneratorAdapter gen,
							   Expr val) {
			objx.emitVar(gen, var);
			val.emit(C.EXPRESSION, objx, gen);
			gen.invokeVirtual(VAR_TYPE, setMethod);
			if (context == C.STATEMENT)
				gen.pop();
		}
	 */
}
