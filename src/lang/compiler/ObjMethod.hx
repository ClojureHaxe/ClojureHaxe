package lang.compiler;

abstract class ObjMethod {
	// when closures are defined inside other closures,
	// the closed over locals need to be propagated to the enclosing objx
	public var parent:ObjMethod;

	// localbinding->localbinding
	public var locals:IPersistentMap = null;
	// num->localbinding
	public var indexlocals:IPersistentMap = null;
	var body:Expr = null;
	public var objx:ObjExpr;
	var argLocals:PersistentVector;
	public var maxLocal:Int = 0;
	var line:Int;
	var column:Int;
	public var usesThis:Bool = false;
	var localsUsedInCatchFinally:PersistentHashSet = PersistentHashSet.EMPTY;
	var methodMeta:IPersistentMap;

	public final function getLocals():IPersistentMap {
		return locals;
	}

	public final function getBody():Expr {
		return body;
	}

	public final function getObjx():ObjExpr {
		return objx;
	}

	public final function getArgLocals():PersistentVector {
		return argLocals;
	}

	public final function getMaxLocal():Int {
		return maxLocal;
	}

	public final function getLine():Int {
		return line;
	}

	public final function getColumn():Int {
		return column;
	}

	public function new(objx:ObjExpr, parent:ObjMethod) {
		this.parent = parent;
		this.objx = objx;
	}
	/*
		static void emitBody(ObjExpr objx, GeneratorAdapter gen, Class retClass, Expr body) {
			MaybePrimitiveExpr be = (MaybePrimitiveExpr) body;
			if (Util.isPrimitive(retClass) && be.canEmitPrimitive()) {
				Class bc = maybePrimitiveType(be);
				if (bc == retClass)
					be.emitUnboxed(C.RETURN, objx, gen);
				else if (retClass == long.class && bc == int.class) {
					be.emitUnboxed(C.RETURN, objx, gen);
					gen.visitInsn(I2L);
				} else if (retClass == double.class && bc == float.class) {
					be.emitUnboxed(C.RETURN, objx, gen);
					gen.visitInsn(F2D);
				} else if (retClass == int.class && bc == long.class) {
					be.emitUnboxed(C.RETURN, objx, gen);
					gen.invokeStatic(RT_TYPE, Method.getMethod("int intCast(long)"));
				} else if (retClass == float.class && bc == double.class) {
					be.emitUnboxed(C.RETURN, objx, gen);
					gen.visitInsn(D2F);
				} else
					throw new IllegalArgumentException("Mismatched primitive return, expected: "
							+ retClass + ", had: " + be.getJavaClass());
			} else {
				body.emit(C.RETURN, objx, gen);
				if (retClass == void.class) {
					gen.pop();
				} else
					gen.unbox(Type.getType(retClass));
			}
		}

		abstract int numParams();

		abstract String getMethodName();

		abstract Type getReturnType();

		abstract Type[] getArgTypes();

		public void emit(ObjExpr fn, ClassVisitor cv) {
			Method m = new Method(getMethodName(), getReturnType(), getArgTypes());

			GeneratorAdapter gen = new GeneratorAdapter(ACC_PUBLIC,
					m,
					null,
					//todo don't hardwire this
					EXCEPTION_TYPES,
					cv);
			gen.visitCode();

			Label loopLabel = gen.mark();
			gen.visitLineNumber(line, loopLabel);
			try {
				Var.pushThreadBindings(RT.map(LOOP_LABEL, loopLabel, METHOD, this));

				body.emit(C.RETURN, fn, gen);
				Label end = gen.mark();
				gen.visitLocalVariable("this", "Ljava/lang/Object;", null, loopLabel, end, 0);
				for (ISeq lbs = argLocals.seq(); lbs != null; lbs = lbs.next()) {
					LocalBinding lb = (LocalBinding) lbs.first();
					gen.visitLocalVariable(lb.name, "Ljava/lang/Object;", null, loopLabel, end, lb.idx);
				}
			} finally {
				Var.popThreadBindings();
			}

			gen.returnValue();
			//gen.visitMaxs(1, 1);
			gen.endMethod();
		}

		void emitClearLocals(GeneratorAdapter gen) {
		}

		void emitClearLocalsOld(GeneratorAdapter gen) {
			for (int i = 0; i < argLocals.count(); i++) {
				LocalBinding lb = (LocalBinding) argLocals.nth(i);
				if (!localsUsedInCatchFinally.contains(lb.idx) && lb.getPrimitiveType() == null) {
					gen.visitInsn(Opcodes.ACONST_NULL);
					gen.storeArg(lb.idx - 1);
				}

			}
			for (int i = numParams() + 1; i < maxLocal + 1; i++) {
				if (!localsUsedInCatchFinally.contains(i)) {
					LocalBinding b = (LocalBinding) RT.get(indexlocals, i);
					if (b == null || maybePrimitiveType(b.init) == null) {
						gen.visitInsn(Opcodes.ACONST_NULL);
						gen.visitVarInsn(OBJECT_TYPE.getOpcode(Opcodes.ISTORE), i);
					}
				}
			}
		}

		void emitClearThis(GeneratorAdapter gen) {
			gen.visitInsn(Opcodes.ACONST_NULL);
			gen.visitVarInsn(Opcodes.ASTORE, 0);
		}

	 */
}
