package lang.compiler;

class StringExpr extends LiteralExpr {
    public var str:String;

    public function new( str:String) {
        this.str = str;
    }

    function val():Any {
        return str;
    }

    /*
    public void emit(C context, ObjExpr objx, GeneratorAdapter gen) {
        if (context != C.STATEMENT)
            gen.push(str);
    }

    public boolean hasJavaClass() {
        return true;
    }

    public Class getJavaClass() {
        return String.class;
    }
    */
}