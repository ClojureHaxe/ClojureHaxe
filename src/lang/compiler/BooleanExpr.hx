package lang.compiler;

class BooleanExpr extends LiteralExpr {
    public var _val:Bool;


    public function new(val:Bool) {
        this._val = val;
    }

    function val():Any {
        return _val ? RT.T : RT.F;
    }

    /*
    public void emit(C context, ObjExpr objx, GeneratorAdapter gen) {
        if (val)
            gen.getStatic(BOOLEAN_OBJECT_TYPE, "TRUE", BOOLEAN_OBJECT_TYPE);
        else
            gen.getStatic(BOOLEAN_OBJECT_TYPE, "FALSE", BOOLEAN_OBJECT_TYPE);
        if (context == C.STATEMENT) {
            gen.pop();
        }
    }

    public boolean hasJavaClass() {
        return true;
    }

    public Class getJavaClass() {
        return Boolean.class;
    }
    */
}