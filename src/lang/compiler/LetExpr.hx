package lang.compiler;

import lang.Compiler.C;
import lang.Compiler.PATHTYPE;
import lang.exceptions.UnsupportedOperationException;
import lang.exceptions.IllegalArgumentException;
import haxe.Exception;

class LetExpr implements Expr implements MaybePrimitiveExpr {
	public var bindingInits:PersistentVector;
	public var body:Expr;
	public var isLoop:Bool;

	// public var bindings:Map<Symbol, Expr> = new Map();

	public function new(bindingInits:PersistentVector, body:Expr, isLoop:Bool // ,  bindings:Map<Symbol, Expr>
	) {
		this.bindingInits = bindingInits;
		this.body = body;
		this.isLoop = isLoop;
		// this.bindings = bindings;
	}

	public function eval():Any {
		trace(">>>>>>>>>>>>>>> LetExpr EVAL");
		// throw new UnsupportedOperationException("Can't eval let/loop");
		for (lb in bindingInits.iterator()) {
			trace(">>>> let expr eval: " + lb);
			var v:Var = Compiler.lookupVar((lb : LocalBinding).sym, true);
			Compiler.registerVar(v);
			// Var.pushThreadBindings(RT.mapUniqueKeys(Var.intern3(RT.CURRENT_NS.deref(), (lb : LocalBinding).sym, (lb : LocalBinding).init.eval())
			// 	.setDynamic()));
			// v.bindRoot(init.eval());
			Var.pushThreadBindings(RT.mapUniqueKeys(v.setDynamic(), (lb : LocalBinding).init.eval()));
		}

		var ret:Any = body.eval();
		for (lb in bindingInits.iterator()) {
			Var.popThreadBindings();
		}
		return ret;
	}
	/*
		public void emit(C context, ObjExpr objx, GeneratorAdapter gen) {
			doEmit(context, objx, gen, false);
		}

		public void emitUnboxed(C context, ObjExpr objx, GeneratorAdapter gen) {
			doEmit(context, objx, gen, true);
		}


		public void doEmit(C context, ObjExpr objx, GeneratorAdapter gen, boolean emitUnboxed) {
			HashMap<BindingInit, Label> bindingLabels = new HashMap();
			for (int i = 0; i < bindingInits.count(); i++) {
				BindingInit bi = (BindingInit) bindingInits.nth(i);
				Class primc = maybePrimitiveType(bi.init);
				if (primc != null) {
					((MaybePrimitiveExpr) bi.init).emitUnboxed(C.EXPRESSION, objx, gen);
					gen.visitVarInsn(Type.getType(primc).getOpcode(Opcodes.ISTORE), bi.binding.idx);
				} else {
					bi.init.emit(C.EXPRESSION, objx, gen);
					if (!bi.binding.used && bi.binding.canBeCleared)
						gen.pop();
					else
						gen.visitVarInsn(OBJECT_TYPE.getOpcode(Opcodes.ISTORE), bi.binding.idx);
				}
				bindingLabels.put(bi, gen.mark());
			}
			Label loopLabel = gen.mark();
			if (isLoop) {
				try {
					Var.pushThreadBindings(RT.map(LOOP_LABEL, loopLabel));
					if (emitUnboxed)
						((MaybePrimitiveExpr) body).emitUnboxed(context, objx, gen);
					else
						body.emit(context, objx, gen);
				} finally {
					Var.popThreadBindings();
				}
			} else {
				if (emitUnboxed)
					((MaybePrimitiveExpr) body).emitUnboxed(context, objx, gen);
				else
					body.emit(context, objx, gen);
			}
			Label end = gen.mark();
		//		gen.visitLocalVariable("this", "Ljava/lang/Object;", null, loopLabel, end, 0);
			for (ISeq bis = bindingInits.seq(); bis != null; bis = bis.next()) {
				BindingInit bi = (BindingInit) bis.first();
				String lname = bi.binding.name;
				if (lname.endsWith("__auto__"))
					lname += RT.nextID();
				Class primc = maybePrimitiveType(bi.init);
				if (primc != null)
					gen.visitLocalVariable(lname, Type.getDescriptor(primc), null, bindingLabels.get(bi), end,
							bi.binding.idx);
				else
					gen.visitLocalVariable(lname, "Ljava/lang/Object;", null, bindingLabels.get(bi), end, bi.binding.idx);
			}
		}

		public boolean hasJavaClass() {
			return body.hasJavaClass();
		}

		public Class getJavaClass() {
			return body.getJavaClass();
		}

		public boolean canEmitPrimitive() {
			return body instanceof MaybePrimitiveExpr && ((MaybePrimitiveExpr) body).canEmitPrimitive();
		}
	 */
}

