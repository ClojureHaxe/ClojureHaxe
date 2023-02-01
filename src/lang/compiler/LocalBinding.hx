package lang.compiler;

import lang.exceptions.UnsupportedOperationException;

class LocalBinding {
	public var sym:Symbol;
	public var tag:Symbol;
	public var init:Expr;

	public var idx:Int;

	public var name:String;
	public var isArg:Bool;
	public var clearPathRoot:PathNode;
	public var canBeCleared:Bool = !RT.booleanCast(Compiler.getCompilerOption(Compiler.disableLocalsClearingKey));
	public var recurMistmatch:Bool = false;
	public var used:Bool = false;

	public function new(num:Int, sym:Symbol, tag:Symbol, init:Expr, isArg:Bool, clearPathRoot:PathNode) {
		// TODO:
        //if (Compiler.maybePrimitiveType(init) != null && tag != null)
	   //		throw new UnsupportedOperationException("Can't type hint a local with a primitive initializer");
		this.idx = num;
		this.sym = sym;
		this.tag = tag;
		this.init = init;
		this.isArg = isArg;
		this.clearPathRoot = clearPathRoot;
		name = Compiler.munge(sym.name);
	}
	/*
		var hjc:Bool;

		public function hasJavaClass():Bool {
			if (hjc == null) {
				if (init != null && init.hasJavaClass() && Util.isPrimitive(init.getJavaClass()) && !(init instanceof MaybePrimitiveExpr))
					hjc = false;
				else
					hjc = tag != null || (init != null && init.hasJavaClass());
			}
			return hjc;
		}

		Class jc;

		public Class getJavaClass() {
			if (jc == null)
				jc = tag != null ? HostExpr.tagToClass(tag) : init.getJavaClass();
			return jc;
		}

		public Class getPrimitiveType() {
			return maybePrimitiveType(init);
		}
	 */
}
