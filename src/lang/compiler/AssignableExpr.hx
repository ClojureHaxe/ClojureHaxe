package lang.compiler;

interface AssignableExpr {
    public function evalAssign(val:Expr):Any;

    // void emitAssign(C context, ObjExpr objx, GeneratorAdapter gen, Expr val);
}