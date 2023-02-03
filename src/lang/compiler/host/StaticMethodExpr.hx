package lang.compiler.host;

import haxe.Exception;
import haxe.ds.Vector;

class StaticMethodExpr extends MethodExpr {
	public var c:Class<Dynamic>;
	public var methodName:String;
	public var args:IPersistentVector;
	public var source:String;
	public var line:Int;
	public var column:Int;
	// public var java.lang.reflect.Method method;
	public var tag:Symbol;
	public var tailPosition:Bool;

	// final static Method forNameMethod = Method.getMethod("Class classForName(String)");
	// final static Method invokeStaticMethodMethod =  Method.getMethod("Object invokeStaticMethod(Class,String,Object[])");
	static var warnOnBoxedKeyword:Keyword = Keyword.intern1("warn-on-boxed");

	// Class jc;

	public function new(source:String, line:Int, column:Int, tag:Symbol, c:Class<Dynamic>, methodName:String, args:IPersistentVector, tailPosition:Bool) {
		this.c = c;
		this.methodName = methodName;
		this.args = args;
		this.source = source;
		this.line = line;
		this.column = column;
		this.tag = tag;
		this.tailPosition = tailPosition;

		// List methods = Reflector.getMethods(c, args.count(), methodName, true);
		// if (methods.isEmpty())
		//     throw new IllegalArgumentException("No matching method " + methodName + " found taking "
		//             + args.count() + " args for " + c);

		// int methodidx = 0;
		// if (methods.size() > 1) {
		//     ArrayList<Class[]> params = new ArrayList();
		//     ArrayList<Class> rets = new ArrayList();
		//     for (int i = 0; i < methods.size(); i++) {
		//         java.lang.reflect.Method m = (java.lang.reflect.Method) methods.get(i);
		//         params.add(m.getParameterTypes());
		//         rets.add(m.getReturnType());
		//     }
		//     methodidx = getMatchingParams(methodName, params, args, rets);
		// }

		// method = (java.lang.reflect.Method) (methodidx >= 0 ? methods.get(methodidx) : null);
		// if (method == null && RT.booleanCast(RT.WARN_ON_REFLECTION.deref())) {
		//     RT.errPrintWriter()
		//             .format("Reflection warning, %s:%d:%d - call to static method %s on %s can't be resolved (argument types: %s).\n",
		//                     SOURCE_PATH.deref(), line, column, methodName, c.getName(), getTypeStringForArgs(args));
		// }
		// if (method != null && warnOnBoxedKeyword.equals(RT.UNCHECKED_MATH.deref()) && isBoxedMath(method)) {
		//     RT.errPrintWriter()
		//             .format("Boxed math warning, %s:%d:%d - call: %s.\n",
		//                     SOURCE_PATH.deref(), line, column, method.toString());
		// }
	}