class LetExprParser implements IParser {
	public function new() {}

	public function parse(context:C, frm:Any):Expr {
		var form:ISeq = frm;
		// (let [var val var2 val2 ...] body...)
		var isLoop:Bool = Compiler.LOOP.equals(RT.first(form));
		if (!(U.instanceof(RT.second(form), IPersistentVector)))
			throw new IllegalArgumentException("Bad binding form, expected vector");

		var bindings:IPersistentVector = RT.second(form);
		if ((bindings.count() % 2) != 0)
			throw new IllegalArgumentException("Bad binding form, expected matched symbol expression pairs");

		var body:ISeq = RT.next(RT.next(form));

		trace("LET EXPR: " + body);
		// trace("LET EXPR: " + body + " " + RT.list(RT.list(Compiler.FNONCE, PersistentVector.EMPTY, form)));
		// Here is compiling in Java
		//  (let* [a 10] a) =>  ((fn* [] (let* [a 10] a)))
		// if (context == C.EVAL || (context == C.EXPRESSION && isLoop))
		//	return Compiler.analyze(context, RT.list(RT.list(Compiler.FNONCE, PersistentVector.EMPTY, form)));

		// var method:ObjMethod = Compiler.METHOD.deref();
		// var backupMethodLocals:IPersistentMap = method.locals;
		// var backupMethodIndexLocals:IPersistentMap = method.indexlocals;
		// var recurMismatches:IPersistentVector = PersistentVector.EMPTY;

		// var i:Int = 0;
		// while (i < bindings.count() / 2) {
		//		recurMismatches = cast recurMismatches.cons(RT.F);
		//			i++;
		//	}

		// trace("LET EXPR recurMismatches: " + recurMismatches);

		// may repeat once for each binding with a mismatch, return breaks
		while (true) {
			trace("LetExprParser WHILE LOOP 1");
			var dynamicBindings:IPersistentMap = RT.map(Compiler.LOCAL_ENV, Compiler.LOCAL_ENV.deref(), Compiler.NEXT_LOCAL_NUM,
				Compiler.NEXT_LOCAL_NUM.deref());
			// method.locals = backupMethodLocals;
			// method.indexlocals = backupMethodIndexLocals;

			// var looproot:PathNode = new PathNode(PATHTYPE.PATH, Compiler.CLEAR_PATH.get());
			// var clearroot:PathNode = new PathNode(PATHTYPE.PATH, looproot);
			// var clearpath:PathNode = new PathNode(PATHTYPE.PATH, looproot);

			var bindingInits:PersistentVector = PersistentVector.EMPTY;
			// var loopLocals:PersistentVector = PersistentVector.EMPTY;
			var i:Int = 0;
			while (i < bindings.count()) {
				if (!(U.instanceof(bindings.nth(i), Symbol)))
					throw new IllegalArgumentException("Bad binding form, expected symbol, got: " + bindings.nth(i));
				var sym:Symbol = bindings.nth(i);
				if (sym.getNamespace() != null)
					throw Util.runtimeException("Can't let qualified name: " + sym);

				var init:Expr = Compiler.analyze3(C.EXPRESSION, bindings.nth(i + 1), sym.name);
				// sequential enhancement of env (like Lisp let*)

				trace(">>> LET EXPR before register: " + sym + " " + init);
				// var lb:LocalBinding = Compiler.registerLocal(sym, Compiler.tagOf(sym), init, false);
				// var bi:BindingInit = new BindingInit(lb, init);
				var lb:LocalBinding = new LocalBinding(0, sym, null, init, true, null);
				bindingInits = bindingInits.cons(lb);

				i += 2;
			}

			var bodyExpr:Expr;

			bodyExpr = (new BodyExpr.BodyExprParser()).parse(isLoop ? C.RETURN : context, body);
			trace("=========================================LET EXPR parse end");
			return new LetExpr(bindingInits, bodyExpr, isLoop);
		}
	}
}

// try {
// } catch (e:Exception) {
// 	Var.popThreadBindings();
// 	throw e;
// }
// Var.popThreadBindings();
