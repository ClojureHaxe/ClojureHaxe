package lang.compiler;

 class IfExpr implements Expr implements  MaybePrimitiveExpr {
    public var  testExpr:Expr;
    public var  thenExpr:Expr;
    public var  elseExpr:Expr;
    public var  line:Int;
    public var  column:Int;


    public function new ( line:Int,  column:Int,  testExpr:Expr,  thenExpr:Expr,  elseExpr:Expr) {
        this.testExpr = testExpr;
        this.thenExpr = thenExpr;
        this.elseExpr = elseExpr;
        this.line = line;
        this.column = column;
    }

    public function eval():Any {
        var t:Any = testExpr.eval();
        if (t != null && t != false)
            return thenExpr.eval();
        return elseExpr.eval();
    }

    /*
    public void emit(C context, ObjExpr objx, GeneratorAdapter gen) {
        doEmit(context, objx, gen, false);
    }

    public void emitUnboxed(C context, ObjExpr objx, GeneratorAdapter gen) {
        doEmit(context, objx, gen, true);
    }

    public void doEmit(C context, ObjExpr objx, GeneratorAdapter gen, boolean emitUnboxed) {
        Label nullLabel = gen.newLabel();
        Label falseLabel = gen.newLabel();
        Label endLabel = gen.newLabel();

        gen.visitLineNumber(line, gen.mark());

        if (testExpr instanceof StaticMethodExpr && ((StaticMethodExpr) testExpr).canEmitIntrinsicPredicate()) {
            ((StaticMethodExpr) testExpr).emitIntrinsicPredicate(C.EXPRESSION, objx, gen, falseLabel);
        } else if (maybePrimitiveType(testExpr) == boolean.class) {
            ((MaybePrimitiveExpr) testExpr).emitUnboxed(C.EXPRESSION, objx, gen);
            gen.ifZCmp(gen.EQ, falseLabel);
        } else {
            testExpr.emit(C.EXPRESSION, objx, gen);
            gen.dup();
            gen.ifNull(nullLabel);
            gen.getStatic(BOOLEAN_OBJECT_TYPE, "FALSE", BOOLEAN_OBJECT_TYPE);
            gen.visitJumpInsn(IF_ACMPEQ, falseLabel);
        }
        if (emitUnboxed)
            ((MaybePrimitiveExpr) thenExpr).emitUnboxed(context, objx, gen);
        else
            thenExpr.emit(context, objx, gen);
        gen.goTo(endLabel);
        gen.mark(nullLabel);
        gen.pop();
        gen.mark(falseLabel);
        if (emitUnboxed)
            ((MaybePrimitiveExpr) elseExpr).emitUnboxed(context, objx, gen);
        else
            elseExpr.emit(context, objx, gen);
        gen.mark(endLabel);
    }

    public boolean hasJavaClass() {
        return thenExpr.hasJavaClass()
                && elseExpr.hasJavaClass()
                &&
                (thenExpr.getJavaClass() == elseExpr.getJavaClass()
                        || thenExpr.getJavaClass() == RECUR_CLASS
                        || elseExpr.getJavaClass() == RECUR_CLASS
                        || (thenExpr.getJavaClass() == null && !elseExpr.getJavaClass().isPrimitive())
                        || (elseExpr.getJavaClass() == null && !thenExpr.getJavaClass().isPrimitive()));
    }

    public boolean canEmitPrimitive() {
        try {
            return thenExpr instanceof MaybePrimitiveExpr
                    && elseExpr instanceof MaybePrimitiveExpr
                    && (thenExpr.getJavaClass() == elseExpr.getJavaClass()
                    || thenExpr.getJavaClass() == RECUR_CLASS
                    || elseExpr.getJavaClass() == RECUR_CLASS)
                    && ((MaybePrimitiveExpr) thenExpr).canEmitPrimitive()
                    && ((MaybePrimitiveExpr) elseExpr).canEmitPrimitive();
        } catch (Exception e) {
            return false;
        }
    }

    public Class getJavaClass() {
        Class thenClass = thenExpr.getJavaClass();
        if (thenClass != null && thenClass != RECUR_CLASS)
            return thenClass;
        return elseExpr.getJavaClass();
    }

    static class Parser implements IParser {
        public Expr parse(C context, Object frm) {
            ISeq form = (ISeq) frm;
            //(if test then) or (if test then else)
            if (form.count() > 4)
                throw Util.runtimeException("Too many arguments to if");
            else if (form.count() < 3)
                throw Util.runtimeException("Too few arguments to if");
            PathNode branch = new PathNode(PATHTYPE.BRANCH, (PathNode) CLEAR_PATH.get());
            Expr testexpr = analyze(context == C.EVAL ? context : C.EXPRESSION, RT.second(form));
            Expr thenexpr, elseexpr;
            try {
                Var.pushThreadBindings(
                        RT.map(CLEAR_PATH, new PathNode(PATHTYPE.PATH, branch)));
                thenexpr = analyze(context, RT.third(form));
            } finally {
                Var.popThreadBindings();
            }
            try {
                Var.pushThreadBindings(
                        RT.map(CLEAR_PATH, new PathNode(PATHTYPE.PATH, branch)));
                elseexpr = analyze(context, RT.fourth(form));
            } finally {
                Var.popThreadBindings();
            }
            return new IfExpr(lineDeref(),
                    columnDeref(),
                    testexpr,
                    thenexpr,
                    elseexpr);
        }
    }

    */


}