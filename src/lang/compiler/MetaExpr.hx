package lang.compiler;

class MetaExpr implements Expr {
	public var expr:Expr;
	public var meta:Expr;

	// final static Type IOBJ_TYPE = Type.getType(IObj.class);
	// final static Method withMetaMethod = Method.getMethod("clojure.lang.IObj withMeta(clojure.lang.IPersistentMap)");

	public function new(expr:Expr, meta:Expr) {
		this.expr = expr;
		this.meta = meta;
	}

	public function eval():Any {
		return cast(expr.eval(), IObj).withMeta(cast(meta.eval(), IPersistentMap));
	}
	/*
		public void emit(C context, ObjExpr objx, GeneratorAdapter gen) {
			expr.emit(C.EXPRESSION, objx, gen);
			gen.checkCast(IOBJ_TYPE);
			meta.emit(C.EXPRESSION, objx, gen);
			gen.checkCast(IPERSISTENTMAP_TYPE);
			gen.invokeInterface(IOBJ_TYPE, withMetaMethod);
			if (context == C.STATEMENT) {
				gen.pop();
			}
		}

		public boolean hasJavaClass() {
			return expr.hasJavaClass();
		}

		public Class getJavaClass() {
			return expr.getJavaClass();
		}
	 */
}
