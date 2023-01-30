package lang.compiler;

class ListExpr implements Expr {
	public var args:IPersistentVector;

	// final static Method arrayToListMethod = Method.getMethod("clojure.lang.ISeq arrayToList(Object[])");

	public function new(args:IPersistentVector) {
		this.args = args;
	}

	public function eval():Any {
		var ret:IPersistentVector = PersistentVector.EMPTY;
		var i:Int = 0;
		while (i < args.count()) {
			ret = cast ret.cons(cast(args.nth(i), Expr).eval());
			i++;
		}
		return ret.seq();
	}
	/*
		public void emit(C context, ObjExpr objx, GeneratorAdapter gen) {
			MethodExpr.emitArgsAsArray(args, objx, gen);
			gen.invokeStatic(RT_TYPE, arrayToListMethod);
			if (context == C.STATEMENT)
				gen.pop();
		}

		public boolean hasJavaClass() {
			return true;
		}

		public Class getJavaClass() {
			return IPersistentList.class;
		}
	 */
}
