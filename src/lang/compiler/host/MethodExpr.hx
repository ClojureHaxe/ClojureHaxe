package lang.compiler.host;

abstract class MethodExpr extends HostExpr {
	/*
		static void emitArgsAsArray(IPersistentVector args, ObjExpr objx, GeneratorAdapter gen) {
			gen.push(args.count());
			gen.newArray(OBJECT_TYPE);
			for (int i = 0; i < args.count(); i++) {
				gen.dup();
				gen.push(i);
				((Expr) args.nth(i)).emit(C.EXPRESSION, objx, gen);
				gen.arrayStore(OBJECT_TYPE);
			}
		}

		public static void emitTypedArgs(ObjExpr objx, GeneratorAdapter gen, Class[] parameterTypes, IPersistentVector args) {
			for (int i = 0; i < parameterTypes.length; i++) {
				Expr e = (Expr) args.nth(i);
				try {
					final Class primc = maybePrimitiveType(e);
					if (primc == parameterTypes[i]) {
						final MaybePrimitiveExpr pe = (MaybePrimitiveExpr) e;
						pe.emitUnboxed(C.EXPRESSION, objx, gen);
					} else if (primc == int.class && parameterTypes[i] == long.class) {
						final MaybePrimitiveExpr pe = (MaybePrimitiveExpr) e;
						pe.emitUnboxed(C.EXPRESSION, objx, gen);
						gen.visitInsn(I2L);
					} else if (primc == long.class && parameterTypes[i] == int.class) {
						final MaybePrimitiveExpr pe = (MaybePrimitiveExpr) e;
						pe.emitUnboxed(C.EXPRESSION, objx, gen);
						if (RT.booleanCast(RT.UNCHECKED_MATH.deref()))
							gen.invokeStatic(RT_TYPE, Method.getMethod("int uncheckedIntCast(long)"));
						else
							gen.invokeStatic(RT_TYPE, Method.getMethod("int intCast(long)"));
					} else if (primc == float.class && parameterTypes[i] == double.class) {
						final MaybePrimitiveExpr pe = (MaybePrimitiveExpr) e;
						pe.emitUnboxed(C.EXPRESSION, objx, gen);
						gen.visitInsn(F2D);
					} else if (primc == double.class && parameterTypes[i] == float.class) {
						final MaybePrimitiveExpr pe = (MaybePrimitiveExpr) e;
						pe.emitUnboxed(C.EXPRESSION, objx, gen);
						gen.visitInsn(D2F);
					} else {
						e.emit(C.EXPRESSION, objx, gen);
						HostExpr.emitUnboxArg(objx, gen, parameterTypes[i]);
					}
				} catch (Exception e1) {
					throw Util.sneakyThrow(e1);
				}

			}
		}
	 */
}
