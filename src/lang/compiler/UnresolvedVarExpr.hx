package lang.compiler;

import lang.exceptions.IllegalArgumentException;

class UnresolvedVarExpr implements Expr {
	public var symbol:Symbol;

	public function new(symbol:Symbol) {
		this.symbol = symbol;
	}

	/*
		public boolean hasJavaClass() {
			return false;
		}

		public Class getJavaClass() {
			throw new IllegalArgumentException(
					"UnresolvedVarExpr has no Java class");
		}

		public void emit(C context, ObjExpr objx, GeneratorAdapter gen) {
		}
	 */
	public function eval():Any {
		throw new IllegalArgumentException("UnresolvedVarExpr cannot be evalled");
	}
}
