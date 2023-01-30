package lang.compiler;

class NilExpr extends LiteralExpr {

    public function new(){}

	function val():Any {
		return null;
	}
	/*public function  emit(C context, ObjExpr objx, GeneratorAdapter gen):Void {
		gen.visitInsn(Opcodes.ACONST_NULL);
		if (context == C.STATEMENT)
			gen.pop();
	}*/
	/*
		public boolean hasJavaClass() {
			return true;
		}

		public Class getJavaClass() {
			return null;
		}
	 */
}
