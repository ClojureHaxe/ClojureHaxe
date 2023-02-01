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

	public function new(bindingInits:PersistentVector, body:Expr, isLoop:Bool) {
		this.bindingInits = bindingInits;
		this.body = body;
		this.isLoop = isLoop;
	}

	public function eval():Any {
		throw new UnsupportedOperationException("Can't eval let/loop");
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
	public function new(){}
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

		trace("LET EXPR: " + body + " " + RT.list(RT.list(Compiler.FNONCE, PersistentVector.EMPTY, form)));
		if (context == C.EVAL || (context == C.EXPRESSION && isLoop))
			return Compiler.analyze(context, RT.list(RT.list(Compiler.FNONCE, PersistentVector.EMPTY, form)));

		var method:ObjMethod = Compiler.METHOD.deref();
		var backupMethodLocals:IPersistentMap = method.locals;
		var backupMethodIndexLocals:IPersistentMap = method.indexlocals;
		var recurMismatches:IPersistentVector = PersistentVector.EMPTY;

		var i:Int = 0;
		while (i < bindings.count() / 2) {
			recurMismatches = cast recurMismatches.cons(RT.F);
			i++;
		}

		// may repeat once for each binding with a mismatch, return breaks
		while (true) {
			var dynamicBindings:IPersistentMap = RT.map(Compiler.LOCAL_ENV, Compiler.LOCAL_ENV.deref(), Compiler.NEXT_LOCAL_NUM,
				Compiler.NEXT_LOCAL_NUM.deref());
			method.locals = backupMethodLocals;
			method.indexlocals = backupMethodIndexLocals;

			var looproot:PathNode = new PathNode(PATHTYPE.PATH, Compiler.CLEAR_PATH.get());
			var clearroot:PathNode = new PathNode(PATHTYPE.PATH, looproot);
			var clearpath:PathNode = new PathNode(PATHTYPE.PATH, looproot);
			if (isLoop)
				dynamicBindings = cast dynamicBindings.assoc(Compiler.LOOP_LOCALS, null);

			try {
				Var.pushThreadBindings(dynamicBindings);

				var bindingInits:PersistentVector = PersistentVector.EMPTY;
				var loopLocals:PersistentVector = PersistentVector.EMPTY;
				var i:Int = 0;
				while (i < bindings.count()) {
					if (!(U.instanceof(bindings.nth(i), Symbol)))
						throw new IllegalArgumentException("Bad binding form, expected symbol, got: " + bindings.nth(i));
					var sym:Symbol = bindings.nth(i);
					if (sym.getNamespace() != null)
						throw Util.runtimeException("Can't let qualified name: " + sym);
					var init:Expr = Compiler.analyze3(C.EXPRESSION, bindings.nth(i + 1), sym.name);
					if (isLoop) {
						/*
							if (recurMismatches != null && RT.booleanCast(recurMismatches.nth(i / 2))) {
								// TODO:::: !
								//init = new StaticMethodExpr("", 0, 0, null, RT.class, "box", RT.vector(init), false);
								if (RT.booleanCast(RT.WARN_ON_REFLECTION.deref()))
									RT.errPrintWriter().println("Auto-boxing loop arg: " + sym);
							} else if (Compiler.maybePrimitiveType(init) == int.class)
								init = new StaticMethodExpr("", 0, 0, null, RT.class, "longCast", RT.vector(init), false);
							else if (maybePrimitiveType(init) == float.class)
								init = new StaticMethodExpr("", 0, 0, null, RT.class, "doubleCast", RT.vector(init), false);
						 */
					}
					// sequential enhancement of env (like Lisp let*)
					try {
						/*
							if (isLoop) {
								Var.pushThreadBindings(
										RT.map(Compiler.CLEAR_PATH, clearpath,
											Compiler.CLEAR_ROOT, clearroot,
											Compiler.NO_RECUR, null));

							}
						 */

						var lb:LocalBinding = Compiler.registerLocal(sym, Compiler.tagOf(sym), init, false);
						var bi:BindingInit = new BindingInit(lb, init);
						bindingInits = bindingInits.cons(bi);
						if (isLoop)
							loopLocals = loopLocals.cons(lb);
					}
					/* finally {
						if (isLoop)
							Var.popThreadBindings();
					}*/
					i += 2;
				}
				if (isLoop)
					Compiler.LOOP_LOCALS.set(loopLocals);
				var bodyExpr:Expr;
				var moreMismatches:Bool = false;
				try {
					if (isLoop) {
						var methodReturnContext:Any = context == C.RETURN ? Compiler.METHOD_RETURN_CONTEXT.deref() : null;
						Var.pushThreadBindings(RT.map(Compiler.CLEAR_PATH, clearpath, Compiler.CLEAR_ROOT, clearroot, Compiler.NO_RECUR, null,
							Compiler.METHOD_RETURN_CONTEXT, methodReturnContext));
					}
					bodyExpr = (new BodyExpr.BodyExprParser()).parse(isLoop ? C.RETURN : context, body);
				}
				// emulate "finally"
				catch (e:Exception) {
					if (isLoop) {
						Var.popThreadBindings();
						var i:Int = 0;
						while (i < loopLocals.count()) {
							var lb:LocalBinding = cast loopLocals.nth(i);
							if (lb.recurMistmatch) {
								recurMismatches = cast recurMismatches.assoc(i, RT.T);
								moreMismatches = true;
							}
							i++;
						}
					}
					throw(e);
				}
				// finaly
				{
					if (isLoop) {
						Var.popThreadBindings();
						var i:Int = 0;
						while (i < loopLocals.count()) {
							var lb:LocalBinding = cast loopLocals.nth(i);
							if (lb.recurMistmatch) {
								recurMismatches = cast recurMismatches.assoc(i, RT.T);
								moreMismatches = true;
							}
							i++;
						}
					}
				}
				if (!moreMismatches)
					return new LetExpr(bindingInits, bodyExpr, isLoop);
			} catch (e:Exception) {
				Var.popThreadBindings();
				throw(e);
			}
			Var.popThreadBindings();
		}
	}
}
