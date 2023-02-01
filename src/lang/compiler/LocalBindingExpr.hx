package lang.compiler;

import lang.Compiler.PATHTYPE;
import lang.exceptions.UnsupportedOperationException;

class LocalBindingExpr implements Expr implements MaybePrimitiveExpr implements AssignableExpr {
	public var b:LocalBinding;
	public var tag:Symbol;

	public var clearPath:PathNode;
	public var clearRoot:PathNode;
	public var shouldClear:Bool = false;

	public function new(b:LocalBinding, tag:Symbol) {
		/* TODO: fix
		if (b.getPrimitiveType() != null && tag != null)
			if (!b.getPrimitiveType().equals(Compiler.tagClass(tag)))
				throw new UnsupportedOperationException("Can't type hint a primitive local with a different type");
			else
				this.tag = null;
		else
			this.tag = tag;
		*/

		this.b = b;

		this.clearPath = Compiler.CLEAR_PATH.get();
		this.clearRoot = Compiler.CLEAR_ROOT.get();
		var sites:IPersistentCollection = RT.get(Compiler.CLEAR_SITES.get(), b);
		b.used = true;

		if (b.idx > 0) {
			if (sites != null) {
				var s:ISeq = sites.seq();
				while (s != null) {
					var o:LocalBindingExpr = s.first();
					var common:PathNode = Compiler.commonPath(clearPath, o.clearPath);
					if (common != null && common.type == PATHTYPE.PATH)
						o.shouldClear = false;
					s = s.next();
				}
			}
			if (clearRoot == b.clearPathRoot) {
				this.shouldClear = true;
				sites = RT.conj(sites, this);
				Compiler.CLEAR_SITES.set(RT.assoc(Compiler.CLEAR_SITES.get(), b, sites));
			}
		}
	}

	public function eval():Any {
		throw new UnsupportedOperationException("Can't eval locals");
	}

	/*
		public function canEmitPrimitive():Bool {
		return b.getPrimitiveType() != null;
		}

		public function emitUnboxed(C context, ObjExpr objx, GeneratorAdapter gen):Void {
		objx.emitUnboxedLocal(gen, b);
		}

		public function emit(C context, ObjExpr objx, GeneratorAdapter gen):Void {
		if (context != C.STATEMENT)
			objx.emitLocal(gen, b, shouldClear);
		}
	 */
	public function evalAssign(val:Expr):Any {
		throw new UnsupportedOperationException("Can't eval locals");
	}
	/*
		public void emitAssign(C context, ObjExpr objx, GeneratorAdapter gen, Expr val) {
		objx.emitAssignLocal(gen, b, val);
		if (context != C.STATEMENT)
			objx.emitLocal(gen, b, false);
		}

		public boolean hasJavaClass() {
		return tag != null || b.hasJavaClass();
		}

		Class jc;

		public Class getJavaClass() {
		if (jc == null) {
			if (tag != null)
				jc = HostExpr.tagToClass(tag);
			else
				jc = b.getJavaClass();
		}
		return jc;
		}
	 */
}
