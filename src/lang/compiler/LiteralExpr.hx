package lang.compiler;

abstract class LiteralExpr implements Expr {
	abstract public function val():Any;

	public function eval():Any {
		return val();
	}
}
