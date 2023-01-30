package lang.compiler;

class NumberExpr extends LiteralExpr implements MaybePrimitiveExpr {
	var n:Any;

	public var id:Int;

	public function new(n:Any) {
		this.n = n;
		this.id = Compiler.registerConstant(n);
	}

	public function val():Any {
		return n;
	}

	/*
		public function emit( context:C,  objx:ObjExpr, gen:GeneratorAdapter) {
			if (context != C.STATEMENT) {
				objx.emitConstant(gen, id);
			}
		}

		public function hasJavaClass():Bool {
			return true;
		}

		public Class getJavaClass() {
			if (n instanceof Integer)
				return long.class;
			else if (n instanceof Double)
				return double.class;
			else if (n instanceof Long)
				return long.class;
			else
				throw new IllegalStateException("Unsupported Number type: " + n.getClass().getName());
		}

		public boolean canEmitPrimitive() {
			return true;
		}

		public void emitUnboxed(C context, ObjExpr objx, GeneratorAdapter gen) {
			if (n instanceof Integer)
				gen.push(n.longValue());
			else if (n instanceof Double)
				gen.push(n.doubleValue());
			else if (n instanceof Long)
				gen.push(n.longValue());
		}
	 */
	static public function parse(form:Any):Expr {
		/*if (form instanceof Integer
					|| form instanceof Double
					|| form instanceof Long)
				return new NumberExpr(form);
			else
				return new ConstantExpr(form); */
		return new NumberExpr(form);
	}
}