	/*
		public static boolean isBoxedMath(java.lang.reflect.Method m) {
			Class c = m.getDeclaringClass();
			if (c.equals(Numbers.class)) {
				WarnBoxedMath boxedMath = m.getAnnotation(WarnBoxedMath.class);
				if (boxedMath != null)
					return boxedMath.value();

				Class[] argTypes = m.getParameterTypes();
				for (Class argType : argTypes)
					if (argType.equals(Object.class) || argType.equals(Number.class))
						return true;
			}
			return false;
		}
	 */
	public function eval():Any {
		try {
			var argvals:Vector<Any> = new Vector(args.count());
			var i:Int = 0;
			while (i < args.count()) {
				argvals[i] = (args.nth(i) : Expr).eval();
				i++;
			}
			/*  
				if (method != null) {
					LinkedList ms = new LinkedList();
					ms.add(method);
					return Reflector.invokeMatchingMethod(methodName, ms, null, argvals);
			}*/
			return Reflector.invokeMethod(c, methodName, argvals);
		} catch (e:Exception) {
			if (!U.instanceof(e, CompilerException))
				throw new CompilerException(source, line, column, null, CompilerException.PHASE_EXECUTION, e);
			else
				throw e;
		}
	}
	/*
		public boolean canEmitPrimitive() {
			return method != null && Util.isPrimitive(method.getReturnType());
		}

		public boolean canEmitIntrinsicPredicate() {
			return method != null && RT.get(Intrinsics.preds, method.toString()) != null;
		}

		public void emitIntrinsicPredicate(C context, ObjExpr objx, GeneratorAdapter gen, Label falseLabel) {
			gen.visitLineNumber(line, gen.mark());
			if (method != null) {
				MethodExpr.emitTypedArgs(objx, gen, method.getParameterTypes(), args);
				if (context == C.RETURN) {
					ObjMethod method = (ObjMethod) METHOD.deref();
					method.emitClearLocals(gen);
				}
				Object[] predOps = (Object[]) RT.get(Intrinsics.preds, method.toString());
				for (int i = 0; i < predOps.length - 1; i++)
					gen.visitInsn((Integer) predOps[i]);
				gen.visitJumpInsn((Integer) predOps[predOps.length - 1], falseLabel);
			} else
				throw new UnsupportedOperationException("Unboxed emit of unknown member");
		}

		public void emitUnboxed(C context, ObjExpr objx, GeneratorAdapter gen) {
			if (method != null) {
				MethodExpr.emitTypedArgs(objx, gen, method.getParameterTypes(), args);
				gen.visitLineNumber(line, gen.mark());
				//Type type = Type.getObjectType(className.replace('.', '/'));
				if (context == C.RETURN) {
					ObjMethod method = (ObjMethod) METHOD.deref();
					method.emitClearLocals(gen);
				}
				Object ops = RT.get(Intrinsics.ops, method.toString());
				if (ops != null) {
					if (ops instanceof Object[]) {
						for (Object op : (Object[]) ops)
							gen.visitInsn((Integer) op);
					} else
						gen.visitInsn((Integer) ops);
				} else {
					Type type = Type.getType(c);
					Method m = new Method(methodName, Type.getReturnType(method), Type.getArgumentTypes(method));
					gen.visitMethodInsn(INVOKESTATIC, type.getInternalName(), methodName, m.getDescriptor(), c.isInterface());
				}
			} else
				throw new UnsupportedOperationException("Unboxed emit of unknown member");
		}

		public void emit(C context, ObjExpr objx, GeneratorAdapter gen) {
			if (method != null) {
				MethodExpr.emitTypedArgs(objx, gen, method.getParameterTypes(), args);
				gen.visitLineNumber(line, gen.mark());
				//Type type = Type.getObjectType(className.replace('.', '/'));
				if (tailPosition && !objx.canBeDirect) {
					ObjMethod method = (ObjMethod) METHOD.deref();
					method.emitClearThis(gen);
				}
				Type type = Type.getType(c);
				Method m = new Method(methodName, Type.getReturnType(method), Type.getArgumentTypes(method));
				gen.visitMethodInsn(INVOKESTATIC, type.getInternalName(), methodName, m.getDescriptor(), c.isInterface());
				//if(context != C.STATEMENT || method.getReturnType() == Void.TYPE)
				Class retClass = method.getReturnType();
				if (context == C.STATEMENT) {
					if (retClass == long.class || retClass == double.class)
						gen.pop2();
					else if (retClass != void.class)
						gen.pop();
				} else {
					HostExpr.emitBoxReturn(objx, gen, method.getReturnType());
				}
			} else {
				gen.visitLineNumber(line, gen.mark());
				gen.push(c.getName());
				gen.invokeStatic(RT_TYPE, forNameMethod);
				gen.push(methodName);
				emitArgsAsArray(args, objx, gen);
				gen.visitLineNumber(line, gen.mark());
				if (context == C.RETURN) {
					ObjMethod method = (ObjMethod) METHOD.deref();
					method.emitClearLocals(gen);
				}
				gen.invokeStatic(REFLECTOR_TYPE, invokeStaticMethodMethod);
				if (context == C.STATEMENT)
					gen.pop();
			}
		}

		public boolean hasJavaClass() {
			return method != null || tag != null;
		}

		public Class getJavaClass() {
			if (jc == null)
				jc = retType((tag != null) ? HostExpr.tagToClass(tag) : null, (method != null) ? method.getReturnType() : null);
			return jc;
		}

	 */
}
