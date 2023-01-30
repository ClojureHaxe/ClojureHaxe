package lang.compiler;

import lang.Compiler.C;

interface IParser {
    public function parse(context:C, form:Any):Expr;
}