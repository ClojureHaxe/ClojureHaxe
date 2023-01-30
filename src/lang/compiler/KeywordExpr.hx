package lang.compiler;

class KeywordExpr extends LiteralExpr {
	public var k:Keyword;

	public function new(k:Keyword) {
		this.k = k;
	}

	public function val():Any {
		return k;
	}

	override public function eval():Any {
		return k;
	}
	/*
		public void emit(C context, ObjExpr objx, GeneratorAdapter gen) {
			objx.emitKeyword(gen, k);
			if (context == C.STATEMENT)
				gen.pop();

		}

		public boolean hasJavaClass() {
			return true;
		}

		public Class getJavaClass() {
			return Keyword.class;
		}
	 */
}
